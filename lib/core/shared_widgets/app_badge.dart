import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppBadgeVariant { primary, success, error, warning, info, neutral }

/// Badge e Pílula de status compartilhada universalmente no Design System (SRP).
/// Garante tamanho fixo uniforme, tipografia nítida (Inter >= 11.5px) e cores semânticas de alto contraste.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final Color? customColor;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final double height;
  final double fontSize;
  final bool showDot;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.success,
    this.customColor,
    this.icon,
    this.leading,
    this.width,
    this.height = 24,
    this.fontSize = 11.5,
    this.showDot = false,
  });

  const AppBadge.pill({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.customColor,
    this.icon,
    this.leading,
    this.width,
    this.height = 26,
    this.fontSize = 11.5,
    this.showDot = false,
  });

  const AppBadge.dot({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.success,
    this.customColor,
    this.width,
    this.height = 24,
    this.fontSize = 11.5,
  })  : icon = null,
        leading = null,
        showDot = true;

  @override
  Widget build(BuildContext context) {
    final baseColor = customColor ?? _resolveColor();

    return Container(
      width: width,
      height: height,
      alignment: width != null ? Alignment.center : null,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ] else if (leading != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: leading!,
            ),
          ] else if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(
                icon,
                size: fontSize + 1.5,
                color: baseColor,
              ),
            ),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: baseColor,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveColor() {
    switch (variant) {
      case AppBadgeVariant.primary:
        return AppColors.primaryNeon;
      case AppBadgeVariant.success:
        return AppColors.success;
      case AppBadgeVariant.error:
        return AppColors.error;
      case AppBadgeVariant.warning:
        return AppColors.feedbackWarning;
      case AppBadgeVariant.info:
        return AppColors.secondaryNeon;
      case AppBadgeVariant.neutral:
        return AppColors.textSecondary;
    }
  }
}
