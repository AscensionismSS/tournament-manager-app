import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

/// Serviço singleton para gerenciar conexões em tempo real via SignalR (Hub /hubs/v1/tournament-draft).
/// Escuta notificações em tempo real, como liberação de conta Steam ("ReceiveSteamUnlocked"),
/// drafts de torneios e atualizações de partidas.
class SignalRService {
  static SignalRService? _instance;
  static SignalRService get instance => _instance ??= SignalRService._();

  SignalRService._();

  HubConnection? _hubConnection;
  bool _isConnecting = false;
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

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

  /// Entra no canal SignalR do draft do torneio
  Future<void> joinTournamentDraft(String tournamentId) async {
    if (isConnected) {
      try {
        await _hubConnection?.invoke('JoinTournamentDraft', args: [tournamentId]);
      } catch (e) {
        if (kDebugMode) debugPrint('Erro ao entrar no grupo de draft: $e');
      }
    }
  }

  /// Sai do canal SignalR do draft do torneio
  Future<void> leaveTournamentDraft(String tournamentId) async {
    if (isConnected) {
      try {
        await _hubConnection?.invoke('LeaveTournamentDraft', args: [tournamentId]);
      } catch (e) {
        if (kDebugMode) debugPrint('Erro ao sair do grupo de draft: $e');
      }
    }
  }

  /// Inicia conexão com o Hub SignalR autenticado via access_token
  Future<void> connect() async {
    if (isConnected || _isConnecting) return;

    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return;

    _isConnecting = true;
    final hubUrl = ApiEndpoints.tournamentDraftHubUrl;

    try {
      await stop();
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              skipNegotiation: false,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _setupHandlers();

      await _hubConnection!.start();
      if (kDebugMode) {
        debugPrint('SignalR conectado ao Hub: $hubUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Aviso SignalR Hub (offline ou reconectando): $e');
      }
    } finally {
      _isConnecting = false;
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

  /// Encerra a conexão com o Hub (ex: ao fazer logout)
  Future<void> stop() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (_) {}
      _hubConnection = null;
    }
  }
}
