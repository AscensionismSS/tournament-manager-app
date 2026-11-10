import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Abas segmentadas para alternar entre jogadores Disponíveis e Escolhidos no Bucket (SRP).
class DraftBucketTabs extends StatelessWidget {
  final int activeIndex;
  final int availableCount;
  final int chosenCount;
  final ValueChanged<int> onTabChanged;
  final bool isLocked;
  final String? lockedTooltip;

  const DraftBucketTabs({
    super.key,
    required this.activeIndex,
    required this.availableCount,
    required this.chosenCount,
    required this.onTabChanged,
    this.isLocked = false,
    this.lockedTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              label: 'DISPONÍVEIS ($availableCount)',
              isSelected: activeIndex == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: Tooltip(
              message: isLocked
                  ? (lockedTooltip ?? 'Substituição em andamento: selecione o novo capitão em Disponíveis')
                  : '',
              child: _buildSegmentButton(
                label: 'ESCOLHIDOS ($chosenCount)',
                isSelected: activeIndex == 1,
                isBlocked: isLocked,
                onTap: isLocked ? () {} : () => onTabChanged(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    bool isBlocked = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBlocked ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceHighlight : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                    color: AppColors.dotaGold.withValues(alpha: 0.5),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isBlocked) ...[
                Icon(
                  Icons.lock_rounded,
                  size: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isBlocked
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : (isSelected
                          ? AppColors.dotaGoldLight
                          : AppColors.textSecondary),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
