import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/signalr_service.dart';
import '../../../core/services/system_security_service.dart';
import '../models/draft_state_snapshot_dto.dart';

/// Controller para orquestração da sessão de Draft, sincronização em tempo real via SignalR
/// e transições de estado (Avançar para Reservas ou Concluir Draft).
class DraftController extends ChangeNotifier {
  DraftStateSnapshotDto? _snapshot;
  DraftStateSnapshotDto? get snapshot => _snapshot;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionInProgress = false;
  bool get isActionInProgress => _isActionInProgress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentTournamentId;

  DraftController({DraftStateSnapshotDto? initialSnapshot}) : _snapshot = initialSnapshot {
    _setupSignalRListeners();
  }

  void _setupSignalRListeners() {
    SignalRService.instance.addDraftSnapshotListener(_onRealtimeSnapshotReceived);
    SignalRService.instance.addDraftCompletedListener(_onRealtimeDraftCompleted);
  }

  void _onRealtimeSnapshotReceived(dynamic data) {
    if (data is Map<String, dynamic>) {
      try {
        _snapshot = DraftStateSnapshotDto.fromJson(data);
        _errorMessage = null;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) debugPrint('Erro ao desserializar snapshot SignalR: $e');
      }
    }
  }

  void _onRealtimeDraftCompleted(dynamic data) {
    if (_snapshot != null) {
      _snapshot = DraftStateSnapshotDto(
        draftSessionId: _snapshot!.draftSessionId,
        tournamentId: _snapshot!.tournamentId,
        state: 'Completed',
        targetTeamCount: _snapshot!.targetTeamCount,
        currentPickIndex: _snapshot!.currentPickIndex,
        currentTurnTeamId: _snapshot!.currentTurnTeamId,
        currentTurnPickOrder: _snapshot!.currentTurnPickOrder,
        draftVersion: _snapshot!.draftVersion + 1,
        substitutingPlayerId: _snapshot!.substitutingPlayerId,
        substitutingTeamId: _snapshot!.substitutingTeamId,
        playerPool: _snapshot!.playerPool,
        teams: _snapshot!.teams,
        minRequiredPlayers: _snapshot!.minRequiredPlayers,
        canStartDraft: _snapshot!.canStartDraft,
        allCaptainsAssigned: _snapshot!.allCaptainsAssigned,
        allStartersPicked: true,
        totalStarterPicks: _snapshot!.totalStarterPicks,
      );
      notifyListeners();
    }
  }

  /// Busca os dados mais recentes do snapshot via REST
  Future<bool> fetchSnapshot(String draftSessionId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await ApiClient.get(
        ApiEndpoints.draftSnapshot(draftSessionId),
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      _errorMessage = null;

      // Entra no canal SignalR do torneio correspondente
      if (_snapshot != null && _currentTournamentId != _snapshot!.tournamentId) {
        if (_currentTournamentId != null) {
          await SignalRService.instance.leaveTournamentDraft(_currentTournamentId!);
        }
        _currentTournamentId = _snapshot!.tournamentId;
        await SignalRService.instance.joinTournamentDraft(_currentTournamentId!);
      }

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao carregar estado do draft: $e';
      return false;
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Seleciona um jogador como Capitão de uma equipe (Fase 1: POST .../captain)
  Future<String?> selectCaptain({
    required String playerId,
    String? teamId,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftCaptain(_snapshot!.draftSessionId),
        body: {
          'playerId': playerId,
          'expectedVersion': _snapshot!.draftVersion,
          if (teamId != null) 'teamId': teamId,
        },
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao selecionar capitão: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Remove um jogador reserva de uma equipe (DELETE .../teams/{teamId}/reserves/{playerId})

  /// Remove o Capitão de uma equipe e o retorna para a pool (Fase 1: DELETE .../captain/{teamId})
  Future<String?> removeCaptain({
    required String teamId,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.delete(
        ApiEndpoints.draftRemoveCaptain(
          _snapshot!.draftSessionId,
          teamId,
          _snapshot!.draftVersion,
        ),
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao remover capitão: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Remove um jogador reserva de uma equipe (DELETE .../teams/{teamId}/reserves/{playerId})

  /// Substitui o capitão de uma equipe: remove o anterior (retornando ao pool) e atribui o novo
  Future<String?> replaceCaptain({
    required String teamId,
    required String newPlayerId,
  }) async {
    final removeError = await removeCaptain(teamId: teamId);
    if (removeError != null) return removeError;
    return selectCaptain(playerId: newPlayerId, teamId: teamId);
  }

  /// Avança da Seleção de Capitães para o Sorteio/Ordem dos Turnos (POST .../advance-to-order-selection)
  Future<String?> advanceToOrderSelection() async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftAdvanceToOrderSelection(_snapshot!.draftSessionId),
        body: {'expectedVersion': _snapshot!.draftVersion},
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao avançar para definição de ordem: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Remove um jogador reserva de uma equipe (DELETE .../teams/{teamId}/reserves/{playerId})

  /// Finaliza a ordem de escolha das equipes no Snake Draft (POST .../finalize-order)
  /// [orderType]: 1 = Manual (Como foi no Draft de Pick), 2 = Randomized (Sorteio Aleatório)
  /// [manualOrderIds]: Lista ordenada de IDs das equipes (quando manual)
  Future<String?> finalizeCaptainOrder({
    required int orderType,
    List<String>? manualOrderIds,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'orderType': orderType,
        'expectedVersion': _snapshot!.draftVersion,
      };
      if (manualOrderIds != null && manualOrderIds.isNotEmpty) {
        body['manualOrderIds'] = manualOrderIds;
      }

      final response = await ApiClient.post(
        ApiEndpoints.draftFinalizeOrder(_snapshot!.draftSessionId),
        body: body,
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao definir ordem do draft: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Remove um jogador reserva de uma equipe (DELETE .../teams/{teamId}/reserves/{playerId})

  /// Avança para a fase de alocação de reservas (POST .../advance-to-substitutes)
  Future<String?> advanceToSubstitutes() async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftAdvanceToSubstitutes(_snapshot!.draftSessionId),
        body: {'expectedVersion': _snapshot!.draftVersion},
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao avançar para reservas: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Remove um jogador reserva de uma equipe (DELETE .../teams/{teamId}/reserves/{playerId})

  /// Conclui o draft diretamente consolidando as equipes (POST .../complete)
  /// e inicia o campeonato gerando chaves/partidas (POST .../tournaments/{id}/start)
  Future<String?> completeDraft({bool startTournament = true}) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tournamentId = _snapshot!.tournamentId;
      final response = await ApiClient.post(
        ApiEndpoints.draftComplete(_snapshot!.draftSessionId),
        body: {'expectedVersion': _snapshot!.draftVersion},
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);

      // Inicia o campeonato e gera as chaves/partidas se solicitado e se houver torneio vinculado
      if (startTournament && tournamentId.isNotEmpty) {
        try {
          await ApiClient.post(
            ApiEndpoints.tournamentStart(tournamentId),
            requiresAuth: true,
          );
        } on ApiException catch (e) {
          final msg = e.message.toLowerCase();
          // Idempotência: Se o torneio já estiver iniciado ou já tiver partidas geradas, não bloqueia
          if (!msg.contains('já foi iniciado') &&
              !msg.contains('já foram geradas') &&
              !msg.contains('already started')) {
            rethrow;
          }
        }
      }

      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao concluir o draft: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Remove um jogador reserva de uma equipe (DELETE .../teams/{teamId}/reserves/{playerId})

  /// Cadastra um jogador tardio diretamente no pool do draft (POST .../late-players)
  Future<String?> addLatePlayer({
    required String name,
    required String playerId,
    required List<String> roles,
    required String preferredRole,
    int? rankTier,
    String? avatarUrl,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftLatePlayer(_snapshot!.draftSessionId),
        body: {
          'name': name,
          'playerId': playerId,
          'roles': roles,
          'preferredRole': preferredRole,
          if (rankTier != null && rankTier > 0) 'rankTier': rankTier,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao cadastrar jogador tardio: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Remove um jogador reserva de uma equipe (DELETE .../teams/{teamId}/reserves/{playerId})

  /// Aloca um reserva diretamente para a equipe (limite de 2 reservas por equipe)
  Future<String?> allocateReserve({
    required String teamId,
    required String playerId,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftReserve(_snapshot!.draftSessionId),
        body: {
          'teamId': teamId,
          'playerId': playerId,
          'expectedVersion': _snapshot!.draftVersion,
        },
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao alocar reserva: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Remove um jogador reserva de uma equipe (DELETE .../teams/{teamId}/reserves/{playerId})
  Future<String?> removeReserve({
    required String teamId,
    required String playerId,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.delete(
        ApiEndpoints.draftRemoveReserve(
          _snapshot!.draftSessionId,
          teamId,
          playerId,
          _snapshot!.draftVersion,
        ),
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao remover reserva: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Realiza o pick de um jogador titular no Snake Draft (POST .../pick)
  Future<String?> pickStarterPlayer({
    required String playerId,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    if (SystemSecurityService.instance.isDraftPicksLocked) {
      final detail = SystemSecurityService.instance.message;
      final msg = (detail != null && detail.trim().isNotEmpty)
          ? 'As escolhas de draft estão temporariamente bloqueadas pela administração. Motivo: $detail'
          : 'As escolhas de draft estão temporariamente bloqueadas pela administração do sistema.';
      _errorMessage = msg;
      notifyListeners();
      return msg;
    }

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftPick(_snapshot!.draftSessionId),
        body: {
          'playerId': playerId,
          'expectedVersion': _snapshot!.draftVersion,
        },
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao realizar pick: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Inicia o fluxo de substituição de um titular
  Future<String?> startSubstitution({
    required String teamId,
    required String outPlayerId,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftStartSubstitution(_snapshot!.draftSessionId),
        body: {
          'teamId': teamId,
          'playerId': outPlayerId,
          'expectedVersion': _snapshot!.draftVersion,
        },
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao iniciar substituição: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Confirma a substituição com o jogador substituto
  Future<String?> confirmSubstitution({
    required String inPlayerId,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftConfirmSubstitution(_snapshot!.draftSessionId),
        body: {
          'newPlayerId': inPlayerId,
          'expectedVersion': _snapshot!.draftVersion,
        },
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao confirmar substituição: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Cancela o modo de substituição ativo
  Future<String?> cancelSubstitution() async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftCancelSubstitution(_snapshot!.draftSessionId),
        body: {
          'expectedVersion': _snapshot!.draftVersion,
        },
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao cancelar substituição: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  /// Renomeia uma equipe no Draft e sincroniza com o Torneio (POST .../team/rename)
  Future<String?> renameTeam({
    required String teamId,
    required String newName,
  }) async {
    if (_snapshot == null) return 'Nenhuma sessão de draft ativa.';

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.draftRenameTeam(_snapshot!.draftSessionId),
        body: {
          'teamId': teamId,
          'newName': newName,
          'expectedVersion': _snapshot!.draftVersion,
        },
        requiresAuth: true,
      );

      _snapshot = DraftStateSnapshotDto.fromJson(response);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      final msg = 'Erro ao renomear equipe: $e';
      _errorMessage = msg;
      return msg;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    SignalRService.instance.removeDraftSnapshotListener(_onRealtimeSnapshotReceived);
    SignalRService.instance.removeDraftCompletedListener(_onRealtimeDraftCompleted);
    if (_currentTournamentId != null) {
      SignalRService.instance.leaveTournamentDraft(_currentTournamentId!);
    }
    super.dispose();
  }
}

