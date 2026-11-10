import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/services/system_security_service.dart';
import '../models/match_series_dto.dart';

/// Controller para orquestração de detalhes e lançamentos de resultados de partidas.
class MatchesController extends ChangeNotifier {
  MatchSeriesDto? _currentSeries;
  MatchSeriesDto? get currentSeries => _currentSeries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _expandedGameDetailsNumber;
  int? get expandedGameDetailsNumber => _expandedGameDetailsNumber;

  String? get _resultLockError {
    if (SystemSecurityService.instance.isResultSubmissionLocked) {
      final msg = SystemSecurityService.instance.message;
      return (msg != null && msg.trim().isNotEmpty)
          ? msg.trim()
          : 'O envio e alteração de resultados de partidas está temporariamente bloqueado pela administração.';
    }
    return null;
  }

  MatchesController({MatchSeriesDto? initialSeries})
      : _currentSeries = initialSeries;

  void toggleExpandedGame(int gameNumber) {
    if (_expandedGameDetailsNumber == gameNumber) {
      _expandedGameDetailsNumber = null;
    } else {
      _expandedGameDetailsNumber = gameNumber;
    }
    notifyListeners();
  }

  void clearExpandedGame() {
    if (_expandedGameDetailsNumber != null) {
      _expandedGameDetailsNumber = null;
      notifyListeners();
    }
  }

  /// Busca os dados mais recentes da série pelo ID
  Future<bool> fetchSeries(String matchId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final json = await ApiClient.get(
        ApiEndpoints.matchById(matchId),
        requiresAuth: false,
      );
      _currentSeries = MatchSeriesDto.fromJson(json);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao carregar detalhes da série: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registra resultado manual de um mapa
  Future<String?> recordManualResult({
    required String matchId,
    required String winnerTeamId,
    required int durationSeconds,
    required int teamAKills,
    required int teamBKills,
    int? gameNumber,
    String? firstPickTeamId,
    List<int>? teamABanHeroIds,
    List<int>? teamBBanHeroIds,
    int? dotaMatchId,
  }) async {
    if (_resultLockError != null) return _resultLockError;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.post(
        ApiEndpoints.matchManualResult(matchId),
        body: {
          'winnerTeamId': winnerTeamId,
          'durationSeconds': durationSeconds,
          'teamAKills': teamAKills,
          'teamBKills': teamBKills,
          if (gameNumber != null) 'gameNumber': gameNumber,
          if (firstPickTeamId != null && firstPickTeamId.isNotEmpty)
            'firstPickTeamId': firstPickTeamId,
          if (teamABanHeroIds != null) 'teamABanHeroIds': teamABanHeroIds,
          if (teamBBanHeroIds != null) 'teamBBanHeroIds': teamBBanHeroIds,
          if (dotaMatchId != null) 'dotaMatchId': dotaMatchId,
        },
        requiresAuth: true,
      );

      await fetchSeries(matchId, silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao lançar resultado manual: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Aplica vitória por W.O.
  Future<String?> recordWalkover({
    required String matchId,
    required String winnerTeamId,
  }) async {
    if (_resultLockError != null) return _resultLockError;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.post(
        ApiEndpoints.matchWalkoverResult(matchId),
        body: {
          'winnerTeamId': winnerTeamId,
        },
        requiresAuth: true,
      );

      await fetchSeries(matchId, silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao aplicar W.O.: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Envia arquivo de replay (.dem) para processamento automático pelo parser Go
  Future<String?> uploadReplay({
    required String matchId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    if (_resultLockError != null) return _resultLockError;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.uploadMultipart(
        ApiEndpoints.matchReplay(matchId),
        fileBytes: fileBytes,
        fileName: fileName,
        fileField: 'replayFile',
        requiresAuth: true,
      );

      await fetchSeries(matchId, silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao enviar arquivo de replay: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Atualiza os dados de um jogo já jogado
  Future<String?> updateGameResult({
    required String matchId,
    required int gameNumber,
    required String winnerTeamId,
    required int durationSeconds,
    required int teamAKills,
    required int teamBKills,
    String? firstPickTeamId,
    List<int>? teamABanHeroIds,
    List<int>? teamBBanHeroIds,
    int? dotaMatchId,
  }) async {
    if (_resultLockError != null) return _resultLockError;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.put(
        ApiEndpoints.matchGame(matchId, gameNumber),
        body: {
          'winnerTeamId': winnerTeamId,
          'durationSeconds': durationSeconds,
          'teamAKills': teamAKills,
          'teamBKills': teamBKills,
          if (firstPickTeamId != null && firstPickTeamId.isNotEmpty)
            'firstPickTeamId': firstPickTeamId,
          if (teamABanHeroIds != null) 'teamABanHeroIds': teamABanHeroIds,
          if (teamBBanHeroIds != null) 'teamBBanHeroIds': teamBBanHeroIds,
          if (dotaMatchId != null) 'dotaMatchId': dotaMatchId,
        },
        requiresAuth: true,
      );

      await fetchSeries(matchId, silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao atualizar dados do mapa: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Substitui um mapa existente com um novo arquivo de Replay (.dem)
  Future<String?> uploadGameReplay({
    required String matchId,
    required int gameNumber,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    if (_resultLockError != null) return _resultLockError;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.uploadMultipart(
        ApiEndpoints.matchGameReplay(matchId, gameNumber),
        fileBytes: fileBytes,
        fileName: fileName,
        fileField: 'replayFile',
        method: 'PUT',
        requiresAuth: true,
      );

      await fetchSeries(matchId, silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao enviar replay do mapa: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Aplica W.O. em um mapa específico
  Future<String?> updateGameWalkover({
    required String matchId,
    required int gameNumber,
    required String winnerTeamId,
  }) async {
    if (_resultLockError != null) return _resultLockError;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.put(
        ApiEndpoints.matchGameWalkover(matchId, gameNumber),
        body: {'winnerTeamId': winnerTeamId},
        requiresAuth: true,
      );

      await fetchSeries(matchId, silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao aplicar W.O. no mapa: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Desfaz o último mapa jogado
  Future<String?> removeLastGame(String matchId) async {
    if (_resultLockError != null) return _resultLockError;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.delete(
        ApiEndpoints.matchRemoveLastGame(matchId),
        requiresAuth: true,
      );

      await fetchSeries(matchId, silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao desfazer último mapa: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Reverte a série por completo
  Future<String?> rollbackSeries(String matchId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.post(
        ApiEndpoints.matchRollback(matchId),
        requiresAuth: true,
      );

      await fetchSeries(matchId, silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao reverter série: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
