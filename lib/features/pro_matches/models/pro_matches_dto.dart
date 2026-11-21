import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/app_date_formatter.dart';

/// Link de transmissão externa de uma partida profissional.
class ProStreamLinkDto {
  final String platform;
  final String language;
  final String languageLabel;
  final bool isOfficial;
  final bool isMain;
  final String url;

  const ProStreamLinkDto({
    required this.platform,
    required this.language,
    required this.languageLabel,
    required this.isOfficial,
    required this.isMain,
    required this.url,
  });

  factory ProStreamLinkDto.fromJson(Map<String, dynamic> json) {
    final platform = _readString(json['platform'], fallback: 'Other');
    final language = _readString(json['language']);
    final rawLangLabel = _readString(json['languageLabel']);
    final languageLabel = rawLangLabel.isNotEmpty
        ? rawLangLabel
        : (language.isNotEmpty ? language.toUpperCase() : '');

    return ProStreamLinkDto(
      platform: platform,
      language: language,
      languageLabel: languageLabel,
      isOfficial: json['isOfficial'] == true,
      isMain: json['isMain'] == true,
      url: _readString(json['url']),
    );
  }

  // --- Propriedades de Apresentação (Dumb UI) ---

  String get _normalizedPlatform => platform.trim().toLowerCase();

  bool get isTwitch => _normalizedPlatform == 'twitch';
  bool get isYoutube => _normalizedPlatform == 'youtube';
  bool get isKick => _normalizedPlatform == 'kick';

  String get displayLabel =>
      languageLabel.isNotEmpty ? '$platform • $languageLabel' : platform;

  Color get accentColor {
    if (isTwitch) return AppColors.streamTwitch;
    if (isYoutube) return AppColors.streamYoutube;
    if (isKick) return AppColors.streamKick;
    return AppColors.textSecondary;
  }

  IconData get platformIcon {
    if (isTwitch) return Icons.live_tv_rounded;
    if (isYoutube) return Icons.play_circle_filled_rounded;
    if (isKick) return Icons.bolt_rounded;
    return Icons.open_in_new_rounded;
  }

  bool get hasValidUrl {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  }
}

/// Equipe profissional participante de uma partida do cenário competitivo.
class ProTeamDto {
  final int teamId;
  final String name;
  final String acronym;
  final String? logoUrl;

  const ProTeamDto({
    required this.teamId,
    required this.name,
    required this.acronym,
    this.logoUrl,
  });

  factory ProTeamDto.fromJson(Map<String, dynamic> json) {
    final name = _readString(json['name'], fallback: 'TBD');
    final acronym = _readString(json['acronym']);
    final rawLogo = _readString(json['logoUrl']);

    return ProTeamDto(
      teamId: _readInt(json['teamId']),
      name: name,
      acronym: acronym,
      logoUrl: rawLogo.isNotEmpty ? rawLogo : null,
    );
  }

  static const ProTeamDto tbd = ProTeamDto(
    teamId: 0,
    name: 'A definir',
    acronym: 'TBD',
  );

  // --- Propriedades de Apresentação (Dumb UI) ---

  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;

  String get displayAcronym {
    if (acronym.isNotEmpty) return acronym.toUpperCase();
    final clean = name.trim();
    if (clean.isEmpty) return 'TBD';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 3 ? 3 : clean.length).toUpperCase();
  }
}

/// Partida profissional (Ao Vivo ou Próxima) do cenário competitivo de Dota 2.
class ProMatchDto {
  final int matchId;
  final int tournamentId;
  final String tournamentName;
  final String leagueName;
  final String? leagueLogoUrl;
  final String tier;
  final String tierLabel;
  final String status;
  final String format;
  final DateTime? scheduledAtUtc;
  final ProTeamDto teamA;
  final ProTeamDto teamB;
  final int scoreTeamA;
  final int scoreTeamB;
  final List<ProStreamLinkDto> streams;

  const ProMatchDto({
    required this.matchId,
    required this.tournamentId,
    required this.tournamentName,
    required this.leagueName,
    this.leagueLogoUrl,
    required this.tier,
    required this.tierLabel,
    required this.status,
    required this.format,
    this.scheduledAtUtc,
    required this.teamA,
    required this.teamB,
    required this.scoreTeamA,
    required this.scoreTeamB,
    this.streams = const [],
  });

  factory ProMatchDto.fromJson(Map<String, dynamic> json) {
    final rawLogo = _readString(json['leagueLogoUrl']);
    final rawTeamA = json['teamA'];
    final rawTeamB = json['teamB'];
    final rawStreams = json['streams'];
    final tier = _readString(json['tier'], fallback: 'A').toUpperCase();
    final tierLabel = _readString(
      json['tierLabel'],
      fallback: tier == 'S' ? 'MAJOR' : 'PRO TIER A',
    );

    return ProMatchDto(
      matchId: _readInt(json['matchId']),
      tournamentId: _readInt(json['tournamentId']),
      tournamentName: _readString(json['tournamentName']),
      leagueName: _readString(json['leagueName']),
      leagueLogoUrl: rawLogo.isNotEmpty ? rawLogo : null,
      tier: tier,
      tierLabel: tierLabel,
      status: _readString(json['status'], fallback: 'Upcoming'),
      format: _readString(json['format']),
      scheduledAtUtc: AppDateFormatter.tryParse(json['scheduledAtUtc']),
      teamA: rawTeamA is Map<String, dynamic>
          ? ProTeamDto.fromJson(rawTeamA)
          : ProTeamDto.tbd,
      teamB: rawTeamB is Map<String, dynamic>
          ? ProTeamDto.fromJson(rawTeamB)
          : ProTeamDto.tbd,
      scoreTeamA: _readInt(json['scoreTeamA']),
      scoreTeamB: _readInt(json['scoreTeamB']),
      streams: rawStreams is List
          ? rawStreams
              .whereType<Map<String, dynamic>>()
              .map(ProStreamLinkDto.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  // --- Propriedades de Apresentação (Dumb UI) ---

  bool get isLive => status.trim().toLowerCase() == 'live';
  bool get isUpcoming => !isLive;
  bool get isMajor => tier == 'S';
  bool get hasStreams => streams.isNotEmpty;
  bool get hasFormat => format.trim().isNotEmpty;

  String get tierBadgeText => isMajor ? '$tierLabel • S' : tierLabel;
  Color get tierColor => isMajor ? AppColors.proTierMajor : AppColors.proTierA;
  IconData get tierIcon =>
      isMajor ? Icons.workspace_premium_rounded : Icons.emoji_events_outlined;

  String get formatLabel => format.trim().toUpperCase();
  String get scoreLabel => '$scoreTeamA : $scoreTeamB';

  String get formattedScheduledDate =>
      AppDateFormatter.formatDate(scheduledAtUtc, placeholder: 'Data a definir');

  String get formattedScheduledTime =>
      AppDateFormatter.formatTime(scheduledAtUtc, placeholder: '--:--');

  String get formattedScheduledAt =>
      AppDateFormatter.formatDateTime(scheduledAtUtc, placeholder: 'Horário a definir');
}

/// Agrupamento de partidas profissionais por campeonato/liga.
class ProTournamentGroupDto {
  final int tournamentId;
  final String name;
  final String leagueName;
  final String? leagueLogoUrl;
  final String tier;
  final String tierLabel;
  final String? prizePool;
  final DateTime? beginAtUtc;
  final DateTime? endAtUtc;
  final bool hasLiveMatches;
  final List<ProMatchDto> liveMatches;
  final List<ProMatchDto> upcomingMatches;

  const ProTournamentGroupDto({
    required this.tournamentId,
    required this.name,
    required this.leagueName,
    this.leagueLogoUrl,
    required this.tier,
    required this.tierLabel,
    this.prizePool,
    this.beginAtUtc,
    this.endAtUtc,
    required this.hasLiveMatches,
    this.liveMatches = const [],
    this.upcomingMatches = const [],
  });

  factory ProTournamentGroupDto.fromJson(Map<String, dynamic> json) {
    final rawLogo = _readString(json['leagueLogoUrl']);
    final rawPrize = _readString(json['prizePool']);
    final rawLive = json['liveMatches'];
    final rawUpcoming = json['upcomingMatches'];
    final tier = _readString(json['tier'], fallback: 'A').toUpperCase();
    final tierLabel = _readString(
      json['tierLabel'],
      fallback: tier == 'S' ? 'MAJOR' : 'PRO TIER A',
    );

    final parsedLive = rawLive is List
        ? rawLive
            .whereType<Map<String, dynamic>>()
            .map(ProMatchDto.fromJson)
            .toList(growable: false)
        : const <ProMatchDto>[];

    final parsedUpcoming = rawUpcoming is List
        ? rawUpcoming
            .whereType<Map<String, dynamic>>()
            .map(ProMatchDto.fromJson)
            .toList(growable: false)
        : const <ProMatchDto>[];

    final explicitHasLive = json['hasLiveMatches'] == true;

    return ProTournamentGroupDto(
      tournamentId: _readInt(json['tournamentId']),
      name: _readString(json['name'], fallback: 'Campeonato Profissional'),
      leagueName: _readString(json['leagueName']),
      leagueLogoUrl: rawLogo.isNotEmpty ? rawLogo : null,
      tier: tier,
      tierLabel: tierLabel,
      prizePool: rawPrize.isNotEmpty ? rawPrize : null,
      beginAtUtc: AppDateFormatter.tryParse(json['beginAtUtc']),
      endAtUtc: AppDateFormatter.tryParse(json['endAtUtc']),
      hasLiveMatches: explicitHasLive || parsedLive.isNotEmpty,
      liveMatches: parsedLive,
      upcomingMatches: parsedUpcoming,
    );
  }

  // --- Propriedades de Apresentação (Dumb UI) ---

  bool get hasLogo => leagueLogoUrl != null && leagueLogoUrl!.isNotEmpty;
  bool get hasTier => tier.isNotEmpty;
  bool get isMajor => tier == 'S';
  bool get hasPrizePool => prizePool != null && prizePool!.isNotEmpty;
  int get totalMatchesCount => liveMatches.length + upcomingMatches.length;

  String get tierBadgeText => isMajor ? '$tierLabel • S' : tierLabel;

  Color get tierColor => isMajor ? AppColors.proTierMajor : AppColors.proTierA;

  IconData get tierIcon =>
      isMajor ? Icons.workspace_premium_rounded : Icons.emoji_events_outlined;

  String get periodLabel {
    if (beginAtUtc != null && endAtUtc != null) {
      return '${AppDateFormatter.formatDate(beginAtUtc)} até ${AppDateFormatter.formatDate(endAtUtc)}';
    }
    if (beginAtUtc != null) {
      return 'Início: ${AppDateFormatter.formatDate(beginAtUtc)}';
    }
    return '';
  }

  bool get hasPeriod => periodLabel.isNotEmpty;
}

/// Resposta consolidada de `GET /api/v1/pro-matches`.
class ProMatchesOverviewDto {
  final bool isConfigured;
  final DateTime? fetchedAtUtc;
  final List<ProMatchDto> liveMatches;
  final List<ProTournamentGroupDto> tournaments;

  const ProMatchesOverviewDto({
    required this.isConfigured,
    this.fetchedAtUtc,
    this.liveMatches = const [],
    this.tournaments = const [],
  });

  factory ProMatchesOverviewDto.fromJson(Map<String, dynamic> json) {
    final rawLive = json['liveMatches'];
    final rawTournaments = json['tournaments'];

    return ProMatchesOverviewDto(
      isConfigured: json['isConfigured'] == true,
      fetchedAtUtc: AppDateFormatter.tryParse(json['fetchedAtUtc']),
      liveMatches: rawLive is List
          ? rawLive
              .whereType<Map<String, dynamic>>()
              .map(ProMatchDto.fromJson)
              .toList(growable: false)
          : const [],
      tournaments: rawTournaments is List
          ? rawTournaments
              .whereType<Map<String, dynamic>>()
              .map(ProTournamentGroupDto.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  // --- Propriedades de Apresentação (Dumb UI) ---

  String get formattedFetchedAt =>
      AppDateFormatter.formatDateTime(fetchedAtUtc, placeholder: 'Agora');

  int get totalLiveCount {
    if (liveMatches.isNotEmpty) return liveMatches.length;
    return tournaments.fold<int>(0, (sum, t) => sum + t.liveMatches.length);
  }

  int get totalUpcomingCount =>
      tournaments.fold<int>(0, (sum, t) => sum + t.upcomingMatches.length);

  int get totalMatchesCount =>
      tournaments.fold<int>(0, (sum, t) => sum + t.totalMatchesCount);

  int get totalMajorCount => tournaments
      .where((t) => t.isMajor)
      .fold<int>(0, (sum, t) => sum + t.totalMatchesCount);

  int get totalTierACount => tournaments
      .where((t) => !t.isMajor)
      .fold<int>(0, (sum, t) => sum + t.totalMatchesCount);

  bool get hasTournaments => tournaments.isNotEmpty;
}

// --- Helpers internos seguros de parsing ---

String _readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim()) ?? fallback;
}
