import 'package:flutter/material.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';

/// Item de mapeamento oficial das posições de Dota 2 sincronizado com o backend (DotaRole enum).
class DotaRoleDef {
  final int id;
  final String name; // Nome do enum C#
  final String label;
  final String roleName;
  final String posLabel;
  final DotaRoleType roleType;
  final Color color;

  const DotaRoleDef({
    required this.id,
    required this.name,
    required this.label,
    required this.roleName,
    required this.posLabel,
    required this.roleType,
    required this.color,
  });

  /// Lista oficial com as 6 posições de Dota 2 suportadas pela plataforma
  static const List<DotaRoleDef> availableRoles = [
    DotaRoleDef(
      id: 1,
      name: 'Carry',
      label: 'Safe Lane (Pos 1)',
      roleName: 'Safe Lane',
      posLabel: 'Pos 1',
      roleType: DotaRoleType.safeLane,
      color: AppColors.feedbackError,
    ),
    DotaRoleDef(
      id: 2,
      name: 'Mid',
      label: 'Mid Lane (Pos 2)',
      roleName: 'Mid Lane',
      posLabel: 'Pos 2',
      roleType: DotaRoleType.midLane,
      color: AppColors.dotaGold,
    ),
    DotaRoleDef(
      id: 3,
      name: 'Offlane',
      label: 'Off Lane (Pos 3)',
      roleName: 'Off Lane',
      posLabel: 'Pos 3',
      roleType: DotaRoleType.offLane,
      color: AppColors.feedbackSuccess,
    ),
    DotaRoleDef(
      id: 4,
      name: 'SoftSupport',
      label: 'Support (Pos 4)',
      roleName: 'Support',
      posLabel: 'Pos 4',
      roleType: DotaRoleType.support,
      color: AppColors.feedbackInfo,
    ),
    DotaRoleDef(
      id: 5,
      name: 'HardSupport',
      label: 'Hard Support (Pos 5)',
      roleName: 'Hard Support',
      posLabel: 'Pos 5',
      roleType: DotaRoleType.hardSupport,
      color: AppColors.dotaRoleHardSupport,
    ),
    DotaRoleDef(
      id: 6,
      name: 'Flex',
      label: 'Flex (Coringa)',
      roleName: 'Flex',
      posLabel: 'Pos 6',
      roleType: DotaRoleType.flex,
      color: AppColors.dotaRoleFlex,
    ),
  ];
}
