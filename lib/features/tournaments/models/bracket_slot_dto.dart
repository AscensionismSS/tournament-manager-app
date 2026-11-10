export 'tournament_team_dto.dart';

/// DTO de slot da chave de Playoffs (Tournaments.Contracts/Tournaments/BracketSlotDto).
/// Entregue pronto pelo backend mesmo antes de o campeonato ter equipes inscritas.
class BracketSlotDto {
  final String code;
  final String stage;
  final int round;
  final String teamASource;
  final String teamBSource;
  final String? winnerTargetSlotCode;
  final String? loserTargetSlotCode;
  final String seriesFormat;

  const BracketSlotDto({
    required this.code,
    required this.stage,
    required this.round,
    required this.teamASource,
    required this.teamBSource,
    this.winnerTargetSlotCode,
    this.loserTargetSlotCode,
    this.seriesFormat = 'Bo3',
  });

  factory BracketSlotDto.fromJson(Map<String, dynamic> json) {
    return BracketSlotDto(
      code: json['code']?.toString() ?? '',
      stage: json['stage']?.toString() ?? 'Upper',
      round: json['round'] as int? ?? 1,
      teamASource: json['teamASource']?.toString() ?? 'TBD',
      teamBSource: json['teamBSource']?.toString() ?? 'TBD',
      winnerTargetSlotCode: json['winnerTargetSlotCode']?.toString(),
      loserTargetSlotCode: json['loserTargetSlotCode']?.toString(),
      seriesFormat: json['seriesFormat']?.toString() ?? 'Bo3',
    );
  }

  /// Converte "Bo1", "Bo2", "Bo3", "Bo5" em "MD1", "MD2", "MD3", "MD5"
  String get seriesBadgeLabel => seriesFormat.toUpperCase().replaceAll('BO', 'MD');

  String get stageLabel {
    switch (stage) {
      case 'PlayIn':
        return 'Play-In';
      case 'Upper':
        return 'Chave Superior (Upper)';
      case 'Lower':
        return 'Chave Inferior (Lower)';
      case 'GrandFinal':
        return 'Grande Final';
      default:
        return stage;
    }
  }

  /// Nome amigável de exibição do confronto (ex: 'Upper R1', 'Final Superior', 'Grande Final')
  String get friendlyTitle {
    if (code == 'GF') return 'Grande Final';
    if (code == 'UF') return 'Final Superior';
    if (code == 'LF') return 'Final Inferior';
    if (code == 'PI') return 'Play-In • R1';
    if (code.startsWith('SF')) return 'Semifinal ${code.replaceAll('SF', '#')}';
    if (code.startsWith('QF')) return 'Quartas ${code.replaceAll('QF', '#')}';
    if (code.startsWith('U')) return 'Upper R1 • $code';
    if (code.startsWith('LR3')) return 'Lower R3 • $code';
    if (code.startsWith('LR2')) return 'Lower R2 • $code';
    if (code.startsWith('LR') || code.startsWith('L')) return 'Lower R1 • $code';
    return code;
  }

  bool get isPlayIn => stage == 'PlayIn' || code == 'PI';

  bool get isFinalOfBracket => code == 'UF' || code == 'LF' || code == 'GF';

  /// Rótulo compacto de identificação da rodada/chave para o topo do card (ex: 'R1 UPPER • U1', 'FINAL UPPER • UF', 'PLAY-IN • PI')
  String get cardBadgeLabel {
    if (code == 'GF' || stage == 'GrandFinal') return 'GRANDE FINAL • GF';
    if (isPlayIn) return 'PLAY-IN • $code';
    if (code == 'UF') return 'FINAL UPPER • UF';
    if (code == 'LF') return 'FINAL LOWER • LF';
    if (code.startsWith('SF')) return 'SEMIFINAL • $code';
    if (code.startsWith('QF')) return 'QUARTAS • $code';
    if (stage == 'Upper') return 'R1 UPPER • $code';
    if (code.startsWith('LR3')) return 'R3 LOWER • $code';
    if (code.startsWith('LR2')) return 'R2 LOWER • $code';
    if (stage == 'Lower') return 'R1 LOWER • $code';
    return 'R$round • $code';
  }

  /// Chave de agrupamento interno para separar as subfases dentro da Upper e da Lower Bracket
  String get subStageGroupKey {
    if (isPlayIn) return '0_playin';
    if (stage == 'Upper') {
      if (code == 'UF') return '3_uf';
      if (code.startsWith('SF')) return '2_sf';
      if (code.startsWith('QF')) return '1_qf';
      return '1_u_r1';
    }
    if (stage == 'Lower') {
      if (code == 'LF') return '4_lf';
      if (code.startsWith('LR3')) return '3_lr3';
      if (code.startsWith('LR2')) return '2_lr2';
      return '1_l_r1';
    }
    return '5_gf';
  }

  /// Pílula curta da subfase (ex: 'R1', 'FINAL UPPER', 'PLAY-IN', 'R2 LOWER')
  String get subStagePill {
    if (isPlayIn) return 'PLAY-IN';
    if (stage == 'Upper') {
      if (code == 'UF') return 'FINAL UPPER';
      if (code.startsWith('SF')) return 'SEMIFINAIS';
      if (code.startsWith('QF')) return 'R1 • QUARTAS';
      return 'R1 UPPER';
    }
    if (stage == 'Lower') {
      if (code == 'LF') return 'FINAL LOWER';
      if (code.startsWith('LR3')) return 'R3 LOWER';
      if (code.startsWith('LR2')) return 'R2 LOWER';
      return 'R1 LOWER';
    }
    return 'GRANDE FINAL';
  }

  /// Título descritivo da subfase para separar levemente as etapas dentro da mesma chave
  String get subStageTitle {
    if (isPlayIn) return 'REPESCAGEM PRELIMINAR (CHAVE DE ACESSO)';
    if (stage == 'Upper') {
      if (code == 'UF') return 'FINAL DA CHAVE SUPERIOR (VALE VAGA NA GRANDE FINAL)';
      if (code.startsWith('SF')) return 'SEMIFINAIS DO MATA-MATA';
      if (code.startsWith('QF')) return 'QUARTAS DE FINAL';
      return 'RODADA 1 • SEMIFINAIS DA CHAVE SUPERIOR';
    }
    if (stage == 'Lower') {
      if (code == 'LF') return 'FINAL DA CHAVE INFERIOR (VALE VAGA NA GRANDE FINAL)';
      if (code.startsWith('LR3')) return 'RODADA 3 DA CHAVE INFERIOR';
      if (code.startsWith('LR2')) return 'RODADA 2 DA CHAVE INFERIOR';
      return 'RODADA 1 DA CHAVE INFERIOR';
    }
    return 'DECISÃO DO TÍTULO';
  }

  /// Converte fontes do backend ('1st', 'Winner(U1)', 'Loser(U1)') em texto amigável e limpo
  static String formatSeedSource(String raw) {
    final clean = raw.trim();
    if (clean.toLowerCase() == '1st') return '1º do Grupo';
    if (clean.toLowerCase() == '2nd') return '2º do Grupo';
    if (clean.toLowerCase() == '3rd') return '3º do Grupo';
    if (clean.toLowerCase() == '4th') return '4º do Grupo';
    if (clean.toLowerCase() == '5th') return '5º do Grupo';
    if (clean.toLowerCase() == '6th') return '6º do Grupo';
    if (clean.toLowerCase() == '7th') return '7º do Grupo';
    if (clean.toLowerCase() == '8th') return '8º do Grupo';

    if (clean.toLowerCase().startsWith('winner(') && clean.endsWith(')')) {
      final inner = clean.substring(7, clean.length - 1);
      return 'Venc. $inner';
    }
    if (clean.toLowerCase().startsWith('loser(') && clean.endsWith(')')) {
      final inner = clean.substring(6, clean.length - 1);
      return 'Perd. $inner';
    }
    return clean;
  }
}
