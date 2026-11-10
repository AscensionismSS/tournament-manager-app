import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import 'bracket_slot_dto.dart';

/// DTO de linha de classificação da Fase de Grupos (Tournaments.Contracts/Tournaments/TeamStandingDto).
/// 100% Dumb UI: reflete os cálculos prontos do backend sem fórmulas esportivas no cliente.
class TeamStandingDto {
  final int rank;
  final String teamId;
  final String teamName;
  final String? groupCode;
  final int points;
  final int playedMatches;
  final int wonMatches;
  final int drawnMatches;
  final int lostMatches;
  final int mapWins;
  final int mapLosses;
  final int mapDifferential;
  final int totalVictoryDurationSeconds;
  final int totalKills;
  final int totalDeaths;
  final int killDifferential;
  final bool isPlaceholder;

  const TeamStandingDto({
    required this.rank,
    required this.teamId,
    required this.teamName,
    this.groupCode,
    this.points = 0,
    this.playedMatches = 0,
    this.wonMatches = 0,
    this.drawnMatches = 0,
    this.lostMatches = 0,
    this.mapWins = 0,
    this.mapLosses = 0,
    this.mapDifferential = 0,
    this.totalVictoryDurationSeconds = 0,
    this.totalKills = 0,
    this.totalDeaths = 0,
    this.killDifferential = 0,
    this.isPlaceholder = false,
  });

  factory TeamStandingDto.fromJson(Map<String, dynamic> json) {
    return TeamStandingDto(
      rank: json['rank'] as int? ?? 1,
      teamId: json['teamId']?.toString() ?? '',
      teamName: json['teamName']?.toString() ?? 'Equipe',
      groupCode: json['groupCode']?.toString() ??
          json['group']?.toString() ??
          json['GroupCode']?.toString(),
      points: json['points'] as int? ?? 0,
      playedMatches: json['playedMatches'] as int? ?? 0,
      wonMatches: json['wonMatches'] as int? ?? 0,
      drawnMatches: json['drawnMatches'] as int? ?? 0,
      lostMatches: json['lostMatches'] as int? ?? 0,
      mapWins: json['mapWins'] as int? ?? 0,
      mapLosses: json['mapLosses'] as int? ?? 0,
      mapDifferential: json['mapDifferential'] as int? ?? 0,
      totalVictoryDurationSeconds:
          json['totalVictoryDurationSeconds'] as int? ?? 0,
      totalKills: json['totalKills'] as int? ?? 0,
      totalDeaths: json['totalDeaths'] as int? ?? 0,
      killDifferential: json['killDifferential'] as int? ?? 0,
    );
  }

  /// Cria uma linha de placeholder quando o campeonato ainda não tem equipes ou partidas iniciadas
  factory TeamStandingDto.placeholder({
    required int rank,
    String? teamName,
    String? groupCode,
  }) {
    return TeamStandingDto(
      rank: rank,
      teamId: '',
      teamName: teamName ?? 'Vaga #$rank — Aguardando Equipe',
      groupCode: groupCode,
      isPlaceholder: teamName == null,
    );
  }

  String get recordSummary => '$wonMatches-$drawnMatches-$lostMatches';

  String get mapsSummary => '$mapWins-$mapLosses';

  String get mapDiffLabel =>
      mapDifferential > 0 ? '+$mapDifferential' : '$mapDifferential';

  String get kdSummary => '$totalKills/$totalDeaths';
}

/// Destino visual de uma posição da tabela de grupos projetado a partir dos [BracketSlotDto] do backend.
class GroupSeedDestination {
  final String label;
  final String detailHint;
  final String codeTag; // Ex: 'UB', 'LB', 'PI', 'GF'
  final String? subLabel;
  final String slotCode;
  final String stage;
  final Color color;
  final IconData icon;

  const GroupSeedDestination({
    required this.label,
    required this.detailHint,
    required this.codeTag,
    this.subLabel,
    required this.slotCode,
    required this.stage,
    required this.color,
    required this.icon,
  });

  /// Resolve para qual chave (Upper, Lower, Play-In, Grande Final) a posição [rankInGroup] avança,
  /// lendo diretamente os [bracketSlots] enviados pelo backend (incluindo `winnerTargetSlotCode`).
  static GroupSeedDestination resolveFromSlots({
    required int rankInGroup,
    required int groupCount,
    required List<BracketSlotDto> bracketSlots,
  }) {
    final int effectiveSeed = groupCount == 2
        ? (rankInGroup <= 2 ? rankInGroup : rankInGroup + 2)
        : rankInGroup;

    final String ordinal = _toOrdinal(effectiveSeed);

    final matchingSlot = bracketSlots.cast<BracketSlotDto?>().firstWhere(
          (s) =>
              s != null &&
              (s.teamASource.toLowerCase() == ordinal.toLowerCase() ||
                  s.teamBSource.toLowerCase() == ordinal.toLowerCase()),
          orElse: () => null,
        );

    if (matchingSlot == null) {
      return const GroupSeedDestination(
        label: 'ELIMINADO',
        detailHint: 'Fora da zona de classificação para os Playoffs',
        codeTag: 'OUT',
        slotCode: '-',
        stage: 'Eliminated',
        color: AppColors.textSecondary,
        icon: Icons.remove_circle_outline_rounded,
      );
    }

    switch (matchingSlot.stage) {
      case 'GrandFinal':
        return GroupSeedDestination(
          label: 'GRANDE FINAL (${matchingSlot.code})',
          detailHint: 'Avança direto para a decisão do título (${matchingSlot.code})',
          codeTag: 'GF',
          slotCode: matchingSlot.code,
          stage: matchingSlot.stage,
          color: AppColors.dotaGold,
          icon: Icons.emoji_events_rounded,
        );
      case 'Upper':
        final bool isSingleElimination =
            matchingSlot.loserTargetSlotCode == null &&
                !bracketSlots.any((s) => s.stage == 'Lower');
        if (isSingleElimination) {
          final stageName = matchingSlot.code.startsWith('QF')
              ? 'QUARTAS DE FINAL'
              : (matchingSlot.code.startsWith('SF') ? 'SEMIFINAL' : 'PLAYOFFS');
          return GroupSeedDestination(
            label: '$stageName (${matchingSlot.code})',
            detailHint:
                'Classificado para o Mata-Mata Simples (${matchingSlot.code}) • Sem Lower Bracket',
            codeTag: matchingSlot.code,
            slotCode: matchingSlot.code,
            stage: 'SingleElimination',
            color: AppColors.feedbackSuccess,
            icon: Icons.bolt_rounded,
          );
        }
        return GroupSeedDestination(
          label: 'UPPER BRACKET (${matchingSlot.code})',
          detailHint:
              'Classificado direto para a Chave Superior (${matchingSlot.code}) • Possui vida dupla',
          codeTag: 'UB',
          slotCode: matchingSlot.code,
          stage: matchingSlot.stage,
          color: AppColors.feedbackSuccess, // VERDE para Upper Bracket
          icon: Icons.keyboard_double_arrow_up_rounded,
        );
      case 'PlayIn':
        final targetCode = matchingSlot.winnerTargetSlotCode ?? 'L2';
        final seedALabel = _ordinalToPtBr(matchingSlot.teamASource);
        final seedBLabel = _ordinalToPtBr(matchingSlot.teamBSource);
        return GroupSeedDestination(
          label: 'PLAY-IN (${matchingSlot.code}) ➔ LOWER ($targetCode)',
          subLabel: 'Vencedor vai para a Lower ($targetCode) • Perdedor Eliminado',
          detailHint:
              'Repescagem ($seedALabel vs $seedBLabel): Vencedor avança para a Lower Bracket ($targetCode) • Perdedor é eliminado',
          codeTag: 'PI',
          slotCode: matchingSlot.code,
          stage: matchingSlot.stage,
          color: AppColors.feedbackWarning, // LARANJA/ÂMBAR para Disputa de Play-In
          icon: Icons.swap_horiz_rounded,
        );
      case 'Lower':
      default:
        return GroupSeedDestination(
          label: 'LOWER BRACKET (${matchingSlot.code})',
          detailHint:
              'Vaga direta na Chave Inferior (${matchingSlot.code}) • Sem margem de derrota',
          codeTag: 'LB',
          slotCode: matchingSlot.code,
          stage: matchingSlot.stage,
          color: AppColors.primaryNeon, // VERMELHO para Lower Bracket
          icon: Icons.keyboard_arrow_right_rounded,
        );
    }
  }

  static String _toOrdinal(int number) {
    switch (number) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${number}th';
    }
  }

  static String _ordinalToPtBr(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isNotEmpty ? '$digitsº' : raw;
  }
}
