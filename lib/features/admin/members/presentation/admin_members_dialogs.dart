import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../members/models/member_dto.dart';
import '../../../members/models/recovery_request_dto.dart';
import '../controllers/admin_members_controller.dart';

/// Orquestrador de diálogos e confirmações para ações administrativas de membros (SRP).
abstract final class AdminMembersDialogs {
  /// Confirma e processa a ativação/bloqueio de login do membro
  static Future<void> toggleStatus(
    BuildContext context,
    AdminMembersController controller,
    MemberDto member,
  ) async {
    final willDeactivate = member.isActive;
    final reason = await AppPromptDialog.show(
      context,
      title: willDeactivate ? 'BLOQUEAR LOGIN' : 'REATIVAR LOGIN',
      message: willDeactivate
          ? 'Informe a justificativa para bloquear o login de "${member.effectiveNickname}":'
          : 'Deseja reativar o acesso de "${member.effectiveNickname}" à plataforma?',
      hintText: willDeactivate ? 'Ex: Conduta tóxica recorrente' : 'Motivo opcional...',
      confirmLabel: willDeactivate ? 'BLOQUEAR ACESSO' : 'REATIVAR ACESSO',
      cancelLabel: 'CANCELAR',
      isDestructive: willDeactivate,
      icon: willDeactivate ? Icons.lock_rounded : Icons.lock_open_rounded,
    );

    if (reason == null && willDeactivate) return;

    if (context.mounted) {
      final success = await controller.updateUserStatus(
        member.userId,
        isActive: !willDeactivate,
        reason: reason,
      );

      if (context.mounted) {
        if (success) {
          AppFeedback.showSuccess(
            context,
            message: willDeactivate
                ? 'Acesso de "${member.effectiveNickname}" desativado com sucesso.'
                : 'Acesso de "${member.effectiveNickname}" reativado com sucesso.',
          );
        } else {
          AppFeedback.showError(
            context,
            message: controller.membersError ?? 'Falha ao alterar status da conta.',
          );
        }
      }
    }
  }


  /// Confirma e processa a aprovação de troca de Steam
  static Future<void> approveRecovery(
    BuildContext context,
    AdminMembersController controller,
    RecoveryRequestDto req,
  ) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'APROVAR TROCA DE STEAM',
      message:
          'Deseja aprovar a solicitação de "${req.displayName}"? A conta Steam atual será desvinculada imediatamente e o jogador será notificado em tempo real.',
      confirmLabel: 'APROVAR TROCA',
      cancelLabel: 'CANCELAR',
      icon: Icons.vpn_key_rounded,
    );

    if (confirm && context.mounted) {
      final success = await controller.approveSteamUnlock(req.id);
      if (context.mounted) {
        if (success) {
          AppFeedback.showSuccess(
            context,
            message: 'Solicitação aprovada com sucesso! A conta Steam de "${req.displayName}" foi desvinculada.',
          );
        } else {
          AppFeedback.showError(
            context,
            message: controller.requestsError ?? 'Falha ao aprovar solicitação de troca.',
          );
        }
      }
    }
  }

  /// Confirma e processa a recusa da solicitação de troca de Steam
  static Future<void> rejectRecovery(
    BuildContext context,
    AdminMembersController controller,
    RecoveryRequestDto req,
  ) async {
    final reason = await AppPromptDialog.show(
      context,
      title: 'RECUSAR TROCA DE STEAM',
      message:
          'Deseja recusar a solicitação de troca de Steam de "${req.displayName}"? Se desejar, informe a justificativa:',
      hintText: 'Ex: Conta Steam divergente / suspeita',
      confirmLabel: 'RECUSAR PEDIDO',
      cancelLabel: 'CANCELAR',
      isDestructive: true,
      icon: Icons.cancel_outlined,
    );

    if (reason == null) return;

    if (context.mounted) {
      final success = await controller.rejectSteamUnlock(req.id, reason: reason);
      if (context.mounted) {
        if (success) {
          AppFeedback.showSuccess(
            context,
            message: 'Solicitação de "${req.displayName}" recusada.',
          );
        } else {
          AppFeedback.showError(
            context,
            message: controller.requestsError ?? 'Falha ao recusar solicitação de troca.',
          );
        }
      }
    }
  }
}
