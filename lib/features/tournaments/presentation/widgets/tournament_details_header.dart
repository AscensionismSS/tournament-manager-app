import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/tournament_dto.dart';
import '../../controllers/tournament_details_controller.dart';
import 'header/tournament_header_banner.dart';
import 'header/tournament_header_quick_actions.dart';
import 'header/tournament_header_tabs.dart';

/// Cabeçalho Hero e Barra de Abas da página do Campeonato (SRP & Dumb UI):
/// - Compõe Banner, Metadados, Ações Rápidas e Barra de Navegação Independente.
class TournamentDetailsHeader extends StatelessWidget {
  final TournamentDto tournament;
  final TournamentDetailsController controller;
  final bool canManage;
  final VoidCallback onBack;
  final ValueChanged<TournamentDetailTab> onSelectTab;
  final VoidCallback onRegisterAction;
  final VoidCallback? onOpenRegistrations;
  final VoidCallback onCloseRegistrations;
  final VoidCallback onStartTournament;
  final VoidCallback? onOpenDraftRoom;
  final VoidCallback? onAdvanceToPlayoffs;
  final VoidCallback? onRevertToGroupStage;
  final VoidCallback? onCancelTournament;
  final VoidCallback? onDeleteTournament;
  final VoidCallback? onLockResults;
  final VoidCallback? onUnlockResults;

  const TournamentDetailsHeader({
    super.key,
    required this.tournament,
    required this.controller,
    required this.canManage,
    required this.onBack,
    required this.onSelectTab,
    required this.onRegisterAction,
    this.onOpenRegistrations,
    required this.onCloseRegistrations,
    required this.onStartTournament,
    this.onOpenDraftRoom,
    this.onAdvanceToPlayoffs,
    this.onRevertToGroupStage,
    this.onCancelTournament,
    this.onDeleteTournament,
    this.onLockResults,
    this.onUnlockResults,
  });

  @override
  Widget build(BuildContext context) {
    const double bannerHeight = 150.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Botão "Voltar para Campeonatos" elegante no padrão suave com toque Vermelho Neon
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(6),
            hoverColor: AppColors.primaryNeon.withValues(alpha: 0.12),
            splashColor: AppColors.primaryNeon.withValues(alpha: 0.20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryNeon.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 15,
                    color: AppColors.primaryNeon,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'VOLTAR PARA CAMPEONATOS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Card Principal com Banner e Metadados
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Hero (com imagem, badges e faixa de trava de resultados)
              TournamentHeaderBanner(
                tournament: tournament,
                height: bannerHeight,
              ),

              // Faixa Inferior de Metadados e Ações Rápidas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    // Metadados: Data Início | Data Fim | Equipes | Modalidade
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildMetaItem(
                          icon: Icons.event_available_rounded,
                          iconColor: AppColors.dotaGold,
                          label: 'INÍCIO',
                          value: tournament.startDateLabel,
                        ),
                        _buildMetaItem(
                          icon: Icons.event_rounded,
                          iconColor: AppColors.primaryNeon,
                          label: 'FIM',
                          value: tournament.endDateLabel,
                        ),
                        _buildMetaItem(
                          icon: Icons.groups_rounded,
                          iconColor: AppColors.dotaGoldLight,
                          label: 'VAGAS',
                          value: tournament.teamsProgressLabel,
                        ),
                        _buildMetaItem(
                          icon: tournament.entryModeIcon,
                          iconColor: tournament.entryModeColor,
                          label: 'MODALIDADE',
                          value: tournament.entryModeLabel,
                        ),
                      ],
                    ),

                    // Botões de Ação e Menu Popup
                    TournamentHeaderQuickActions(
                      tournament: tournament,
                      canManage: canManage,
                      canAdvanceToPlayoffs: controller.canAdvanceToPlayoffs,
                      onRegisterAction: onRegisterAction,
                      onOpenRegistrations: onOpenRegistrations,
                      onCloseRegistrations: onCloseRegistrations,
                      onStartTournament: onStartTournament,
                      onOpenDraftRoom: onOpenDraftRoom,
                      onAdvanceToPlayoffs: onAdvanceToPlayoffs,
                      onRevertToGroupStage: onRevertToGroupStage,
                      onCancelTournament: onCancelTournament,
                      onDeleteTournament: onDeleteTournament,
                      onLockResults: onLockResults,
                      onUnlockResults: onUnlockResults,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. Barra de Navegação Independente de Ponta a Ponta (100% de largura)
        TournamentHeaderTabs(
          controller: controller,
          canManage: canManage,
          onSelectTab: onSelectTab,
        ),
      ],
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
