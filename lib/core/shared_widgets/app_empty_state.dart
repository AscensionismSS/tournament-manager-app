import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Componente centralizado para exibição de telas vazias, sem dados do backend
/// ou abas ainda sem conteúdo (SRP).
/// Evita a criação de arquivos de tela descartáveis/placeholders duplicados.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final Widget? customAction;
  final bool asCard;
  final double? minHeight;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.actionIcon,
    this.customAction,
    this.asCard = false,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.22),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 44,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title.toUpperCase(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (customAction != null) ...[
          const SizedBox(height: 24),
          customAction!,
        ] else if (actionLabel != null && onActionPressed != null) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onActionPressed,
            icon: Icon(actionIcon ?? Icons.refresh_rounded, size: 18),
            label: Text(actionLabel!),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );

    if (asCard) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: content,
      );
    }

    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 360.0),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: content,
    );
  }
}
