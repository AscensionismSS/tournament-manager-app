import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';

/// Card/Tile modular para controle de trava de segurança individual (SRP).
class SecurityLockTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isMaintenance;

  const SecurityLockTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isMaintenance = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isMaintenance
        ? AppColors.feedbackWarning
        : AppColors.primaryNeon;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: value
                  ? activeColor.withValues(alpha: 0.15)
                  : AppColors.canvasSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value
                    ? activeColor.withValues(alpha: 0.45)
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? activeColor : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: value ? AppColors.textPrimary : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (value) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: activeColor.withValues(alpha: 0.50),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isMaintenance ? 'ATIVO' : 'BLOQUEADO',
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: 0.35),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.canvasSurface,
          ),
        ],
      ),
    );
  }
}
