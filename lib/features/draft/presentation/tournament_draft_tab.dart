import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../tournaments/models/tournament_dto.dart';
import '../controllers/draft_controller.dart';
import '../models/draft_state_snapshot_dto.dart';
import 'widgets/draft_captains_phase_view.dart';
import 'widgets/draft_header_stepper.dart';
import 'widgets/draft_order_selection_dialog.dart';

/// Aba oficial da Sala de Draft de Equipes (SRP & Dumb UI).
/// Conectada ao [DraftController] e sincronizada em tempo real via SignalR.
class TournamentDraftTab extends StatefulWidget {
  final TournamentDto tournament;
  final bool canManage;

  const TournamentDraftTab({
    super.key,
    required this.tournament,
    required this.canManage,
  });

  @override
  State<TournamentDraftTab> createState() => _TournamentDraftTabState();
}

class _TournamentDraftTabState extends State<TournamentDraftTab> {
  late final DraftController _draftController;

  @override
  void initState() {
    super.initState();
    _draftController = DraftController();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final sessionId = widget.tournament.draftSessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      await _draftController.fetchSnapshot(sessionId);
    }
  }

  Future<void> _handleOpenOrderDialog(DraftStateSnapshotDto snapshot) async {
    final confirmed = await DraftOrderSelectionDialog.show(
      context,
      snapshot: snapshot,
      onConfirm: ({
        required int orderType,
        List<String>? manualOrderIds,
      }) {
        return _draftController.finalizeCaptainOrder(
          orderType: orderType,
          manualOrderIds: manualOrderIds,
        );
      },
    );

    if (confirmed == true && mounted) {
      AppFeedback.showSuccess(
        context,
        message: 'Ordem do Snake Draft confirmada com sucesso!',
      );
    }
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = widget.tournament.draftSessionId;

    if (sessionId == null || sessionId.isEmpty) {
      return const AppEmptyState(
        icon: Icons.shuffle_rounded,
        title: 'MODALIDADE SEM DRAFT',
        message: 'Este campeonato não possui uma sessão de draft vinculada.',
      );
    }

    return AnimatedBuilder(
      animation: _draftController,
      builder: (context, _) {
        if (_draftController.isLoading && _draftController.snapshot == null) {
          return const Center(
            child: AppLoadingState(
              message: 'Conectando à Sala de Draft em tempo real...',
            ),
          );
        }

        if (_draftController.errorMessage != null &&
            _draftController.snapshot == null) {
          return Center(
            child: AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar Draft',
              message: _draftController.errorMessage!,
              actionLabel: 'Tentar Novamente',
              onActionPressed: _loadDraft,
            ),
          );
        }

        final snapshot = _draftController.snapshot;
        if (snapshot == null) {
          return const Center(
            child: AppEmptyState(
              icon: Icons.hourglass_empty_rounded,
              title: 'AGUARDANDO DADOS',
              message: 'Não foi possível carregar o estado do draft.',
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Barra de Etapas do Draft (Stepper)
            DraftHeaderStepper(
              currentStep: snapshot.currentStepNumber,
              stateLabel: snapshot.state,
              action: widget.canManage &&
                      ((snapshot.isSelectingCaptains &&
                              snapshot.allCaptainsAssigned) ||
                          snapshot.isCaptainOrderSelection)
                  ? AppButton(
                      text: 'DEFINIR ORDEM DO DRAFT',
                      icon: Icons.arrow_forward_rounded,
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.primary,
                      isLoading: _draftController.isActionInProgress,
                      onPressed: () => _handleOpenOrderDialog(snapshot),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            // 2. Renderização da Fase Atual
            _buildCurrentPhaseContent(snapshot),
          ],
        );
      },
    );
  }

  Widget _buildCurrentPhaseContent(DraftStateSnapshotDto snapshot) {
    // Fase 1: Seleção de Capitães
    if (snapshot.isSelectingCaptains) {
      return DraftCaptainsPhaseView(
        controller: _draftController,
        snapshot: snapshot,
        canManage: widget.canManage,
      );
    }

    // Fase 2: Ordem de Escolha do Snake Draft
    if (snapshot.isCaptainOrderSelection) {
      return AppCard(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dotaGold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.dotaGold.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  size: 28,
                  color: AppColors.dotaGoldLight,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'FASE 2: ORDEM DE ESCOLHA DO DRAFT',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Todos os capitães foram definidos! Escolha entre a ordem de pick dos capitães ou sorteio aleatório para o Snake Draft.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (widget.canManage) ...[
                const SizedBox(height: 16),
                AppButton(
                  text: 'DEFINIR ORDEM DO SNAKE DRAFT',
                  icon: Icons.format_list_numbered_rounded,
                  size: AppButtonSize.medium,
                  variant: AppButtonVariant.primary,
                  onPressed: () => _handleOpenOrderDialog(snapshot),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Fases 3 e 4: Titulares e Reservas
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_esports_rounded,
              size: 32,
              color: AppColors.primaryNeon,
            ),
            const SizedBox(height: 12),
            Text(
              'ESTADO DO DRAFT: ${snapshot.state.toUpperCase()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aguardando próximas etapas do fluxo do draft.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
