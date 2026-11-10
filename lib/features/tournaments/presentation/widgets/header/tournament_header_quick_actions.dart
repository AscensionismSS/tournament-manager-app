import 'package:flutter/material.dart';
import '../../../../../core/models/system_security_settings.dart';
import '../../../../../core/services/system_security_service.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../../../core/theme/theme.dart';
import '../../../models/tournament_dto.dart';
import '../../../models/tournament_status.dart';

/// Bloco de Ações Rápidas e Menu de Gerenciamento do Cabeçalho de Torneios (SRP & Dumb UI).
class TournamentHeaderQuickActions extends StatelessWidget {
  final TournamentDto tournament;
  final bool canManage;
  final bool canAdvanceToPlayoffs;
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

  const TournamentHeaderQuickActions({
    super.key,
    required this.tournament,
    required this.canManage,
    required this.canAdvanceToPlayoffs,
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
    final bool isOpen = tournament.isRegistrationOpen;
    final bool isDraftStatus = tournament.status == TournamentStatus.draft;
    final bool canStart = canManage && tournament.canStartTournament;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (canManage && isDraftStatus && onOpenRegistrations != null)
          AppButton(
            text: 'ABRIR INSCRIÇÕES',
            icon: Icons.lock_open_rounded,
            size: AppButtonSize.small,
            variant: AppButtonVariant.primary,
            onPressed: onOpenRegistrations,
          ),
        if (isOpen && !tournament.isFull)
          ValueListenableBuilder<SystemSecuritySettings>(
            valueListenable: SystemSecurityService.instance.settingsNotifier,
            builder: (context, security, _) {
              final isLocked = security.isTournamentRegistrationLocked;
              return ValueListenableBuilder(
                valueListenable: TokenStorage.profileNotifier,
                builder: (context, profile, _) {
                  final isAlreadyEnrolled = profile != null &&
                      tournament.draftPlayerPool.any(
                        (p) =>
                            p.id == profile.userId ||
                            (p.externalUserId != null &&
                                profile.steamId != null &&
                                p.externalUserId == profile.steamId),
                      );

                  String buttonText = 'INSCREVER EQUIPE';
                  IconData buttonIcon = Icons.how_to_reg_rounded;
                  AppButtonVariant buttonVariant = AppButtonVariant.primary;

                  if (isLocked) {
                    buttonText = 'INSCRIÇÕES TRAVADAS';
                    buttonIcon = Icons.lock_outline_rounded;
                  } else if (tournament.hasDraftSession) {
                    if (isAlreadyEnrolled) {
                      buttonText = 'INSCRITO NO DRAFT ✓';
                      buttonIcon = Icons.check_circle_rounded;
                      buttonVariant = AppButtonVariant.ghost;
                    } else {
                      buttonText = 'INSCREVER-SE';
                      buttonIcon = Icons.how_to_reg_rounded;
                      buttonVariant = AppButtonVariant.primary;
                    }
                  }

                  return AppButton(
                    text: buttonText,
                    icon: buttonIcon,
                    size: AppButtonSize.small,
                    variant: buttonVariant,
                    onPressed: isLocked ? null : onRegisterAction,
                  );
                },
              );
            },
          ),
        if (canManage && isOpen)
          AppButton(
            text: tournament.hasDraftSession ? 'INICIAR DRAFT' : 'TRAVAR VAGAS',
            icon: tournament.hasDraftSession
                ? Icons.shuffle_rounded
                : Icons.lock_outline_rounded,
            size: AppButtonSize.small,
            variant: tournament.hasDraftSession
                ? AppButtonVariant.primary
                : AppButtonVariant.ghost,
            onPressed: onCloseRegistrations,
          ),
        if (tournament.status == TournamentStatus.drafting && onOpenDraftRoom != null)
          AppButton(
            text: 'SALA DE DRAFT',
            icon: Icons.shuffle_rounded,
            size: AppButtonSize.small,
            variant: AppButtonVariant.primary,
            onPressed: onOpenDraftRoom,
          ),
        if (canStart)
          AppButton(
            text: 'INICIAR CAMPEONATO',
            icon: Icons.play_arrow_rounded,
            size: AppButtonSize.small,
            variant: AppButtonVariant.primary,
            onPressed: onStartTournament,
          ),
        if (canManage &&
            canAdvanceToPlayoffs &&
            onAdvanceToPlayoffs != null)
          AppButton(
            text: 'GERAR PLAYOFFS',
            icon: Icons.emoji_events_rounded,
            size: AppButtonSize.small,
            variant: AppButtonVariant.primary,
            onPressed: onAdvanceToPlayoffs,
          ),
        if (canManage)
          PopupMenuButton<String>(
            tooltip: 'Gerenciamento do Torneio',
            padding: EdgeInsets.zero,
            offset: const Offset(0, 42),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border, width: 1.0),
            ),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.canvasSurface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.75),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
            onSelected: (value) {
              if (value == 'lock_results' && onLockResults != null) {
                onLockResults!();
              } else if (value == 'unlock_results' && onUnlockResults != null) {
                onUnlockResults!();
              } else if (value == 'advance_playoffs' &&
                  onAdvanceToPlayoffs != null) {
                onAdvanceToPlayoffs!();
              } else if (value == 'revert_groups' &&
                  onRevertToGroupStage != null) {
                onRevertToGroupStage!();
              } else if (value == 'cancel' && onCancelTournament != null) {
                onCancelTournament!();
              } else if (value == 'delete' && onDeleteTournament != null) {
                onDeleteTournament!();
              }
            },
            itemBuilder: (context) => [
              // Trava / Destrava de Envio de Resultados (Result Submission Lock)
              if (tournament.status != TournamentStatus.canceled &&
                  tournament.status != TournamentStatus.completed) ...[
                if (!tournament.isResultSubmissionLocked && onLockResults != null)
                  const PopupMenuItem(
                    value: 'lock_results',
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_clock_rounded,
                          size: 16,
                          color: AppColors.feedbackWarning,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Travar Resultados',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.feedbackWarning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (tournament.isResultSubmissionLocked &&
                    onUnlockResults != null)
                  const PopupMenuItem(
                    value: 'unlock_results',
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          size: 16,
                          color: AppColors.dotaGoldLight,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Destravar Resultados',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dotaGoldLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (tournament.status == TournamentStatus.groupStage &&
                  onAdvanceToPlayoffs != null)
                const PopupMenuItem(
                  value: 'advance_playoffs',
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          size: 16, color: AppColors.dotaGoldLight),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gerar Playoffs',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dotaGoldLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (tournament.status == TournamentStatus.playoffs &&
                  onRevertToGroupStage != null)
                const PopupMenuItem(
                  value: 'revert_groups',
                  child: Row(
                    children: [
                      Icon(Icons.undo_rounded,
                          size: 16, color: AppColors.dotaGoldLight),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reverter para Grupos',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dotaGoldLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (tournament.status != TournamentStatus.canceled &&
                  tournament.status != TournamentStatus.completed)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_rounded,
                          size: 16, color: AppColors.feedbackWarning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cancelar Torneio',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.feedbackWarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        size: 16, color: AppColors.feedbackError),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Excluir Torneio',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.feedbackError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
