import 'player_game_stats_dto.dart';

/// DTO de um mapa individual dentro de uma série (Tournaments.Contracts/Matches/MatchGameDto).
class MatchGameDto {
  final String id;
  final int gameNumber;
  final String resultSource;
  final String winnerTeamId;
  final int durationSeconds;
  final int teamAKills;
  final int teamBKills;
  final bool isWalkover;
  final int? dotaMatchId;
  final String? firstPickTeamId;
  final List<int> teamABanHeroIds;
  final List<int> teamBBanHeroIds;
  final List<PlayerGameStatsDto> playerStats;
  final int teamARoshanKills;
  final int teamBRoshanKills;
  final int teamAAegisStolen;
  final int teamBAegisStolen;

  const MatchGameDto({
    required this.id,
    required this.gameNumber,
    required this.resultSource,
    required this.winnerTeamId,
    this.durationSeconds = 0,
    this.teamAKills = 0,
    this.teamBKills = 0,
    this.isWalkover = false,
    this.dotaMatchId,
    this.firstPickTeamId,
    this.teamABanHeroIds = const [],
    this.teamBBanHeroIds = const [],
    this.playerStats = const [],
    this.teamARoshanKills = 0,
    this.teamBRoshanKills = 0,
    this.teamAAegisStolen = 0,
    this.teamBAegisStolen = 0,
  });

  factory MatchGameDto.fromJson(Map<String, dynamic> json) {
    return MatchGameDto(
      id: json['id']?.toString() ?? '',
      gameNumber: json['gameNumber'] as int? ?? 1,
      resultSource: json['resultSource']?.toString() ?? 'Manual',
      winnerTeamId: json['winnerTeamId']?.toString() ?? '',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      teamAKills: (json['teamAKills'] as num?)?.toInt() ?? 0,
      teamBKills: (json['teamBKills'] as num?)?.toInt() ?? 0,
      isWalkover: json['isWalkover'] as bool? ?? false,
      dotaMatchId: (json['dotaMatchId'] as num?)?.toInt(),
      firstPickTeamId: (json['firstPickTeamId'] ?? json['FirstPickTeamId'])?.toString(),
      teamABanHeroIds: (json['teamABanHeroIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      teamBBanHeroIds: (json['teamBBanHeroIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      playerStats: (json['playerStats'] as List<dynamic>?)
              ?.map((e) => PlayerGameStatsDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      teamARoshanKills: ((json['teamARoshanKills'] ?? json['team_a_roshan_kills']) as num?)?.toInt() ?? 0,
      teamBRoshanKills: ((json['teamBRoshanKills'] ?? json['team_b_roshan_kills']) as num?)?.toInt() ?? 0,
      teamAAegisStolen: ((json['teamAAegisStolen'] ?? json['team_a_aegis_stolen']) as num?)?.toInt() ?? 0,
      teamBAegisStolen: ((json['teamBAegisStolen'] ?? json['team_b_aegis_stolen']) as num?)?.toInt() ?? 0,
    );
  }

  bool get isManual => resultSource.toLowerCase() == 'manual';

  bool get isReplay => resultSource.toLowerCase() == 'replayparser';

  /// Determina se o Time A teve o First Pick no confronto (sem fallback pré-definido).
  bool isTeamAFirstPick(String? teamAId) {
    if (firstPickTeamId != null && firstPickTeamId!.isNotEmpty && teamAId != null) {
      return firstPickTeamId == teamAId;
    }
    return false;
  }

  /// Determina se o Time B teve o First Pick no confronto (sem fallback pré-definido).
  bool isTeamBFirstPick(String? teamBId) {
    if (firstPickTeamId != null && firstPickTeamId!.isNotEmpty && teamBId != null) {
      return firstPickTeamId == teamBId;
    }
    return false;
  }

  /// Duração formatada em mm:ss
  String get formattedDuration {
    if (isWalkover) return 'W.O.';
    if (durationSeconds <= 0) return '--:--';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Retorna os abates formatados
  String get formattedScore => '$teamAKills - $teamBKills';
}
