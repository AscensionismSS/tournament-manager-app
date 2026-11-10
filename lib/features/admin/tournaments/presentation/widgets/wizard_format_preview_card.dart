import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../models/tournament_wizard_state.dart';

/// Diagrama Visual Interativo exibido na Etapa 2 do Wizard (`WizardStepFormat`).
/// Ilustra em tempo real o modelo da competição conforme o usuário alterna entre
/// `Grupos + Playoffs (1 ou 2 Grupos)` e `Mata-Mata Direto`, explicando o fluxo das vagas.
class WizardFormatPreviewCard extends StatelessWidget {
  final TournamentWizardState state;

  const WizardFormatPreviewCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDirect = state.formatType == 'DirectPlayoffs';
    final isTwoGroups = !isDirect && state.groupCount == 2;
    final teams = state.teamCount;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey('${state.formatType}_${state.groupCount}_$teams'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.7),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Cabeçalho do Esquema Visual
            Row(
              children: [
                Icon(
                  isDirect
                      ? Icons.bolt_rounded
                      : Icons.schema_rounded,
                  size: 15,
                  color: AppColors.dotaGold,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _resolveHeaderTitle(isDirect: isDirect, isTwoGroups: isTwoGroups),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: AppColors.dotaGoldLight,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: AppColors.primaryNeon.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '$teams EQUIPES',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNeon,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Diagrama Esquemático Visual (Fluxo das Fases)
            if (isDirect)
              _buildDirectPlayoffsDiagram(teams)
            else if (isTwoGroups)
              _buildTwoGroupsDiagram()
            else
              _buildSingleGroupDiagram(teams),

            const SizedBox(height: 10),

            // 3. Explicação resumida das vagas para a escolha atual
            Text(
              _resolveExplanation(
                isDirect: isDirect,
                isTwoGroups: isTwoGroups,
                teams: teams,
              ),
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveHeaderTitle({
    required bool isDirect,
    required bool isTwoGroups,
  }) {
    if (isDirect) {
      return 'MODELO VISUAL: MATA-MATA DIRETO (CHAVE ÚNICA)';
    }
    if (isTwoGroups) {
      return 'MODELO VISUAL: 2 GRUPOS (A & B) ➔ UPPER & LOWER BRACKET';
    }
    return 'MODELO VISUAL: GRUPO ÚNICO ➔ UPPER & LOWER BRACKET';
  }

  String _resolveExplanation({
    required bool isDirect,
    required bool isTwoGroups,
    required int teams,
  }) {
    if (isDirect) {
      return teams == 4
          ? 'As 4 equipes entram direto nas Semifinais (SF1 e SF2). Quem vencer avança para a Grande Final; quem perder está eliminado.'
          : 'As 8 equipes entram direto nas Quartas de Final (QF1 a QF4). Eliminatória simples sem Lower Bracket (perdeu, saiu).';
    }
    if (isTwoGroups) {
      return 'Grupo A (4 times) e Grupo B (4 times): 1º e 2º de cada grupo avançam à Upper Bracket (vida dupla), enquanto 3º e 4º vão para a Lower Bracket.';
    }
    switch (teams) {
      case 4:
        return 'Todos jogam contra todos no grupo: 1º e 2º avançam para a Upper Bracket (U1), e 3º e 4º disputam a Lower Bracket (L1).';
      case 5:
        return '1º e 2º vão à Upper (U1) • 3º espera na Lower (L1) • 4º vs 5º disputam o Play-In (PI) valendo a última vaga na Lower.';
      case 6:
        return '1º ao 4º avançam à Upper Bracket (U1 e U2 com vida dupla) • 5º e 6º entram direto na Lower Bracket (L1 e L2).';
      case 7:
        return '1º ao 4º vão à Upper (U1/U2) • 5º vai direto à Lower (L1) • 6º vs 7º jogam o Play-In (PI) pela última vaga na Lower (L2).';
      case 8:
      default:
        return '1º ao 4º avançam para a Upper Bracket (U1 e U2 com vida dupla), enquanto 5º ao 8º disputam a sobrevivência na Lower Bracket (L1 e L2).';
    }
  }

  Widget _buildSingleGroupDiagram(int teams) {
    final hasPlayIn = teams == 5 || teams == 7;
    final upperLabel = teams <= 5 ? '1º e 2º ➔ UPPER' : '1º ao 4º ➔ UPPER';
    final lowerLabel = teams == 4
        ? '3º e 4º ➔ LOWER'
        : (teams == 5
            ? '3º ➔ LOWER  |  4ºx5º ➔ PLAY-IN'
            : (teams == 6
                ? '5º e 6º ➔ LOWER'
                : (teams == 7
                    ? '5º ➔ LOWER  |  6ºx7º ➔ PLAY-IN'
                    : '5º ao 8º ➔ LOWER')));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildDiagramBox(
            icon: Icons.table_chart_rounded,
            title: 'GRUPO ÚNICO',
            subtitle: 'Todos x Todos ($teams times)',
            color: AppColors.dotaGoldLight,
          ),
        ),
        _buildArrow(),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildMiniBranch(
                label: upperLabel,
                color: AppColors.dotaGold,
                icon: Icons.keyboard_double_arrow_up_rounded,
              ),
              const SizedBox(height: 6),
              _buildMiniBranch(
                label: lowerLabel,
                color: hasPlayIn ? AppColors.feedbackWarning : AppColors.primaryNeon,
                icon: hasPlayIn
                    ? Icons.swap_horiz_rounded
                    : Icons.keyboard_arrow_right_rounded,
              ),
            ],
          ),
        ),
        _buildArrow(),
        Expanded(
          flex: 3,
          child: _buildDiagramBox(
            icon: Icons.emoji_events_rounded,
            title: 'GRANDE FINAL',
            subtitle: 'Campeão Upper vs Lower',
            color: AppColors.dotaGold,
          ),
        ),
      ],
    );
  }

  Widget _buildTwoGroupsDiagram() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildMiniBranch(
                label: 'GRUPO A (4 times)',
                color: AppColors.dotaGoldLight,
                icon: Icons.grid_view_rounded,
              ),
              const SizedBox(height: 6),
              _buildMiniBranch(
                label: 'GRUPO B (4 times)',
                color: AppColors.dotaGoldLight,
                icon: Icons.grid_view_rounded,
              ),
            ],
          ),
        ),
        _buildArrow(),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildMiniBranch(
                label: 'Top 1–2 (A/B) ➔ UPPER',
                color: AppColors.dotaGold,
                icon: Icons.keyboard_double_arrow_up_rounded,
              ),
              const SizedBox(height: 6),
              _buildMiniBranch(
                label: 'Top 3–4 (A/B) ➔ LOWER',
                color: AppColors.primaryNeon,
                icon: Icons.keyboard_arrow_right_rounded,
              ),
            ],
          ),
        ),
        _buildArrow(),
        Expanded(
          flex: 3,
          child: _buildDiagramBox(
            icon: Icons.emoji_events_rounded,
            title: 'GRANDE FINAL',
            subtitle: 'Upper vs Lower',
            color: AppColors.dotaGold,
          ),
        ),
      ],
    );
  }

  Widget _buildDirectPlayoffsDiagram(int teams) {
    return Row(
      children: [
        if (teams == 8) ...[
          Expanded(
            child: _buildDiagramBox(
              icon: Icons.account_tree_rounded,
              title: 'QUARTAS (QF)',
              subtitle: '4 confrontos diretos',
              color: AppColors.primaryNeon,
            ),
          ),
          _buildArrow(),
        ],
        Expanded(
          child: _buildDiagramBox(
            icon: Icons.bolt_rounded,
            title: 'SEMIFINAIS (SF)',
            subtitle: 'Eliminatória Simples',
            color: AppColors.primaryNeon,
          ),
        ),
        _buildArrow(),
        Expanded(
          child: _buildDiagramBox(
            icon: Icons.emoji_events_rounded,
            title: 'GRANDE FINAL',
            subtitle: 'Decisão do Título',
            color: AppColors.dotaGold,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagramBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBranch({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: AppColors.dotaGold,
      ),
    );
  }
}
