import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/safe_url_launcher.dart';
import '../../../../members/models/member_dto.dart';
import '../../../../members/models/recovery_request_dto.dart';

/// Tabela Desktop para Solicitações Pendentes de Troca de Steam.
/// Alinhada estritamente com a identidade visual e colunas de [AdminMembersTable]:
/// - Solicitante (Avatar + Nick da Plataforma + E-mail)
/// - Steam Atual agrupada à esquerda (Nick da Steam + Link direto)
/// - Tipo, Data, Status e Ação de Aprovação alinhados à direita.
class RecoveryRequestsTable extends StatelessWidget {
  final List<RecoveryRequestDto> requests;
  final String? processingRequestId;
  final ValueChanged<RecoveryRequestDto> onApprove;
  final ValueChanged<RecoveryRequestDto> onReject;
  final MemberDto? Function(String userId)? getMember;

  const RecoveryRequestsTable({
    super.key,
    required this.requests,
    this.processingRequestId,
    required this.onApprove,
    required this.onReject,
    this.getMember,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Cabeçalho da Tabela
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.surfaceHighlight,
              child: const Row(
                children: [
                  // 1. Solicitante
                  SizedBox(
                    width: 260,
                    child: Text(
                      'SOLICITANTE',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 24),
                  // 2. Coluna de Steam Atual (Perto do Solicitante)
                  SizedBox(
                    width: 240,
                    child: Text(
                      'STEAM ATUAL',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Spacer(),
                  // 3. Data do Pedido
                  SizedBox(
                    width: 140,
                    child: Text(
                      'DATA DO PEDIDO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // 4. Status
                  SizedBox(
                    width: 110,
                    child: Text(
                      'STATUS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // 5. Ações (Recusar e Aprovar)
                  SizedBox(
                    width: 230,
                    child: Text(
                      'AÇÕES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Linhas com Separador Nítido e Confortável
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border.withValues(alpha: 0.75),
              ),
              itemBuilder: (context, index) {
                final req = requests[index];
                final isProcessing = processingRequestId == req.id;
                final member = getMember?.call(req.userId);

                return _buildRow(context, req, member, isProcessing);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    RecoveryRequestDto req,
    MemberDto? member,
    bool isProcessing,
  ) {
    // Resolução de dados de Steam: DTO nativo com fallback para o cadastro de membros
    final String? steamId = req.steamId ?? member?.steamId;
    final String? personaName = req.personaName ?? member?.personaName;
    final String? avatarUrl = req.avatarUrl ?? member?.avatarUrl;
    final bool hasSteam = steamId != null && steamId.trim().isNotEmpty;
    final String? profileUrl = req.computedSteamProfileUrl ?? member?.computedSteamProfileUrl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.transparent,
      child: Row(
        children: [
          // 1. Solicitante (Avatar + Nick da Plataforma em cima + E-mail embaixo com cópia)
          SizedBox(
            width: 260,
            child: Row(
              children: [
                AppAvatar(
                  imageUrl: avatarUrl,
                  name: req.displayName,
                  radius: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Em cima: Nick da Plataforma
                      Text(
                        req.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Embaixo: E-mail da conta (com cópia em um clique)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: req.email));
                          AppFeedback.showSuccess(
                            context,
                            message: 'E-mail copiado: ${req.email}',
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Tooltip(
                          message: 'Clique para copiar o e-mail',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    req.email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 12,
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // 2. Coluna STEAM ATUAL (Perto do Solicitante: Nick da Steam em cima + Link embaixo)
          SizedBox(
            width: 240,
            child: hasSteam
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Em cima: Nick da Steam
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sports_esports_rounded,
                            size: 14,
                            color: AppColors.dotaGoldLight,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              personaName?.trim().isNotEmpty == true
                                  ? personaName!
                                  : steamId,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dotaGoldLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Embaixo: Link direto clicável para a Steam
                      if (profileUrl != null)
                        InkWell(
                          onTap: () => SafeUrlLauncher.launch(
                            profileUrl,
                            context: context,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Steam: $steamId',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.textSecondary.withValues(alpha: 0.4),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                        ),
                    ],
                  )
                : Text(
                    'Sem Steam vinculada',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
          const Spacer(),

          // 3. Data do Pedido
          SizedBox(
            width: 140,
            child: Text(
              req.formattedCreatedAt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // 4. Status (Pendente)
          const SizedBox(
            width: 110,
            child: Center(
              child: AppBadge(
                label: 'Pendente',
                variant: AppBadgeVariant.warning,
                icon: Icons.hourglass_top_rounded,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // 5. Ações (Recusar e Aprovar)
          SizedBox(
            width: 230,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  text: 'RECUSAR',
                  icon: Icons.close_rounded,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.danger,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : () => onReject(req),
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: 'APROVAR',
                  icon: Icons.check_rounded,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.primary,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : () => onApprove(req),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
