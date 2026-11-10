import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../models/tournament_options_dto.dart';
import '../../models/tournament_wizard_state.dart';
import 'wizard_format_preview_card.dart';

/// Passo 2 do Wizard: Formato da Competição, Grupos e Playoffs.
class WizardStepFormat extends StatelessWidget {
  final TournamentWizardState state;
  final TournamentConfigurationOptionsDto? options;
  final VoidCallback onChanged;

  const WizardStepFormat({
    super.key,
    required this.state,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDirectPlayoffs = state.formatType == 'DirectPlayoffs';

    // UI Passiva: Formatos e combinações informadas estritamente pelo backend
    final directFormat = options?.availableFormats
        .where((f) => f.type == 'DirectPlayoffs')
        .firstOrNull;
    final isDirectAllowed = options != null
        ? directFormat != null
        : (state.teamCount == 4 || state.teamCount == 8);

    final currentFormatOpt = options?.availableFormats
        .where((f) => f.type == state.formatType)
        .firstOrNull;

    final isTwoGroupsAllowed = options != null
        ? (currentFormatOpt?.allowedGroupCounts.contains(2) ?? false)
        : (state.teamCount == 8 && !isDirectPlayoffs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Tipo de Torneio (Formato Principal)
        const Text(
          'FORMATO DA COMPETIÇÃO',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            // Opção 1: Grupos + Playoffs (Sempre Double Elimination: Upper & Lower)
            Expanded(
              child: _buildFormatCard(
                title: 'Grupos + Playoffs',
                subtitle: 'Fase classificatória seguida de Upper & Lower Bracket.',
                icon: Icons.grid_view_rounded,
                isSelected: !isDirectPlayoffs,
                onTap: () {
                  state.formatType = 'GroupStageAndPlayoffs';
                  state.playoffFormat = 'DoubleElimination';
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 10),

            // Opção 2: Mata-Mata Direto (Sempre Single Elimination)
            Expanded(
              child: _buildFormatCard(
                title: 'Mata-Mata Direto',
                subtitle: 'Eliminatória simples pura sem fase de grupos.',
                icon: Icons.account_tree_rounded,
                isSelected: isDirectPlayoffs,
                isEnabled: isDirectAllowed,
                onTap: isDirectAllowed
                    ? () {
                        state.formatType = 'DirectPlayoffs';
                        state.playoffFormat = 'SingleElimination';
                        state.groupCount = 1;
                        if (state.playoffSeriesFormat == 'Bo5') {
                          state.playoffSeriesFormat = 'Bo3';
                        }
                        onChanged();
                      }
                    : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 2. Quantidade de Grupos (Sempre padronizado)
        const Text(
          'QUANTIDADE DE GRUPOS',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _buildFormatCard(
                title: '1 Grupo Único',
                subtitle: 'Todos os times competem em grupo único.',
                icon: Icons.table_chart_rounded,
                isSelected: !isDirectPlayoffs && state.groupCount == 1,
                isEnabled: !isDirectPlayoffs,
                onTap: !isDirectPlayoffs
                    ? () {
                        state.groupCount = 1;
                        onChanged();
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFormatCard(
                title: '2 Grupos (4 times cada)',
                subtitle: 'Grupo A e Grupo B equilibrados (4 times cada).',
                icon: Icons.dashboard_customize_rounded,
                isSelected: isTwoGroupsAllowed && state.groupCount == 2,
                isEnabled: isTwoGroupsAllowed,
                onTap: isTwoGroupsAllowed
                    ? () {
                        state.groupCount = 2;
                        onChanged();
                      }
                    : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. Diagrama Visual Interativo do Modelo Selecionado
        WizardFormatPreviewCard(state: state),
      ],
    );
  }

  Widget _buildFormatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isEnabled = true,
    VoidCallback? onTap,
  }) {
    final opacity = isEnabled ? 1.0 : 0.35;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 102,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryNeon.withValues(alpha: 0.12)
                : AppColors.surfaceHighlight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryNeon
                  : AppColors.border.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: isSelected ? AppColors.primaryNeon : AppColors.textSecondary,
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.primaryNeon,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
