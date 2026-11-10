import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Card de seleção e opção compartilhada (SRP).
/// Utilizado em Wizards, Diálogos e Formulários para opções visuais selecionáveis,
/// garantindo consistência de feedback visual, foco, estados ativo/inativo/desabilitado
/// e tipografia alinhada ao Design System.
class AppSelectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool disabled;
  final String? disabledTooltip;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final Widget? badge;

  const AppSelectCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.disabled = false,
    this.disabledTooltip,
    this.accentColor,
    this.padding,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.primaryNeon;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 12);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: disabled
            ? AppColors.surfaceHighlight.withValues(alpha: 0.3)
            : (isSelected
                ? effectiveAccent.withValues(alpha: 0.15)
                : AppColors.surfaceHighlight),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: disabled
              ? AppColors.border.withValues(alpha: 0.3)
              : (isSelected ? effectiveAccent : AppColors.border),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (badge != null) ...[
            Align(
              alignment: Alignment.topRight,
              child: badge!,
            ),
            const SizedBox(height: 4),
          ],
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: disabled
                  ? AppColors.onSurface.withValues(alpha: 0.25)
                  : (isSelected ? effectiveAccent : AppColors.onSurface),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              color: disabled
                  ? AppColors.onSurface.withValues(alpha: 0.25)
                  : (isSelected ? Colors.white : AppColors.onSurface),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: disabled
                    ? AppColors.onSurface.withValues(alpha: 0.2)
                    : (isSelected
                        ? AppColors.onSurface.withValues(alpha: 0.8)
                        : AppColors.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ],
      ),
    );

    if (disabled) {
      if (disabledTooltip != null && disabledTooltip!.isNotEmpty) {
        return Tooltip(
          message: disabledTooltip!,
          child: Opacity(
            opacity: 0.7,
            child: content,
          ),
        );
      }
      return Opacity(
        opacity: 0.7,
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: content,
    );
  }
}
