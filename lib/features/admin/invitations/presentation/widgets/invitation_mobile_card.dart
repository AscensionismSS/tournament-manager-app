import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../models/invitation_dto.dart';
import 'invitation_status_badge.dart';

/// Card moderno, altamente legível e adaptável para dispositivos móveis (SRP).
/// Estruturado em 3 níveis visuais bem definidos:
/// 1. Cabeçalho (E-mail, papel e status).
/// 2. Caixa destacada de código com botão de cópia de um toque.
/// 3. Rodapé com data/validade contextual e ação de revogação.
class InvitationMobileCard extends StatelessWidget {
  final InvitationDto invite;
  final bool isRevoking;
  final ValueChanged<InvitationDto> onCopyCode;
  final ValueChanged<InvitationDto> onRevoke;

  const InvitationMobileCard({
    super.key,
    required this.invite,
    this.isRevoking = false,
    required this.onCopyCode,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Cabeçalho: E-mail, Papel e Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 5),
                      InvitationRoleBadge(invite: invite),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InvitationStatusBadge(status: invite.status),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Ação Rápida de Cópia do Link
            AppButton.outline(
              customColor: AppColors.dotaGold,
              size: AppButtonSize.small,
              icon: Icons.link_rounded,
              text: 'COPIAR LINK DE CADASTRO',
              isFullWidth: true,
              onPressed: () => onCopyCode(invite),
            ),
            const SizedBox(height: 12),

            // 3. Validade / Emissão
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: invite.status.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    invite.validityDescription,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: invite.status.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  invite.formattedCreatedAt,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // 4. Ação de Revogação Destacada (Visível e Ergonômica no Mobile)
            if (invite.canBeRevoked) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              AppButton.danger(
                size: AppButtonSize.small,
                isFullWidth: true,
                icon: Icons.cancel_outlined,
                text: 'REVOGAR CONVITE',
                isLoading: isRevoking,
                onPressed: isRevoking ? null : () => onRevoke(invite),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
