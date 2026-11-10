import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/safe_url_launcher.dart';
import '../../../../members/models/member_dto.dart';
import 'admin_member_role_badge.dart';

/// Card Mobile oficial para membros no painel administrativo (usando AppCard).
class AdminMemberMobileCard extends StatelessWidget {
  final MemberDto member;
  final bool isProcessing;
  final ValueChanged<MemberDto> onToggleStatus;

  const AdminMemberMobileCard({
    super.key,
    required this.member,
    this.isProcessing = false,
    required this.onToggleStatus,
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
            // Topo: Avatar + Nick da Plataforma + E-mail | Cargo Badge
            Row(
              children: [
                AppAvatar(
                  imageUrl: member.avatarUrl,
                  name: member.displayName,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nick da Plataforma
                      Text(
                        member.displayName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // E-mail da Conta (com cópia em um clique)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: member.displayEmail));
                          AppFeedback.showSuccess(
                            context,
                            message: 'E-mail copiado: ${member.displayEmail}',
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                member.displayEmail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_rounded,
                              size: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AdminMemberRoleBadge(member: member),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Linha da Steam (Nick em cima/esquerda + Link embaixo/direita)
            if (member.isSteamLinked) ...[
              Row(
                children: [
                  const Icon(
                    Icons.sports_esports_rounded,
                    size: 14,
                    color: AppColors.dotaGoldLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    member.personaName ?? member.steamId ?? 'Steam',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dotaGoldLight,
                    ),
                  ),
                  const Spacer(),
                  if (member.computedSteamProfileUrl != null)
                    InkWell(
                      onTap: () => SafeUrlLauncher.launch(
                        member.computedSteamProfileUrl!,
                        context: context,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            member.steamId != null
                                ? 'Steam: ${member.steamId}'
                                : 'Ver perfil',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary.withValues(alpha: 0.85),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 12,
                            color: AppColors.dotaGold.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Linha de Status (Conta / Login)
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS DA CONTA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppBadge(
                      label: member.isActive ? 'Ativo' : 'Desativado',
                      variant: member.isActive ? AppBadgeVariant.success : AppBadgeVariant.error,
                      icon: member.isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                    ),
                  ],
                ),
              ],
            ),

            if (!member.isActive && member.statusReason != null && member.statusReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: AppColors.feedbackError,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Motivo: ${member.statusReason}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.feedbackError,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Botão de Moderação Mobile
            AppButton(
              text: member.isActive ? 'Bloquear Login' : 'Ativar Login',
              icon: member.isActive ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: AppButtonSize.small,
              isFullWidth: true,
              variant: member.isActive ? AppButtonVariant.danger : AppButtonVariant.secondary,
              isLoading: isProcessing,
              onPressed: isProcessing ? null : () => onToggleStatus(member),
            ),
          ],
        ),
      ),
    );
  }
}
