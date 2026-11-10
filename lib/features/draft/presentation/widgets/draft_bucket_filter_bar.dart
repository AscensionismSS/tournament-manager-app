import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';

/// Ordem de ordenação por Nome
enum PlayerNameSort { none, asc, desc }

/// Ordem de ordenação por Rank
enum PlayerRankSort { none, desc, asc }

/// Barra modular de filtros por Função (com símbolos oficiais) e botões de ordenação cíclica (SRP).
class DraftBucketFilterBar extends StatelessWidget {
  final DotaRoleType? selectedRole;
  final ValueChanged<DotaRoleType?> onRoleSelected;
  final PlayerNameSort nameSort;
  final VoidCallback onCycleNameSort;
  final PlayerRankSort rankSort;
  final VoidCallback onCycleRankSort;
  final VoidCallback? onOpenRolesGuide;

  const DraftBucketFilterBar({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
    required this.nameSort,
    required this.onCycleNameSort,
    required this.rankSort,
    required this.onCycleRankSort,
    this.onOpenRolesGuide,
  });

  static const List<DotaRoleType> _roles = [
    DotaRoleType.safeLane,
    DotaRoleType.midLane,
    DotaRoleType.offLane,
    DotaRoleType.support,
    DotaRoleType.hardSupport,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Barra de Funções (Símbolos oficiais do Dota 2 + Botão Info [i])
        Row(
          children: [
            // Botão "TODAS"
            _buildAllButton(),
            const SizedBox(width: 5),

            // Símbolos das 5 Posições Oficiais
            for (final role in _roles) ...[
              _buildRoleIconButton(role),
              const SizedBox(width: 5),
            ],

            const Spacer(),

            // Botão [i] de Informação e Guia das Funções usando o AppInfoButton oficial do shared
            if (onOpenRolesGuide != null)
              AppInfoButton(
                tooltip: 'Guia de Funções (Roles)',
                size: AppIconButtonSize.compact,
                variant: AppIconButtonVariant.primary,
                onPressed: onOpenRolesGuide,
              ),
          ],
        ),

        const SizedBox(height: 8),

        // 2. Botões de Ordenação Cíclica (Nome e Rank)
        Row(
          children: [
            Expanded(
              child: _buildSortButton(
                title: 'NOME',
                subtitle: nameSort == PlayerNameSort.asc
                    ? 'A-Z ↑'
                    : (nameSort == PlayerNameSort.desc ? 'Z-A ↓' : 'Inscrição'),
                isActive: nameSort != PlayerNameSort.none,
                icon: nameSort == PlayerNameSort.asc
                    ? Icons.arrow_upward_rounded
                    : (nameSort == PlayerNameSort.desc
                        ? Icons.arrow_downward_rounded
                        : Icons.sort_by_alpha_rounded),
                onTap: onCycleNameSort,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSortButton(
                title: 'RANK',
                subtitle: rankSort == PlayerRankSort.desc
                    ? 'Maior ↓'
                    : (rankSort == PlayerRankSort.asc ? 'Menor ↑' : 'Inscrição'),
                isActive: rankSort != PlayerRankSort.none,
                icon: rankSort == PlayerRankSort.desc
                    ? Icons.trending_down_rounded
                    : (rankSort == PlayerRankSort.asc
                        ? Icons.trending_up_rounded
                        : Icons.military_tech_rounded),
                onTap: onCycleRankSort,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllButton() {
    final bool isSelected = selectedRole == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onRoleSelected(null),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.dotaGold.withValues(alpha: 0.18)
                : AppColors.canvasSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? AppColors.dotaGold
                  : AppColors.border.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'TODAS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isSelected ? AppColors.dotaGoldLight : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleIconButton(DotaRoleType role) {
    final bool isSelected = selectedRole == role;
    final Color roleColor = role.officialColor;

    return Tooltip(
      message: '${role.label} (${role.description})',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onRoleSelected(isSelected ? null : role),
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? roleColor.withValues(alpha: 0.24)
                  : AppColors.canvasSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? roleColor
                    : roleColor.withValues(alpha: 0.40),
                width: isSelected ? 1.4 : 0.85,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: DotaRoleIcon(
                role: role,
                size: 16,
                color: isSelected ? roleColor : roleColor.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton({
    required String title,
    required String subtitle,
    required bool isActive,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const Color activeColor = AppColors.dotaGold;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.12)
                : AppColors.canvasSurface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.75)
                  : AppColors.border.withValues(alpha: 0.45),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isActive ? AppColors.dotaGoldLight : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$title: $subtitle',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.4,
                  color: isActive ? AppColors.dotaGoldLight : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
