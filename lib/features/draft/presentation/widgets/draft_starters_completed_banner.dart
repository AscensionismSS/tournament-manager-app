import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/draft_controller.dart';
import '../../models/draft_state_snapshot_dto.dart';

/// Banner de topo persistente para quando os titulares estão completos (Snake Draft finalizado).
/// Fica visível na tela enquanto o admin revisa os elencos, permitindo acionar a transição a qualquer momento.
class DraftStartersCompletedBanner extends StatelessWidget {
  final DraftController controller;
  final DraftStateSnapshotDto snapshot;

  const DraftStartersCompletedBanner({
    super.key,
    required this.controller,
    required this.snapshot,
  });

  Future<void> _onAdvanceToSubstitutes(BuildContext context) async {
    final error = await controller.advanceToSubstitutes();
    if (!context.mounted) return;

    if (error != null) {
      AppFeedback.showError(context, message: error);
    } else {
      AppFeedback.showSuccess(
        context,
        message: 'Fase de reservas iniciada! Distribuição livre liberada.',
      );
    }
  }

  Future<void> _onCompleteDraft(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'CONCLUIR DRAFT E GERAR PARTIDAS?',
      message:
          'Isso consolidará todas as equipes no campeonato, gerará a tabela e chaves de partidas e encerrará o draft. Esta ação é irreversível.',
      confirmLabel: 'SIM, CONCLUIR E GERAR',
      cancelLabel: 'VOLTAR',
      isDestructive: false,
    );

    if (confirmed == true && context.mounted) {
      final tournamentId = controller.snapshot?.tournamentId;
      final error = await controller.completeDraft(startTournament: true);
      if (!context.mounted) return;

      if (error != null) {
        AppFeedback.showError(context, message: error);
      } else {
        AppFeedback.showSuccess(
          context,
          message:
              'Draft concluído e campeonato iniciado! Chaves e partidas geradas.',
        );
        if (tournamentId != null && tournamentId.isNotEmpty) {
          context.go('/tournaments/$tournamentId/teams');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!snapshot.canDecidePostStarters) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dotaGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.dotaGold.withValues(alpha: 0.38),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dotaGold.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ícone decorativo dourado
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.dotaGold.withValues(alpha: 0.15),
            border: Border.all(
              color: AppColors.dotaGold.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 20,
            color: AppColors.dotaGoldLight,
          ),
        ),
        const SizedBox(width: 12),

        // Textos informativos com Wrap anti-overflow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'TITULARES COMPLETOS',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: AppColors.dotaGoldLight,
                    ),
                  ),
                  AppBadge(
                    label: 'SNAKE DRAFT FINALIZADO',
                    customColor: AppColors.dotaGoldLight,
                    height: 18,
                    fontSize: 9.0,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Todas as equipes possuem 5 titulares. Escolha entre alocar reservas ou consolidar o draft no campeonato.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Botões de Ação
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              text: 'ALOCAR RESERVAS',
              icon: Icons.group_add_rounded,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.medium,
              isLoading: controller.isActionInProgress,
              onPressed: () => _onAdvanceToSubstitutes(context),
            ),
            AppButton(
              text: 'CONCLUIR DRAFT',
              icon: Icons.check_circle_outline_rounded,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              isLoading: controller.isActionInProgress,
              onPressed: () => _onCompleteDraft(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 18,
              color: AppColors.dotaGoldLight,
            ),
            Text(
              'TITULARES COMPLETOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: AppColors.dotaGoldLight,
              ),
            ),
            AppBadge(
              label: 'SNAKE DRAFT FINALIZADO',
              customColor: AppColors.dotaGoldLight,
              height: 18,
              fontSize: 9.0,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Todas as equipes possuem 5 titulares. Escolha abaixo a próxima etapa:',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textPrimary.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'ALOCAR RESERVAS',
          icon: Icons.group_add_rounded,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.medium,
          isLoading: controller.isActionInProgress,
          onPressed: () => _onAdvanceToSubstitutes(context),
        ),
        const SizedBox(height: 8),
        AppButton(
          text: 'CONCLUIR DRAFT',
          icon: Icons.check_circle_outline_rounded,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.medium,
          isLoading: controller.isActionInProgress,
          onPressed: () => _onCompleteDraft(context),
        ),
      ],
    );
  }
}
