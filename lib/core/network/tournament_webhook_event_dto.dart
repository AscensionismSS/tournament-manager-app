import 'package:flutter/material.dart';
import '../utils/app_date_formatter.dart';

/// DTO que espelha fielmente `Tournaments.Contracts.Tournaments.TournamentWebhookEventDto`
/// enviado pelo backend via Server-Sent Events (`GET /api/v1/tournaments/events` e `/{id}/events`).
class TournamentWebhookEventDto {
  final String tournamentId;
  final String tournamentName;
  final String eventType;
  final String message;
  final int version;
  final String status;
  final String? matchSeriesId;
  final String? slotCode;
  final String? winnerTeamName;
  final DateTime timestampUtc;
  final bool isRead;

  const TournamentWebhookEventDto({
    required this.tournamentId,
    required this.tournamentName,
    required this.eventType,
    required this.message,
    required this.version,
    required this.status,
    this.matchSeriesId,
    this.slotCode,
    this.winnerTeamName,
    required this.timestampUtc,
    this.isRead = false,
  });

  /// Chave única de deduplicação para evitar que o stream global e o stream da página
  /// disparem duas notificações idênticas no mesmo instante.
  String get dedupKey =>
      '$tournamentId:$version:$eventType:${matchSeriesId ?? ""}:${slotCode ?? ""}';

  /// Horário relativo amigável pronto para exibição no Sininho (Dumb UI)
  String get formattedTime =>
      AppDateFormatter.formatRelative(timestampUtc, placeholder: 'Agora');

  /// Indica se é um evento de reversão/rollback administrativo ou trava de resultados
  bool get isWarningEvent =>
      eventType == 'MatchReverted' ||
      eventType == 'TournamentResultsLocked' ||
      eventType == 'SecuritySettingsUpdated';

  /// Indica se é o evento de coroação do campeão ou avanço importante
  bool get isHighlightEvent =>
      eventType == 'TournamentCompleted' ||
      eventType == 'PlayoffsGenerated' ||
      eventType == 'GroupStageCompleted' ||
      eventType == 'TournamentStarted';

  /// Ícone temático de acordo com o `EventType` enviado pelo backend
  IconData get eventIcon {
    switch (eventType) {
      case 'TournamentStarted':
        return Icons.rocket_launch_rounded;
      case 'MatchGameRecorded':
        return Icons.sports_esports_rounded;
      case 'GroupMatchCompleted':
        return Icons.grid_view_rounded;
      case 'GroupStageCompleted':
        return Icons.emoji_events_rounded;
      case 'PlayoffsGenerated':
        return Icons.account_tree_rounded;
      case 'BracketProgressed':
        return Icons.trending_up_rounded;
      case 'TournamentCompleted':
        return Icons.emoji_events_rounded;
      case 'MatchReverted':
        return Icons.history_rounded;
      case 'TournamentResultsLocked':
        return Icons.lock_clock_rounded;
      case 'TournamentResultsUnlocked':
        return Icons.lock_open_rounded;
      case 'SecuritySettingsUpdated':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  TournamentWebhookEventDto copyWith({bool? isRead}) {
    return TournamentWebhookEventDto(
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      eventType: eventType,
      message: message,
      version: version,
      status: status,
      matchSeriesId: matchSeriesId,
      slotCode: slotCode,
      winnerTeamName: winnerTeamName,
      timestampUtc: timestampUtc,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Aceita tanto PascalCase (`JsonSerializer.Serialize` padrão do SSE no backend)
  /// quanto camelCase.
  factory TournamentWebhookEventDto.fromJson(Map<String, dynamic> json) {
    return TournamentWebhookEventDto(
      tournamentId:
          (json['TournamentId'] ?? json['tournamentId'] ?? '').toString(),
      tournamentName: (json['TournamentName'] ??
              json['tournamentName'] ??
              'Campeonato')
          .toString(),
      eventType: (json['EventType'] ?? json['eventType'] ?? '').toString(),
      message: (json['Message'] ?? json['message'] ?? '').toString(),
      version: (json['Version'] ?? json['version']) is num
          ? ((json['Version'] ?? json['version']) as num).toInt()
          : int.tryParse(
                  (json['Version'] ?? json['version'] ?? '0').toString()) ??
              0,
      status: (json['Status'] ?? json['status'] ?? '').toString(),
      matchSeriesId:
          (json['MatchSeriesId'] ?? json['matchSeriesId'])?.toString(),
      slotCode: (json['SlotCode'] ?? json['slotCode'])?.toString(),
      winnerTeamName:
          (json['WinnerTeamName'] ?? json['winnerTeamName'])?.toString(),
      timestampUtc: AppDateFormatter.tryParse(
            json['TimestampUtc'] ?? json['timestampUtc'],
          ) ??
          DateTime.now().toUtc(),
    );
  }
}

