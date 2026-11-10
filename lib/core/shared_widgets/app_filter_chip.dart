import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Pílula / Chip de filtro padronizada para filtros e seletores (SRP).
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? activeColor;
  final int? count;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.activeColor,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? AppColors.primaryNeon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.18)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? effectiveColor : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? effectiveColor : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? effectiveColor : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? effectiveColor.withValues(alpha: 0.25)
                        : AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? effectiveColor : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
