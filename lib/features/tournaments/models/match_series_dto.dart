import '../../draft/models/draft_team_dto.dart';
import 'match_game_dto.dart';
import 'tournament_team_dto.dart';

/// DTO de série/confronto do campeonato (Tournaments.Contracts/Matches/MatchSeriesDto).
class MatchSeriesDto {
  final String id;
  final String tournamentId;
  final String slotCode;
  final String format;
  final String status;
  final String? teamAId;
  final String? teamAName;
  final int scoreTeamA;
  final String? teamBId;
  final String? teamBName;
  final int scoreTeamB;
  final String? winnerTeamId;
  final String? loserTeamId;
  final List<MatchGameDto> games;
  final int round;

  const MatchSeriesDto({
    required this.id,
    required this.tournamentId,
    required this.slotCode,
    required this.format,
    required this.status,
    this.teamAId,
    this.teamAName,
    this.scoreTeamA = 0,
    this.teamBId,
    this.teamBName,
    this.scoreTeamB = 0,
    this.winnerTeamId,
    this.loserTeamId,
    this.games = const [],
    this.round = 1,
  });

  factory MatchSeriesDto.fromJson(Map<String, dynamic> json) {
    int parsedRound = (json['round'] ?? json['roundNumber']) as int? ?? 1;
    final slot = json['slotCode']?.toString() ?? '';
    final rMatch = RegExp(r'_R(\d+)_').firstMatch(slot);
    if (rMatch != null && parsedRound == 1) {
      parsedRound = int.tryParse(rMatch.group(1)!) ?? 1;
    }

    return MatchSeriesDto(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournamentId']?.toString() ?? '',
      slotCode: slot,
      format: json['format']?.toString() ?? 'Bo1',
      status: json['status']?.toString() ?? 'Pending',
      teamAId: json['teamAId']?.toString(),
      teamAName: json['teamAName']?.toString(),
      scoreTeamA: json['scoreTeamA'] as int? ?? 0,
      teamBId: json['teamBId']?.toString(),
      teamBName: json['teamBName']?.toString(),
      scoreTeamB: json['scoreTeamB'] as int? ?? 0,
      winnerTeamId: json['winnerTeamId']?.toString(),
      loserTeamId: json['loserTeamId']?.toString(),
      games: (json['games'] as List<dynamic>?)
              ?.map((e) => MatchGameDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      round: parsedRound,
    );
  }

  bool get isGroupStageMatch {
    final code = slotCode.toUpperCase();
    return code.startsWith('G_') ||
        code.startsWith('GA_') ||
        code.startsWith('GB_');
  }

  bool get isPlayoffMatch => !isGroupStageMatch;

  bool get isGroupAMatch => slotCode.toUpperCase().startsWith('GA_');

  bool get isGroupBMatch => slotCode.toUpperCase().startsWith('GB_');

  bool get isCompleted => status.toLowerCase() == 'completed';

  bool get isOngoing =>
      status.toLowerCase() == 'ongoing' ||
      (!isCompleted && games.isNotEmpty);

  bool get isPending => status.toLowerCase() == 'pending';

  bool get isTeamAWinner =>
      winnerTeamId != null && teamAId != null && winnerTeamId == teamAId;

  bool get isTeamBWinner =>
      winnerTeamId != null && teamBId != null && winnerTeamId == teamBId;

  String? get winnerTeamName {
    if (winnerTeamId == null) return null;
    if (winnerTeamId == teamAId) return teamAName;
    if (winnerTeamId == teamBId) return teamBName;
    return null;
  }

  String get statusBadgeLabel {
    if (isCompleted) return 'FINALIZADO';
    if (isOngoing || games.isNotEmpty) return 'EM ANDAMENTO';
    return 'A DEFINIR';
  }

  String get mdBadgeLabel => format.toUpperCase().replaceAll('BO', 'MD');

  /// Número sequencial da partida na rodada (ex: extraído de 'G_R1_M2' -> 2)
  int get matchNumber {
    final mMatch = RegExp(r'_M(\d+)').firstMatch(slotCode);
    if (mMatch != null) {
      return int.tryParse(mMatch.group(1)!) ?? 1;
    }
    return 1;
  }

  String get displayTeamA =>
      teamAName != null && teamAName!.trim().isNotEmpty ? teamAName! : 'A definir';

  String get displayTeamB =>
      teamBName != null && teamBName!.trim().isNotEmpty ? teamBName! : 'A definir';

  /// Número máximo de mapas possíveis conforme o formato (MD1 = 1, MD2 = 2, MD3 = 3, MD5 = 5)
  int get maxGames {
    final clean = format.toUpperCase();
    if (clean.contains('5')) return 5;
    if (clean.contains('3')) return 3;
    if (clean.contains('2')) return 2;
    return 1;
  }

  /// Vitórias necessárias para fechar a série (MD1 = 1, MD3 = 2, MD5 = 3)
  int get winsNeeded => (maxGames / 2).ceil();

  /// Se a série já foi definida (um time atingiu as vitórias necessárias ou status concluído)
  bool get isSeriesDecided =>
      isCompleted || scoreTeamA >= winsNeeded || scoreTeamB >= winsNeeded;

  /// Retorna o mapa jogado pelo número do game (1-based)
  MatchGameDto? gameByNumber(int gameNumber) {
    for (final g in games) {
      if (g.gameNumber == gameNumber) return g;
    }
    return null;
  }

  /// Verifica se um mapa específico ainda é necessário
  bool isGameNeeded(int gameNumber) {
    if (gameNumber <= games.length) return true;
    if (isSeriesDecided) return false;
    return true;
  }

  /// Próximo mapa a ser disputado (1-based), ou null se já concluído
  int? get nextGameNumber {
    if (isSeriesDecided) return null;
    return games.length + 1;
  }

  /// Total de mapas exibidos na barra do modal de detalhes (sempre exibe todos os slots da série: G1..G3, G1..G5)
  int get navigableGamesCount => maxGames;

  /// Último mapa acessível para clique/navegação (bloqueia jogos extras desnecessários após decisão matemática da série)
  int get maxUnlockedGameNumber {
    if (isSeriesDecided && games.isNotEmpty) {
      return games.length;
    }
    return maxGames;
  }

  /// Título formatado do modal de detalhes da série (ex: 'SÉRIE MD3 • R1')
  String get seriesDialogTitle => 'SÉRIE $mdBadgeLabel • R$round';

  /// Indica se determinado mapa foi o jogo decisivo da série
  bool isDecisiveGame(int gameNumber) =>
      isSeriesDecided && games.isNotEmpty && gameNumber == games.length;

  /// Resolve o nome atualizado de uma equipe a partir do Draft ou Torneio
  String resolveTeamDisplayName(
    String? targetTeamId,
    String fallback, {
    List<DraftTeamDto>? draftTeams,
    List<TournamentTeamDto>? tournamentTeams,
  }) {
    if (targetTeamId != null) {
      if (draftTeams != null) {
        for (final t in draftTeams) {
          if (t.id == targetTeamId && t.name.trim().isNotEmpty) return t.name;
        }
      }
      if (tournamentTeams != null) {
        for (final t in tournamentTeams) {
          if (t.id == targetTeamId && t.name.trim().isNotEmpty) return t.name;
        }
      }
    }
    return fallback;
  }
}
