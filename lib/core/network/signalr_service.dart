import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

/// Serviço singleton para gerenciar conexões em tempo real via SignalR (Hub /hubs/v1/tournament-draft).
/// Escuta notificações em tempo real, como liberação de conta Steam ("ReceiveSteamUnlocked"),
/// drafts de torneios e atualizações de partidas, com re-join automático de grupos.
class SignalRService {
  static SignalRService? _instance;
  static SignalRService get instance => _instance ??= SignalRService._();

  SignalRService._();

  HubConnection? _hubConnection;
  Future<void>? _connectingFuture;
  int _connectionEpoch = 0;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  bool get _isRecoveringOrConnecting {
    final state = _hubConnection?.state;
    return state == HubConnectionState.Connecting ||
        state == HubConnectionState.Reconnecting ||
        state == HubConnectionState.Disconnecting;
  }

  /// Grupos de draft ativos que devem ser ingressados após handshake inicial ou reconexão automática
  final Set<String> _joinedTournamentIds = <String>{};

  @visibleForTesting
  Set<String> get joinedTournamentIdsForTest =>
      Set<String>.unmodifiable(_joinedTournamentIds);

  final List<void Function(dynamic)> _steamUnlockedListeners = [];
  final List<void Function(dynamic)> _draftSnapshotListeners = [];
  final List<void Function(dynamic)> _draftCompletedListeners = [];
  final List<void Function(dynamic)> _securitySettingsListeners = [];

  /// Registra ouvinte para alterações de travas de segurança globais
  void addSecuritySettingsListener(void Function(dynamic) listener) {
    if (!_securitySettingsListeners.contains(listener)) {
      _securitySettingsListeners.add(listener);
    }
  }

  /// Remove ouvinte de alterações de travas de segurança
  void removeSecuritySettingsListener(void Function(dynamic) listener) {
    _securitySettingsListeners.remove(listener);
  }

  /// Registra ouvinte para o evento de desbloqueio da Steam
  void addSteamUnlockedListener(void Function(dynamic) listener) {
    if (!_steamUnlockedListeners.contains(listener)) {
      _steamUnlockedListeners.add(listener);
    }
  }

  /// Remove ouvinte do evento de desbloqueio da Steam
  void removeSteamUnlockedListener(void Function(dynamic) listener) {
    _steamUnlockedListeners.remove(listener);
  }

  /// Registra ouvinte para snapshots de draft em tempo real
  void addDraftSnapshotListener(void Function(dynamic) listener) {
    if (!_draftSnapshotListeners.contains(listener)) {
      _draftSnapshotListeners.add(listener);
    }
  }

  /// Remove ouvinte de snapshot de draft
  void removeDraftSnapshotListener(void Function(dynamic) listener) {
    _draftSnapshotListeners.remove(listener);
  }

  /// Registra ouvinte para conclusão do draft
  void addDraftCompletedListener(void Function(dynamic) listener) {
    if (!_draftCompletedListeners.contains(listener)) {
      _draftCompletedListeners.add(listener);
    }
  }

  /// Remove ouvinte de conclusão do draft
  void removeDraftCompletedListener(void Function(dynamic) listener) {
    _draftCompletedListeners.remove(listener);
  }

  /// Entra no canal SignalR do draft do torneio (com suporte a fila pré-conexão e auto-rejoin)
  Future<void> joinTournamentDraft(String tournamentId) async {
    final trimmed = tournamentId.trim();
    if (trimmed.isEmpty) return;
    _joinedTournamentIds.add(trimmed);

    final inFlight = _connectingFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    if (isConnected) {
      try {
        await _hubConnection?.invoke('JoinTournamentDraft', args: [trimmed]);
      } catch (e) {
        if (kDebugMode) debugPrint('Erro ao entrar no grupo de draft: $e');
      }
      return;
    }

    // Se já estiver em reconexão automática pelo SignalR, preserva a sessão atual;
    // o handler `onreconnected` reingressará automaticamente em `_joinedTournamentIds`.
    if (_isRecoveringOrConnecting) {
      return;
    }

    await connect();
  }

  /// Sai do canal SignalR do draft do torneio
  Future<void> leaveTournamentDraft(String tournamentId) async {
    final trimmed = tournamentId.trim();
    if (trimmed.isEmpty) return;
    _joinedTournamentIds.remove(trimmed);

    if (isConnected) {
      try {
        await _hubConnection?.invoke('LeaveTournamentDraft', args: [trimmed]);
      } catch (e) {
        if (kDebugMode) debugPrint('Erro ao sair do grupo de draft: $e');
      }
    }
  }

  Future<void> _rejoinActiveGroups(int epoch) async {
    if (epoch != _connectionEpoch || !isConnected || _joinedTournamentIds.isEmpty) {
      return;
    }
    for (final id in List<String>.from(_joinedTournamentIds)) {
      if (epoch != _connectionEpoch || !_joinedTournamentIds.contains(id) || !isConnected) {
        continue;
      }
      try {
        await _hubConnection?.invoke('JoinTournamentDraft', args: [id]);
      } catch (e) {
        if (kDebugMode) debugPrint('Erro ao reingressar no grupo de draft ($id): $e');
      }
    }
  }

  /// Inicia conexão com o Hub SignalR autenticado via access_token (deduplicado e protegido contra corridas)
  Future<void> connect() {
    if (isConnected || _isRecoveringOrConnecting) {
      return Future<void>.value();
    }
    final existing = _connectingFuture;
    if (existing != null) {
      return existing;
    }

    final int epoch = ++_connectionEpoch;
    final future = _connectInternal(epoch);
    _connectingFuture = future;
    return future;
  }

  Future<void> _connectInternal(int epoch) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty || epoch != _connectionEpoch) return;

      final hubUrl = ApiEndpoints.tournamentDraftHubUrl;
      await _disposeConnectionOnly();
      if (epoch != _connectionEpoch) return;

      final connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => (await TokenStorage.getToken()) ?? '',
              skipNegotiation: false,
            ),
          )
          .withAutomaticReconnect(
            retryDelays: const [0, 2000, 5000, 10000, 20000, 30000],
          )
          .build();

      _hubConnection = connection;

      connection.onreconnected(({connectionId}) {
        _rejoinActiveGroups(epoch);
      });

      connection.onclose(({error}) {
        if (_hubConnection == connection) {
          _hubConnection = null;
        }
      });

      _setupHandlers();

      await connection.start();
      if (epoch != _connectionEpoch) {
        try {
          await connection.stop();
        } catch (_) {}
        if (_hubConnection == connection) {
          _hubConnection = null;
        }
        return;
      }

      await _rejoinActiveGroups(epoch);
      if (kDebugMode) {
        debugPrint('SignalR conectado ao Hub: $hubUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Aviso SignalR Hub (offline ou reconectando): $e');
      }
    } finally {
      if (epoch == _connectionEpoch || _connectingFuture != null) {
        _connectingFuture = null;
      }
    }
  }

  void _setupHandlers() {
    // 1. Escuta o evento de aprovação de troca de Steam emitido pelo Admin
    _hubConnection?.on('ReceiveSteamUnlocked', (List<Object?>? arguments) async {
      if (kDebugMode) {
        debugPrint('SignalR [ReceiveSteamUnlocked] recebido: $arguments');
      }

      dynamic updatedData;
      if (arguments != null && arguments.isNotEmpty) {
        updatedData = arguments[0];
        if (updatedData is Map<String, dynamic>) {
          await TokenStorage.updateSessionProfile(updatedData);
        }
      }

      // Dispara callbacks locais
      for (final listener in List<void Function(dynamic)>.from(_steamUnlockedListeners)) {
        listener(updatedData);
      }
    });

    // 2. Escuta snapshots de atualização do Draft (picks, trocas, capitães, etc.)
    _hubConnection?.on('ReceiveDraftStateSnapshot', (List<Object?>? arguments) {
      if (kDebugMode) {
        debugPrint('SignalR [ReceiveDraftStateSnapshot] recebido: $arguments');
      }
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0];
        for (final listener in List<void Function(dynamic)>.from(_draftSnapshotListeners)) {
          listener(data);
        }
      }
    });

    // 3. Escuta consolidação final do Draft
    _hubConnection?.on('ReceiveDraftCompleted', (List<Object?>? arguments) {
      if (kDebugMode) {
        debugPrint('SignalR [ReceiveDraftCompleted] recebido: $arguments');
      }
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0];
        for (final listener in List<void Function(dynamic)>.from(_draftCompletedListeners)) {
          listener(data);
        }
      }
    });

    // 4. Escuta atualizações de travas globais de segurança e modo de manutenção
    _hubConnection?.on('ReceiveSecuritySettingsChanged', (List<Object?>? arguments) {
      if (kDebugMode) {
        debugPrint('SignalR [ReceiveSecuritySettingsChanged] recebido: $arguments');
      }
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0];
        for (final listener in List<void Function(dynamic)>.from(_securitySettingsListeners)) {
          listener(data);
        }
      }
    });
  }

  Future<void> _disposeConnectionOnly() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (_) {}
      _hubConnection = null;
    }
  }

  /// Encerra a conexão com o Hub e limpa assinaturas de grupos (ex: ao fazer logout)
  Future<void> stop() async {
    _connectionEpoch++;
    _connectingFuture = null;
    _joinedTournamentIds.clear();
    await _disposeConnectionOnly();
  }
}
