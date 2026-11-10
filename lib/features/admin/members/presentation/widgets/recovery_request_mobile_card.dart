import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/safe_url_launcher.dart';
import '../../../../members/models/member_dto.dart';
import '../../../../members/models/recovery_request_dto.dart';

/// Card Mobile para Solicitações de Troca de Steam usando AppCard.
/// Adaptado com a mesma identidade de [AdminMemberMobileCard]:
/// - Solicitante (Avatar + Nick da Plataforma + E-mail)
/// - Steam Atual (Nick da Steam + Link direto)
/// - Tipo, Data, Status e Ação de Aprovação
class RecoveryRequestMobileCard extends StatelessWidget {
  final RecoveryRequestDto request;
  final MemberDto? member;
  final bool isProcessing;
  final ValueChanged<RecoveryRequestDto> onApprove;
  final ValueChanged<RecoveryRequestDto> onReject;

  const RecoveryRequestMobileCard({
    super.key,
    required this.request,
    this.member,
    this.isProcessing = false,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // Resolução de dados de Steam: DTO nativo com fallback para o cadastro de membros
    final String? steamId = request.steamId ?? member?.steamId;
    final String? personaName = request.personaName ?? member?.personaName;
    final String? avatarUrl = request.avatarUrl ?? member?.avatarUrl;
    final bool hasSteam = steamId != null && steamId.trim().isNotEmpty;
    final String? profileUrl = request.computedSteamProfileUrl ?? member?.computedSteamProfileUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Topo: Avatar + Nick da Plataforma + E-mail | Badge Status
            Row(
              children: [
                AppAvatar(
                  imageUrl: avatarUrl,
                  name: request.displayName,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nick da Plataforma
                      Text(
                        request.displayName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // E-mail com cópia em um clique
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: request.email));
                          AppFeedback.showSuccess(
                            context,
                            message: 'E-mail copiado: ${request.email}',
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                request.email,
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
                const AppBadge(
                  label: 'Pendente',
                  variant: AppBadgeVariant.warning,
                  icon: Icons.hourglass_top_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Linha da Steam Atual
            Row(
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  size: 14,
                  color: AppColors.dotaGoldLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasSteam
                        ? (personaName?.trim().isNotEmpty == true ? personaName! : steamId)
                        : 'Sem Steam vinculada',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: hasSteam
                          ? AppColors.dotaGoldLight
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                      fontStyle: hasSteam ? FontStyle.normal : FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSteam && profileUrl != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => SafeUrlLauncher.launch(
                      profileUrl,
                      context: context,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Steam: $steamId',
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
              ],
            ),
            const SizedBox(height: 10),

            // Data do Pedido
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Solicitado em: ${request.formattedCreatedAt}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            if (request.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'RECUSAR',
                      icon: Icons.close_rounded,
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.danger,
                      isLoading: isProcessing,
                      onPressed: isProcessing ? null : () => onReject(request),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      text: 'APROVAR',
                      icon: Icons.check_rounded,
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.primary,
                      isLoading: isProcessing,
                      onPressed: isProcessing ? null : () => onApprove(request),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
