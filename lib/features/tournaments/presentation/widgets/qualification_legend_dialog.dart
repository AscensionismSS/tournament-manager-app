import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/bracket_slot_dto.dart';
import '../../models/tournament_dto.dart';

/// Barra de Legenda de Classificação Pós-Grupos com cores padronizadas:
/// - Verde: Chave Superior (Upper Bracket - vida dupla)
/// - Vermelho: Chave Inferior (Lower Bracket - sem margem de erro)
/// - Laranja: Disputa de Play-In (Repescagem valendo vaga na Lower; perdedor é eliminado)
class QualificationLegendBar extends StatelessWidget {
  final TournamentDto tournament;

  const QualificationLegendBar({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final hasLowerBracket =
        tournament.bracketSlots.any((s) => s.stage == 'Lower');
    final isDirectFinal = tournament.formatType == 'GroupStageDirectFinal';
    final playInSlot = tournament.bracketSlots
        .cast<BracketSlotDto?>()
        .firstWhere((s) => s?.stage == 'PlayIn', orElse: () => null);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 15,
                      color: AppColors.dotaGold,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ZONAS DE CLASSIFICAÇÃO:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (isDirectFinal) ...[
                  _buildLegendDot(
                    color: AppColors.feedbackSuccess,
                    label: '1º e 2º: Grande Final Direta',
                  ),
                  _buildLegendDot(
                    color: AppColors.textSecondary,
                    label: 'Demais: Eliminados',
                  ),
                ] else if (hasLowerBracket) ...[
                  // Upper Bracket: VERDE
                  _buildLegendDot(
                    color: AppColors.feedbackSuccess,
                    label: 'Chave Superior (Upper Bracket)',
                  ),
                  // Lower Bracket: VERMELHO
                  _buildLegendDot(
                    color: AppColors.primaryNeon,
                    label: 'Chave Inferior Direta (Lower Bracket)',
                  ),
                ] else ...[
                  _buildLegendDot(
                    color: AppColors.feedbackSuccess,
                    label:
                        'Eliminatória Simples (Mata-Mata Direto sem Lower Bracket)',
                  ),
                ],
                // Disputa de Play-In: LARANJA/ÂMBAR (Aparece apenas quando o modelo do backend possui Play-In)
                if (playInSlot != null)
                  _buildLegendDot(
                    color: AppColors.feedbackWarning,
                    label: _buildPlayInSummary(playInSlot),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Botão "ⓘ" para abrir a explicação detalhada das vagas e do Play-In
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => QualificationLegendDialog.show(context, tournament),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dotaGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.dotaGold.withValues(alpha: 0.45),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.dotaGoldLight,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'COMO FUNCIONA?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.dotaGoldLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildPlayInSummary(BracketSlotDto playIn) {
    final a = playIn.teamASource.replaceAll(RegExp(r'[^0-9]'), '');
    final b = playIn.teamBSource.replaceAll(RegExp(r'[^0-9]'), '');
    final target = playIn.winnerTargetSlotCode ?? 'Lower';
    if (a.isNotEmpty && b.isNotEmpty) {
      return 'Play-In ($aº vs $bº ➔ Vencedor vai para Lower $target • Perdedor é Eliminado)';
    }
    return 'Disputa de Play-In (Repescagem: vencedor avança, perdedor eliminado)';
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Modal explicativo detalhando o destino de cada posição e a regra do Play-In (`ⓘ`).
class QualificationLegendDialog extends StatelessWidget {
  final TournamentDto tournament;

  const QualificationLegendDialog({
    super.key,
    required this.tournament,
  });

  static Future<void> show(BuildContext context, TournamentDto tournament) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'REGRAS DE CLASSIFICAÇÃO & PLAYOFFS',
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.dotaGold,
        maxWidth: 480,
        onClose: () => Navigator.of(dialogContext).pop(),
        content: QualificationLegendDialog(tournament: tournament),
        actions: [
          AppButton(
            text: 'ENTENDI',
            size: AppButtonSize.medium,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLower = tournament.bracketSlots.any((s) => s.stage == 'Lower');
    final playInSlot = tournament.bracketSlots
        .cast<BracketSlotDto?>()
        .firstWhere((s) => s?.stage == 'PlayIn', orElse: () => null);

    final aSeed =
        playInSlot?.teamASource.replaceAll(RegExp(r'[^0-9]'), '') ?? '6';
    final bSeed =
        playInSlot?.teamBSource.replaceAll(RegExp(r'[^0-9]'), '') ?? '7';
    final targetCode = playInSlot?.winnerTargetSlotCode ?? 'L2';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLower) ...[
          _buildRuleCard(
            icon: Icons.keyboard_double_arrow_up_rounded,
            color: AppColors.feedbackSuccess,
            title: 'CHAVE SUPERIOR (UPPER BRACKET) — VERDE',
            description:
                'Os primeiros colocados da Fase de Grupos garantem vaga direta na Chave Superior. '
                'Possuem vantagem de "vida dupla": caso percam uma série na Upper, não são eliminados — caem para a Lower Bracket e continuam disputando o campeonato.',
          ),
          const SizedBox(height: 12),
          _buildRuleCard(
            icon: Icons.keyboard_arrow_right_rounded,
            color: AppColors.primaryNeon,
            title: 'CHAVE INFERIOR DIRETA (LOWER BRACKET) — VERMELHO',
            description:
                'Classificação direta para a Chave Inferior sem passar por repescagem. '
                'Na Lower Bracket não existe segunda chance: qualquer derrota resulta em eliminação imediata do torneio.',
          ),
        ] else ...[
          _buildRuleCard(
            icon: Icons.bolt_rounded,
            color: AppColors.feedbackSuccess,
            title: 'MATA-MATA SIMPLES (ELIMINATÓRIA DIRETA)',
            description:
                'A Fase de Grupos define o pareamento das chaves (ex: 1º vs 8º, 2º vs 7º). '
                'Nos Playoffs todas as séries são eliminatórias diretas (sem Lower Bracket).',
          ),
        ],
        if (playInSlot != null) ...[
          const SizedBox(height: 12),
          _buildRuleCard(
            icon: Icons.swap_horiz_rounded,
            color: AppColors.feedbackWarning,
            title: 'DISPUTA DE PLAY-IN ($aSeedº VS $bSeedº) — LARANJA',
            description:
                'Partida de repescagem dinâmica presente nos formatos com número ímpar de times (como 7 ou 5 equipes):\n'
                '• $aSeedº e $bSeedº colocados disputam a última vaga remanescente nos Playoffs.\n'
                '• VENCEDOR: Avança para a Chave Inferior no confronto $targetCode.\n'
                '• PERDEDOR: É eliminado imediatamente do torneio.\n'
                '(Nota: Em modelos como 4, 6 ou 8 equipes, a classificação para a Lower é 100% direta, sem a fase de Play-In).',
          ),
        ],
        if (tournament.teams.length.isOdd || tournament.teamCount.isOdd) ...[
          const SizedBox(height: 12),
          _buildRuleCard(
            icon: Icons.pause_circle_outline_rounded,
            color: AppColors.dotaGold,
            title: 'FOLGA NA RODADA (BYE) — DOURADO / ÂMBAR',
            description:
                'Devido ao número ímpar de participantes (${tournament.teamCount} equipes), '
                'cada rodada da Fase de Grupos programa uma folga automática (BYE) para 1 equipe, '
                'seguindo rigorosamente a tabela oficial do sistema Berger. '
                'Ao fim da fase, todos os times terão disputado o mesmo número de partidas.',
          ),
        ],
      ],
    );
  }

  Widget _buildRuleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
