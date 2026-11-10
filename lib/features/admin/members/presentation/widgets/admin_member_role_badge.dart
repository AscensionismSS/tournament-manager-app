import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../members/models/member_dto.dart';

/// Badge visual oficial para cargos administrativos e de jogadores (SRP & DRY).
class AdminMemberRoleBadge extends StatelessWidget {
  final MemberDto member;

  const AdminMemberRoleBadge({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    if (member.isSuperAdmin) {
      return AppBadge(
        label: member.roleDisplayName,
        variant: AppBadgeVariant.warning,
        icon: Icons.shield_rounded,
      );
    }
    if (member.isAdmin) {
      return AppBadge(
        label: member.roleDisplayName,
        variant: AppBadgeVariant.primary,
        icon: Icons.admin_panel_settings_rounded,
      );
    }
    return AppBadge(
      label: member.roleDisplayName,
      variant: AppBadgeVariant.neutral,
      icon: Icons.person_rounded,
    );
  }
}
