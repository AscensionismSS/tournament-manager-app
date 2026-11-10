import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Opacidade do fundo do cartão (1.0 = sólido). Útil sobre imagens de fundo.
  final double backgroundOpacity;

  const AppCard({
    super.key,
    required this.child,
    this.backgroundOpacity = 1.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 28.0, vertical: 34.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const radius = BorderRadius.all(Radius.circular(18.0));

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: backgroundOpacity),
        borderRadius: radius,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 38,
            spreadRadius: 2,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}