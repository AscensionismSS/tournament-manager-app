import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'sse_connector.dart';
import 'tournament_webhook_event_dto.dart';

/// Serviço centralizado de Server-Sent Events (SSE) para Campeonatos:
/// 1. Rota Global (`GET /api/v1/tournaments/events`): alimenta o Sininho no Header e dispara `AppFeedback` em qualquer tela.
/// 2. Rota do Torneio (`GET /api/v1/tournaments/{id}/events`): alimenta a tela específica `/tournaments/:id` para recarregar chaves e partidas em tempo real.
class TournamentEventsService {
  TournamentEventsService._();
  static final TournamentEventsService instance = TournamentEventsService._();

  /// Lista reativa de notificações para o Sininho na TopBar (mais recentes no topo)
  final ValueNotifier<List<TournamentWebhookEventDto>> notifications =
      ValueNotifier<List<TournamentWebhookEventDto>>([]);

  /// Contador reativo de notificações não lidas (acende a bolinha vermelha no Sininho)
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Stream broadcast para exibir o toast flutuante (`AppFeedback`) e avisar telas ativas
  final StreamController<TournamentWebhookEventDto> _eventBroadcast =
      StreamController<TournamentWebhookEventDto>.broadcast();

  Stream<TournamentWebhookEventDto> get events => _eventBroadcast.stream;

  StreamSubscription<String>? _globalSub;
  bool _isGlobalRunning = false;

  /// Cache leve das últimas chaves de evento para deduplicação instantânea
  final Map<String, DateTime> _recentDedupKeys = {};

  /// Inicia a escuta global (`GET /api/v1/tournaments/events`) no `MainShell`,
  /// limpando antes eventuais conexões `EventSource` órfãs de um Hot Restart no navegador.
  void startGlobalStream() {
    if (_isGlobalRunning) return;
    cleanupStaleSseConnections();
    _isGlobalRunning = true;
    _globalSub?.cancel();
    _globalSub = connectSseStream(ApiEndpoints.tournamentEventsGlobal)
        .listen(_handleRawJsonPayload);
  }

  /// Encerra a escuta global ao destruir o `MainShell`
  void stopGlobalStream() {
    _isGlobalRunning = false;
    _globalSub?.cancel();
    _globalSub = null;
  }

  /// Abre uma conexão SSE dedicada para um campeonato específico (`GET /api/v1/tournaments/{id}/events`).
  /// Quando o `StreamSubscription` da tela é cancelado no `dispose()`, o `EventSource` é fechado imediatamente.
  Stream<TournamentWebhookEventDto> subscribeToTournament(String tournamentId) {
    return connectSseStream(ApiEndpoints.tournamentEventsById(tournamentId))
        .map(_decodePayload)
        .where((evt) => evt != null)
        .cast<TournamentWebhookEventDto>()
        .map((evt) {
      _ingestEvent(evt);
      return evt;
    });
  }

  void _handleRawJsonPayload(String payload) {
    final evt = _decodePayload(payload);
    if (evt != null) {
      _ingestEvent(evt);
    }
  }

  TournamentWebhookEventDto? _decodePayload(String payload) {
    if (payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return TournamentWebhookEventDto.fromJson(decoded);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SSE] Falha ao decodificar evento: $e');
      }
    }
    return null;
  }

  /// Injeta um evento sintético ou manual diretamente no Sininho de Notificações e no broadcast global
  void pushNotification(TournamentWebhookEventDto evt) {
    _ingestEvent(evt);
  }

  void _ingestEvent(TournamentWebhookEventDto evt) {
    final now = DateTime.now();
    _recentDedupKeys.removeWhere(
      (_, timestamp) => now.difference(timestamp).inSeconds > 15,
    );

    if (_recentDedupKeys.containsKey(evt.dedupKey)) {
      return;
    }
    _recentDedupKeys[evt.dedupKey] = now;

    // 1. Adiciona no topo da lista do Sininho (máximo de 30 itens em RAM)
    final updated = [evt, ...notifications.value];
    if (updated.length > 30) {
      updated.removeRange(30, updated.length);
    }
    notifications.value = updated;
    unreadCount.value = updated.where((n) => !n.isRead).length;

    // 2. Emite para o MainShell (mostrar AppFeedback) e ouvintes ativos
    if (!_eventBroadcast.isClosed) {
      _eventBroadcast.add(evt);
    }
  }

  /// Marca todas as notificações do Sininho como lidas (apaga a bolinha vermelha)
  void markAllAsRead() {
    if (unreadCount.value == 0) return;
    notifications.value =
        notifications.value.map((n) => n.copyWith(isRead: true)).toList();
    unreadCount.value = 0;
  }

  /// Marca uma notificação específica como lida ao clicar nela
  void markAsRead(String dedupKey) {
    notifications.value = notifications.value.map((n) {
      if (n.dedupKey == dedupKey && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    unreadCount.value = notifications.value.where((n) => !n.isRead).length;
  }

  /// Limpa o histórico em memória do Sininho
  void clearAll() {
    notifications.value = [];
    unreadCount.value = 0;
  }
}
