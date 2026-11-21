import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/safe_url_launcher.dart';
import '../../../../members/models/member_dto.dart';
import 'admin_member_role_badge.dart';

/// Cabeçalho modular da tabela desktop de membros (permite virtualização via Slivers).
class AdminMembersTableHeader extends StatelessWidget {
  final bool roundTopCorners;

  const AdminMembersTableHeader({
    super.key,
    this.roundTopCorners = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: roundTopCorners
            ? const BorderRadius.vertical(top: Radius.circular(12))
            : null,
        border: roundTopCorners
            ? const Border(
                top: BorderSide(color: AppColors.border),
                left: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              )
            : null,
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 260,
            child: Text(
              'MEMBRO',
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
          SizedBox(
            width: 240,
            child: Text(
              'STEAM',
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
          SizedBox(
            width: 130,
            child: Text(
              'CARGO',
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
          SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Text(
              'STATUS DA CONTA',
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
          SizedBox(width: 16),
          SizedBox(
            width: 90,
            child: Text(
              'MODERAÇÃO',
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
    );
  }
}

/// Linha modular de membro (reutilizável tanto em SliverList virtualizada quanto em scroll horizontal).
class AdminMembersTableRow extends StatelessWidget {
  final MemberDto member;
  final bool isProcessing;
  final bool isLast;
  final bool framed;
  final ValueChanged<MemberDto> onToggleStatus;

  const AdminMembersTableRow({
    super.key,
    required this.member,
    required this.isProcessing,
    required this.onToggleStatus,
    this.isLast = false,
    this.framed = false,
  });

  @override
  Widget build(BuildContext context) {
    final rowContent = AdminMembersTable._buildRowContent(
      context,
      member,
      isProcessing,
      onToggleStatus,
    );

    if (!framed) return rowContent;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(12))
              : null,
          border: Border(
            left: const BorderSide(color: AppColors.border),
            right: const BorderSide(color: AppColors.border),
            bottom: BorderSide(
              color: isLast
                  ? AppColors.border
                  : AppColors.border.withValues(alpha: 0.75),
            ),
          ),
        ),
        child: rowContent,
      ),
    );
  }
}

/// Tabela Desktop oficial para Gerenciamento de Membros e Identidade Steam.
class AdminMembersTable extends StatelessWidget {
  final List<MemberDto> members;
  final String? processingUserId;
  final ValueChanged<MemberDto> onToggleStatus;

  const AdminMembersTable({
    super.key,
    required this.members,
    this.processingUserId,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tableWidth = constraints.maxWidth < 960.0 ? 960.0 : constraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    const AdminMembersTableHeader(),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.border.withValues(alpha: 0.75),
                      ),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isProcessing = processingUserId == member.userId;

                        return _buildRowContent(
                          context,
                          member,
                          isProcessing,
                          onToggleStatus,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildRowContent(
    BuildContext context,
    MemberDto member,
    bool isProcessing,
    ValueChanged<MemberDto> onToggleStatus,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.transparent,
      child: Row(
        children: [
          // 1. Jogador / Membro (Nick da Plataforma em cima + E-mail embaixo com cópia)
          SizedBox(
            width: 260,
            child: Row(
              children: [
                AppAvatar(
                  imageUrl: member.avatarUrl,
                  name: member.displayName,
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
                        member.displayName,
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
                          Clipboard.setData(ClipboardData(text: member.displayEmail));
                          AppFeedback.showSuccess(
                            context,
                            message: 'E-mail copiado: ${member.displayEmail}',
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
                                    member.displayEmail,
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

          // 2. Coluna STEAM (Perto de Membro: Nick da Steam em cima + Link para a Steam embaixo)
          SizedBox(
            width: 240,
            child: member.isSteamLinked
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
                              member.personaName?.trim().isNotEmpty == true
                                  ? member.personaName!
                                  : (member.steamId ?? 'Steam Vinculada'),
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
                      // Embaixo: O que leva para a Steam (Link direto)
                      if (member.computedSteamProfileUrl != null)
                        InkWell(
                          onTap: () => SafeUrlLauncher.launch(
                            member.computedSteamProfileUrl!,
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
                                    member.steamId != null
                                        ? 'Steam: ${member.steamId}'
                                        : 'Ver perfil na Steam',
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

          // 3. Cargo
          SizedBox(
            width: 130,
            child: Center(
              child: AdminMemberRoleBadge(member: member),
            ),
          ),
          const SizedBox(width: 16),

          // 4. Status da Conta (Login)
          SizedBox(
            width: 140,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBadge(
                  label: member.isActive ? 'Ativo' : 'Desativado',
                  variant: member.isActive ? AppBadgeVariant.success : AppBadgeVariant.error,
                  icon: member.isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                ),
                if (!member.isActive && member.statusReason != null && member.statusReason!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Tooltip(
                    message: member.statusReason!,
                    child: Text(
                      member.statusReason!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.feedbackError,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 5. Ações Administrativas (Moderação de Login)
          SizedBox(
            width: 90,
            child: Center(
              child: member.isRootOwner
                  ? const Tooltip(
                      message: 'Proprietário Raiz protegido',
                      child: AppBadge(
                        label: 'Raiz',
                        customColor: AppColors.dotaGold,
                        icon: Icons.verified_user_rounded,
                        fontSize: 10.5,
                      ),
                    )
                  : AppIconButton(
                      icon: member.isActive ? Icons.lock_rounded : Icons.lock_open_rounded,
                      variant: member.isActive
                          ? AppIconButtonVariant.danger
                          : AppIconButtonVariant.success,
                      size: AppIconButtonSize.small,
                      isLoading: isProcessing,
                      tooltip: member.isActive
                          ? 'Desativar membro (Bloquear Login)'
                          : 'Ativar membro (Liberar Login)',
                      onPressed: isProcessing ? null : () => onToggleStatus(member),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
