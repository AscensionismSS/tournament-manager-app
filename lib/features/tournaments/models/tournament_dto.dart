import 'package:flutter/material.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/utils/dota_rank_helper.dart';
import 'bracket_slot_dto.dart';
import 'tournament_status.dart';

class DraftPlayerSummaryDto {
  final String id;
  final String name;
  final String? externalUserId;
  final List<String> roles;
  final String? preferredRole;
  final int? rankTier;
  final String? avatarUrl;
  final String? dotaFriendId;
  final String? steamProfileUrl;

  const DraftPlayerSummaryDto({
    required this.id,
    required this.name,
    this.externalUserId,
    this.roles = const [],
    this.preferredRole,
    this.rankTier,
    this.avatarUrl,
    this.dotaFriendId,
    this.steamProfileUrl,
  });

  factory DraftPlayerSummaryDto.fromJson(Map<String, dynamic> json) {
    return DraftPlayerSummaryDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Jogador',
      externalUserId: json['externalUserId']?.toString(),
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      preferredRole: json['preferredRole']?.toString(),
      rankTier: (json['rankTier'] as num?)?.toInt(),
      avatarUrl: json['avatarUrl']?.toString(),
      dotaFriendId: json['dotaFriendId']?.toString(),
      steamProfileUrl: json['steamProfileUrl']?.toString(),
    );
  }

  /// Iniciais para avatar
  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Tier numérico da Valve (0 a 8)
  int get tierNumber => DotaRankHelper.parseTierNumber(rankTier);

  /// Estrelas da medalha (1 a 5)
  int get rankStars => DotaRankHelper.parseRankStars(rankTier);

  /// Nome formatado da medalha
  String get rankDetail => DotaRankHelper.formatRankDetail(rankTier: rankTier);

  /// URL direta do perfil no OpenDota
  String? get openDotaUrl {
    final fid = dotaFriendId;
    if (fid != null && fid.trim().isNotEmpty) {
      return 'https://www.opendota.com/players/${fid.trim()}';
    }
    return null;
  }

  /// URL computada da Steam
  String? get computedSteamProfileUrl {
    final url = steamProfileUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return null;
  }
}

/// DTO oficial de dados de um torneio da arena (Tournaments.Contracts/Tournaments/TournamentDto).
/// Segue a diretriz de UI Passiva: propriedades visuais e formatadas calculadas diretamente no modelo.
class TournamentDto {
  final String id;
  final String name;
  final TournamentStatus status;
  final int teamCount;
  final int groupCount;
  final String formatType;
  final String playoffFormat;
  final String? groupStageSeriesFormat;
  final String playoffSeriesFormat;
  final String grandFinalSeriesFormat;
  final String? draftSessionId;
  final String? bannerUrl;
  final String? championId;
  final String? championName;
  final DateTime createdAtUtc;
  final DateTime? startDateUtc;
  final DateTime? endDateUtc;
  final String? prizePool;
  final String? rules;
  final List<TournamentTeamDto> teams;
  final List<BracketSlotDto> bracketSlots;
  final int version;
  final DateTime? lastUpdatedAtUtc;
  final int? registeredPlayerCount;
  final List<DraftPlayerSummaryDto> draftPlayerPool;
  final bool canStartTournament;
  final bool isResultSubmissionLocked;
  final String? resultLockReason;
  final DateTime? resultLockedAtUtc;

  const TournamentDto({
    required this.id,
    required this.name,
    required this.status,
    required this.teamCount,
    this.groupCount = 0,
    required this.formatType,
    required this.playoffFormat,
    this.groupStageSeriesFormat,
    this.playoffSeriesFormat = 'Bo3',
    this.grandFinalSeriesFormat = 'Bo5',
    this.draftSessionId,
    this.bannerUrl,
    this.championId,
    this.championName,
    required this.createdAtUtc,
    this.startDateUtc,
    this.endDateUtc,
    this.prizePool,
    this.rules,
    this.teams = const [],
    this.bracketSlots = const [],
    this.version = 1,
    this.lastUpdatedAtUtc,
    this.registeredPlayerCount,
    this.draftPlayerPool = const [],
    this.canStartTournament = false,
    this.isResultSubmissionLocked = false,
    this.resultLockReason,
    this.resultLockedAtUtc,
  });

  factory TournamentDto.fromJson(Map<String, dynamic> json) {
    final rawTeams = json['teams'] as List<dynamic>? ?? [];
    final rawSlots = json['bracketSlots'] as List<dynamic>? ?? [];

    return TournamentDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Torneio sem nome',
      status: TournamentStatus.fromValue(json['status']),
      teamCount: json['teamCount'] as int? ?? 8,
      groupCount: json['groupCount'] as int? ?? 0,
      formatType: json['formatType']?.toString() ?? 'DirectPlayoffs',
      playoffFormat: json['playoffFormat']?.toString() ?? 'SingleElimination',
      groupStageSeriesFormat: json['groupStageSeriesFormat']?.toString(),
      playoffSeriesFormat: json['playoffSeriesFormat']?.toString() ?? 'Bo3',
      grandFinalSeriesFormat: json['grandFinalSeriesFormat']?.toString() ?? 'Bo5',
      draftSessionId: json['draftSessionId']?.toString(),
      bannerUrl: json['bannerUrl']?.toString() ?? json['banner']?.toString(),
      championId: json['championId']?.toString(),
      championName: json['championName']?.toString(),
      createdAtUtc: AppDateFormatter.tryParse(
        json['createdAtUtc'],
        fallback: DateTime.now(),
      )!,
      startDateUtc: AppDateFormatter.tryParse(json['startDateUtc'] ?? json['startDate']),
      endDateUtc: AppDateFormatter.tryParse(json['endDateUtc'] ?? json['endDate']),
      prizePool: json['prizePool']?.toString(),
      rules: json['rules']?.toString() ?? json['regulation']?.toString(),
      teams: rawTeams
          .whereType<Map<String, dynamic>>()
          .map(TournamentTeamDto.fromJson)
          .toList(),
      bracketSlots: rawSlots
          .whereType<Map<String, dynamic>>()
          .map(BracketSlotDto.fromJson)
          .toList(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      lastUpdatedAtUtc: AppDateFormatter.tryParse(json['lastUpdatedAtUtc']),
      registeredPlayerCount: (json['registeredPlayerCount'] as num?)?.toInt(),
      draftPlayerPool: (json['draftPlayerPool'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DraftPlayerSummaryDto.fromJson)
              .toList() ??
          const [],
      canStartTournament: json['canStartTournament'] as bool? ?? false,
      isResultSubmissionLocked: json['isResultSubmissionLocked'] as bool? ?? false,
      resultLockReason: json['resultLockReason']?.toString(),
      resultLockedAtUtc: AppDateFormatter.tryParse(json['resultLockedAtUtc']),
    );
  }

  // --- Getters Utilitários para Dumb UI ---

  String get resultLockReasonLabel =>
      (resultLockReason != null && resultLockReason!.trim().isNotEmpty)
          ? resultLockReason!.trim()
          : 'O envio de novos resultados para este campeonato foi temporariamente suspenso pela organização.';

  int get registeredTeamsCount => teams.length;

  bool get hasGroupStage => formatType != 'DirectPlayoffs' && groupCount > 0;

  int get teamsPerGroup =>
      hasGroupStage && groupCount > 0 ? (teamCount ~/ groupCount) : teamCount;

  String get groupStageMdLabel =>
      (groupStageSeriesFormat ?? 'Bo1').toUpperCase().replaceAll('BO', 'MD');

  String get playoffMdLabel =>
      playoffSeriesFormat.toUpperCase().replaceAll('BO', 'MD');

  String get grandFinalMdLabel =>
      grandFinalSeriesFormat.toUpperCase().replaceAll('BO', 'MD');

  String? get resolvedBannerUrl => ApiEndpoints.resolveMediaUrl(bannerUrl);

  bool get hasBanner => resolvedBannerUrl != null && resolvedBannerUrl!.isNotEmpty;

  String get formattedCreatedAt => AppDateFormatter.formatDateTime(createdAtUtc);

  String get formattedDateOnly => AppDateFormatter.formatDate(createdAtUtc);

  String get startDateLabel =>
      startDateUtc != null ? AppDateFormatter.formatDate(startDateUtc) : 'A definir';

  String get endDateLabel =>
      endDateUtc != null ? AppDateFormatter.formatDate(endDateUtc) : 'A definir';

  String get periodSummaryLabel =>
      startDateUtc != null && endDateUtc != null
          ? '$startDateLabel até $endDateLabel'
          : (startDateUtc != null ? 'Início: $startDateLabel' : 'Datas a definir');

  String get prizePoolLabel =>
      prizePool != null && prizePool!.trim().isNotEmpty ? prizePool!.trim() : 'A definir';

  String get rulesLabel =>
      rules != null && rules!.trim().isNotEmpty
          ? rules!.trim()
          : 'O regulamento oficial e as diretrizes da competição serão exibidos aqui.';

  /// Status principal único para exibição limpa no topo do banner
  String get bannerPrimaryStatusLabel => status.label;

  Color get bannerPrimaryStatusColor => status.color;

  IconData get bannerPrimaryStatusIcon => status.icon;

  bool get isRegistrationOpen => status == TournamentStatus.registrationOpen;

  bool get isRegistrationClosed =>
      status != TournamentStatus.registrationOpen &&
      status != TournamentStatus.draft;

  String get registrationStatusLabel {
    if (status == TournamentStatus.draft) return 'Rascunho';
    return isRegistrationOpen ? 'Inscrições Abertas' : 'Inscrições Fechadas';
  }

  IconData get registrationStatusIcon {
    if (status == TournamentStatus.draft) return Icons.edit_note_rounded;
    return isRegistrationOpen ? Icons.how_to_reg_rounded : Icons.lock_outline_rounded;
  }

  Color get registrationStatusColor {
    if (status == TournamentStatus.draft) return AppColors.textSecondary;
    return isRegistrationOpen ? AppColors.dotaGold : AppColors.textSecondary;
  }

  String get formatLabel {
    switch (formatType) {
      case 'DirectPlayoffs':
        return 'Mata-Mata Direto';
      case 'GroupStageAndPlayoffs':
        return 'Grupos + Playoffs';
      case 'GroupStageDirectFinal':
        return 'Grupos + Final Direta';
      default:
        return formatType;
    }
  }

  String get playoffFormatLabel {
    switch (playoffFormat) {
      case 'SingleElimination':
        return 'Eliminatória Simples';
      case 'DoubleElimination':
        return 'Eliminatória Dupla';
      default:
        return playoffFormat;
    }
  }

  bool get isDoubleElimination => playoffFormat == 'DoubleElimination';

  bool get isSingleElimination => playoffFormat == 'SingleElimination';

  String get fullFormatSummary => '$formatLabel ($playoffFormatLabel)';

  String get teamsProgressLabel {
    if (hasDraftSession) {
      if (status == TournamentStatus.registrationOpen ||
          status == TournamentStatus.draft ||
          status == TournamentStatus.drafting) {
        final count = registeredPlayerCount ?? draftPlayerPool.length;
        return '$count ${count == 1 ? "jogador inscrito" : "jogadores inscritos"}';
      }
      return '$registeredTeamsCount / $teamCount times';
    }
    return '$registeredTeamsCount / $teamCount times';
  }

  int get availableSlots => (teamCount - registeredTeamsCount).clamp(0, teamCount);

  bool get isFull => registeredTeamsCount >= teamCount;

  double get occupancyProgress =>
      teamCount > 0 ? (registeredTeamsCount / teamCount).clamp(0.0, 1.0) : 0.0;

  String get slotsSummaryLabel => isFull
      ? 'Vagas Esgotadas'
      : '$availableSlots ${availableSlots == 1 ? "vaga disponível" : "vagas disponíveis"}';

  bool get hasDraftSession => draftSessionId != null && draftSessionId!.isNotEmpty;

  String get entryModeLabel => hasDraftSession ? 'Draft de Jogadores' : 'Times Fechados';

  IconData get entryModeIcon =>
      hasDraftSession ? Icons.shuffle_rounded : Icons.shield_rounded;

  Color get entryModeColor =>
      hasDraftSession ? AppColors.primaryNeon : AppColors.dotaGoldLight;

  bool get hasChampion => championName != null && championName!.trim().isNotEmpty;

  String get actionCtaLabel =>
      isRegistrationOpen ? 'ACESSAR INSCRIÇÃO' : 'VER CAMPEONATO';
}
