import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../models/tournament_wizard_state.dart';

/// Passo 4 do Wizard: Resumo Geral e Confirmação de Criação.
class WizardStepReview extends StatelessWidget {
  final TournamentWizardState state;

  const WizardStepReview({
    super.key,
    required this.state,
  });

  String _formatName(String type) {
    switch (type) {
      case 'DirectPlayoffs':
        return 'Mata-Mata Direto';
      case 'GroupStageAndPlayoffs':
        return 'Fase de Grupos + Playoffs';
      case 'GroupStageDirectFinal':
        return 'Fase de Grupos + Final Direta';
      default:
        return type;
    }
  }

  String _playoffName(String type) {
    switch (type) {
      case 'SingleElimination':
        return 'Eliminatória Simples';
      case 'DoubleElimination':
        return 'Eliminatória Dupla (Upper / Lower)';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGroups = state.formatType != 'DirectPlayoffs';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Card de Identidade do Campeonato
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryNeon.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (state.bannerBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryNeon, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.memory(
                      state.bannerBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/company_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.emoji_events_rounded,
                        size: 24,
                        color: AppColors.primaryNeon,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.name.isEmpty ? 'Campeonato sem nome' : state.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        AppBadge(
                          label: '${state.teamCount} Equipes Competitivas',
                          customColor: AppColors.dotaGold,
                          icon: Icons.groups_rounded,
                        ),
                        AppBadge(
                          label: state.enableDraftMode ? 'Draft Ativo' : 'Sem Draft',
                          customColor: state.enableDraftMode ? AppColors.success : AppColors.textSecondary,
                          icon: Icons.shuffle_rounded,
                        ),
                        if (state.bannerBytes != null || (state.bannerUrl != null && state.bannerUrl!.isNotEmpty))
                          const AppBadge(
                            label: 'Banner Anexado',
                            customColor: AppColors.primaryNeon,
                            icon: Icons.image_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Grid de Resumo dos Parâmetros Esportivos
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna Esquerda: Formato & Chaves
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.alt_route_rounded, size: 15, color: AppColors.primaryNeon),
                        SizedBox(width: 6),
                        Text(
                          'FORMATO & CHAVEAMENTO',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildItemRow('Modelo:', _formatName(state.formatType)),
                    const SizedBox(height: 6),
                    _buildItemRow('Playoffs:', _playoffName(state.playoffFormat)),
                    const SizedBox(height: 6),
                    _buildItemRow(
                      'Fase de Grupos:',
                      hasGroups
                          ? '${state.groupCount} ${state.groupCount == 1 ? 'Grupo Único' : 'Grupos de 4'}'
                          : 'Não se aplica (Mata-Mata Direto)',
                      isStrikethrough: !hasGroups,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Coluna Direita: Séries e Partidas
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sports_esports_rounded, size: 15, color: AppColors.dotaGold),
                        SizedBox(width: 6),
                        Text(
                          'SÉRIES DE CONFRONTO',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildItemRow(
                      'Série Grupos:',
                      hasGroups
                          ? 'Melhor de ${state.groupStageFormat.replaceAll('Bo', '')} (${state.groupStageFormat})'
                          : 'Não se aplica (Mata-Mata Direto)',
                      isStrikethrough: !hasGroups,
                    ),
                    const SizedBox(height: 6),
                    _buildItemRow('Playoffs:', 'Melhor de ${state.playoffSeriesFormat.replaceAll('Bo', '')} (${state.playoffSeriesFormat})'),
                    const SizedBox(height: 6),
                    _buildItemRow('Grande Final:', 'Melhor de ${state.grandFinalSeriesFormat.replaceAll('Bo', '')} (${state.grandFinalSeriesFormat})'),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 3. Aviso de Confirmação Final
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tudo validado com as regras do backend. Clique em "CRIAR CAMPEONATO" para registrar a competição e liberar inscrições e draft.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(String label, String value, {bool isStrikethrough = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textSecondary,
              color: isStrikethrough ? AppColors.textSecondary : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
