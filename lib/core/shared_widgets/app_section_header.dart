import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_divider.dart';

/// Cabeçalho padronizado de seções com ponto luminoso neon (ou ícone), título prioritário,
/// badge de contagem inteligente, linha divisória horizontal adaptativa e ação opcional no final (SRP).
/// Utiliza CustomMultiChildLayout para garantir alinhamento pixel-perfect e imunidade total a overflows.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? countLabel;
  final Widget? trailing;
  final Widget? icon;
  final Color? accentColor;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.countLabel,
    this.trailing,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final effectiveColor = accentColor ?? AppColors.primaryNeon;

    final titleStyle = textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: accentColor ?? colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: accentColor ?? AppColors.textPrimary,
        );

    final badgeStyle = textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          color: effectiveColor,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          color: effectiveColor,
        );

    final hasIcon = icon != null;
    final hasCount = countLabel != null;
    final hasTrailing = trailing != null;

    return SizedBox(
      height: 24,
      child: CustomMultiChildLayout(
        delegate: _AppSectionHeaderLayoutDelegate(
          hasIcon: hasIcon,
          hasCount: hasCount,
          hasTrailing: hasTrailing,
        ),
        children: [
          // 1. Indicador luminoso neon
          LayoutId(
            id: 'leading',
            child: Container(
              width: hasIcon ? 3.5 : 8,
              height: hasIcon ? 16 : 8,
              decoration: BoxDecoration(
                shape: hasIcon ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: hasIcon ? BorderRadius.circular(2) : null,
                color: effectiveColor,
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.6),
                    blurRadius: hasIcon ? 6 : 8,
                    spreadRadius: hasIcon ? 0.5 : 1,
                  ),
                ],
              ),
            ),
          ),

          // 2. Ícone opcional
          if (hasIcon)
            LayoutId(
              id: 'icon',
              child: icon!,
            ),

          // 3. Título com prioridade de exibição
          LayoutId(
            id: 'title',
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),

          // 4. Badge de contagem
          if (hasCount)
            LayoutId(
              id: 'badge',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: effectiveColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  countLabel!,
                  style: badgeStyle,
                ),
              ),
            ),

          // 5. Linha divisória adaptativa
          LayoutId(
            id: 'divider',
            child: const Center(
              child: AppDivider.subtle(),
            ),
          ),

          // 6. Trailing action opcional
          if (hasTrailing)
            LayoutId(
              id: 'trailing',
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

class _AppSectionHeaderLayoutDelegate extends MultiChildLayoutDelegate {
  final bool hasIcon;
  final bool hasCount;
  final bool hasTrailing;

  _AppSectionHeaderLayoutDelegate({
    required this.hasIcon,
    required this.hasCount,
    required this.hasTrailing,
  });

  @override
  void performLayout(Size size) {
    // 1. Layout Trailing (se presente) para saber onde termina a área útil
    double trailingWidth = 0.0;
    if (hasTrailing && hasChild('trailing')) {
      final trailingSize = layoutChild(
        'trailing',
        BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      );
      trailingWidth = trailingSize.width;
      positionChild(
        'trailing',
        Offset(size.width - trailingWidth, (size.height - trailingSize.height) / 2),
      );
    }

    // 2. Layout Indicador Neon
    double x = 0.0;
    if (hasChild('leading')) {
      final leadingSize = layoutChild(
        'leading',
        BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      );
      positionChild(
        'leading',
        Offset(0, (size.height - leadingSize.height) / 2),
      );
      x += leadingSize.width + 8.0;
    }

    // 3. Layout Ícone (se presente)
    if (hasIcon && hasChild('icon')) {
      final iconSize = layoutChild(
        'icon',
        BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      );
      positionChild(
        'icon',
        Offset(x, (size.height - iconSize.height) / 2),
      );
      x += iconSize.width + 8.0;
    }

    // 4. Layout Badge (se presente) para medição precisa de largura
    double badgeWidth = 0.0;
    Size badgeSize = Size.zero;
    if (hasCount && hasChild('badge')) {
      badgeSize = layoutChild(
        'badge',
        BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      );
      badgeWidth = badgeSize.width;
    }

    // 5. Cálculo do espaço horizontal para o Título
    final double rightBoundary =
        size.width - (trailingWidth > 0 ? trailingWidth + 12.0 : 0.0);
    final double badgeSpace = hasCount ? (badgeWidth + 10.0) : 0.0;
    final double maxTitleWidth =
        (rightBoundary - x - badgeSpace).clamp(0.0, size.width);

    // 6. Layout Título
    if (hasChild('title')) {
      final titleSize = layoutChild(
        'title',
        BoxConstraints(maxWidth: maxTitleWidth, maxHeight: size.height),
      );
      positionChild(
        'title',
        Offset(x, (size.height - titleSize.height) / 2),
      );
      x += titleSize.width;
    }

    // 7. Posiciona o Badge imediatamente após o Título
    if (hasCount && hasChild('badge')) {
      x += 10.0;
      positionChild(
        'badge',
        Offset(x, (size.height - badgeSize.height) / 2),
      );
      x += badgeWidth;
    }

    // 8. Linha divisória adaptativa no espaço restante
    final double remainingForDivider = rightBoundary - x - 14.0;
    if (hasChild('divider')) {
      if (remainingForDivider >= 20.0) {
        final dividerSize = layoutChild(
          'divider',
          BoxConstraints.tightFor(
            width: remainingForDivider,
            height: size.height,
          ),
        );
        positionChild(
          'divider',
          Offset(x + 14.0, (size.height - dividerSize.height) / 2),
        );
      } else {
        layoutChild(
          'divider',
          const BoxConstraints.tightFor(width: 0, height: 0),
        );
        positionChild('divider', Offset(x, 0));
      }
    }
  }

  @override
  bool shouldRelayout(covariant _AppSectionHeaderLayoutDelegate oldDelegate) {
    return oldDelegate.hasIcon != hasIcon ||
        oldDelegate.hasCount != hasCount ||
        oldDelegate.hasTrailing != hasTrailing;
  }
}
