import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import '../controllers/draft_controller.dart';
import '../models/draft_state_snapshot_dto.dart';

/// Modal de decisão exibido ao organizador quando todos os titulares foram escolhidos (Snake Draft concluído).
/// Permite ao administrador escolher entre avançar para a alocação de reservas ou concluir o draft imediatamente.
class DraftStartersCompletedDialog extends StatelessWidget {
  final DraftController controller;
  final DraftStateSnapshotDto snapshot;

  const DraftStartersCompletedDialog({
    super.key,
    required this.controller,
    required this.snapshot,
  });

  /// Método estático utilitário para exibir o modal
  static Future<void> show(
    BuildContext context, {
    required DraftController controller,
    required DraftStateSnapshotDto snapshot,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DraftStartersCompletedDialog(
        controller: controller,
        snapshot: snapshot,
      ),
    );
  }

  Future<void> _onAdvanceToSubstitutes(BuildContext context) async {
    final error = await controller.advanceToSubstitutes();
    if (!context.mounted) return;

    if (error != null) {
      AppFeedback.showError(context, message: error);
    } else {
      Navigator.of(context).pop();
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
        Navigator.of(context).pop();
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final totalTeams = snapshot.targetTeamCount > 0 ? snapshot.targetTeamCount : snapshot.teams.length;

    return AppDialog(
      maxWidth: 460,
      title: 'DRAFT DE TITULARES FINALIZADO',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Ícone e Destaque Visual Dourado Aegis
          Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dotaGold.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.dotaGold.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dotaGold.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 30,
                color: AppColors.dotaGoldLight,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Título Impactante
          Text(
            'TODOS OS TITULARES FORAM ESCOLHIDOS!',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: AppColors.dotaGoldLight,
            ),
          ),
          const SizedBox(height: 8),

          // 3. Descrição Clara da Situação
          Text(
            'Todas as $totalTeams equipes completaram sua escalação titular de 5 jogadores (1 capitão + 4 titulares selecionados no Snake Draft).',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // 4. Painel de Status das Equipes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvasSurface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  label: 'EQUIPES COMPLETAS',
                  value: '$totalTeams / $totalTeams',
                  color: AppColors.feedbackSuccess,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
                _buildMetric(
                  label: 'PICKS REALIZADOS',
                  value: '${snapshot.currentPickIndex} / ${snapshot.totalStarterPicks}',
                  color: AppColors.dotaGoldLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pergunta Diretiva
          Text(
            'Deseja alocar jogadores reservas ou concluir o draft imediatamente?',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // 5. Botões de Ação do Organizador
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botão 1: Alocar Reservas
              AppButton(
                text: 'ALOCAR RESERVAS',
                icon: Icons.group_add_rounded,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.medium,
                isLoading: controller.isActionInProgress,
                onPressed: () => _onAdvanceToSubstitutes(context),
              ),
              const SizedBox(height: 10),

              // Botão 2: Concluir Draft Imediatamente
              AppButton(
                text: 'CONCLUIR DRAFT AGORA',
                icon: Icons.check_circle_outline_rounded,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.medium,
                isLoading: controller.isActionInProgress,
                onPressed: () => _onCompleteDraft(context),
              ),
              const SizedBox(height: 8),

              // Botão 3: Fechar para Revisar Escalações na Tela
              AppButton(
                text: 'REVISAR ESCALAÇÕES NA TELA',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
