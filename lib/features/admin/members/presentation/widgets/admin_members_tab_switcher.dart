import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../controllers/admin_members_controller.dart';

/// Barra seletora de abas oficial do painel de administração de membros (SRP).
class AdminMembersTabSwitcher extends StatelessWidget {
  final AdminMembersTab activeTab;
  final ValueChanged<AdminMembersTab> onTabChanged;
  final int pendingRequestsCount;

  const AdminMembersTabSwitcher({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    this.pendingRequestsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(
            tab: AdminMembersTab.members,
            label: 'Gestão de Membros',
            icon: Icons.people_alt_rounded,
            badgeCount: null,
          ),
          const SizedBox(width: 6),
          _buildTabButton(
            tab: AdminMembersTab.recoveryRequests,
            label: 'Solicitações de Troca de Steam',
            icon: Icons.vpn_key_rounded,
            badgeCount: pendingRequestsCount,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required AdminMembersTab tab,
    required String label,
    required IconData icon,
    int? badgeCount,
  }) {
    final isSelected = activeTab == tab;

    return InkWell(
      onTap: () => onTabChanged(tab),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceHighlight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon.withValues(alpha: 0.8) : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNeon.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryNeon : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.dotaGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
