import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Variantes visuais padronizadas da linha divisória da plataforma (SRP & DRY).
enum AppDividerVariant {
  /// Gradiente com acento Vermelho Arena no centro para separar seções de destaque.
  neon,

  /// Gradiente com acento Ouro Aegis no centro para elementos competitivos.
  gold,

  /// Linha neutra e sutil padrão [AppColors.border].
  subtle,
}

/// Linha divisória horizontal padronizada do Design System.
/// Centraliza todas as divisórias estéticas da aplicação, eliminando Containers ad-hoc duplicados.
class AppDivider extends StatelessWidget {
  final AppDividerVariant variant;
  final double thickness;
  final double height;
  final double indent;
  final double endIndent;

  const AppDivider({
    super.key,
    this.variant = AppDividerVariant.subtle,
    this.thickness = 1.0,
    this.height = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  /// Linha com brilho central Vermelho Arena
  const AppDivider.neon({
    super.key,
    this.thickness = 1.0,
    this.height = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  }) : variant = AppDividerVariant.neon;

  /// Linha com brilho central Ouro Aegis
  const AppDivider.gold({
    super.key,
    this.thickness = 1.0,
    this.height = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  }) : variant = AppDividerVariant.gold;

  /// Linha neutra e sutil
  const AppDivider.subtle({
    super.key,
    this.thickness = 1.0,
    this.height = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  }) : variant = AppDividerVariant.subtle;

  @override
  Widget build(BuildContext context) {
    Decoration? decoration;
    Color? solidColor;

    switch (variant) {
      case AppDividerVariant.neon:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.border.withValues(alpha: 0.15),
              AppColors.border.withValues(alpha: 0.75),
              AppColors.primaryNeon.withValues(alpha: 0.45),
              AppColors.border.withValues(alpha: 0.75),
              AppColors.border.withValues(alpha: 0.15),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        );
        break;

      case AppDividerVariant.gold:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.border.withValues(alpha: 0.15),
              AppColors.border.withValues(alpha: 0.75),
              AppColors.dotaGold.withValues(alpha: 0.45),
              AppColors.border.withValues(alpha: 0.75),
              AppColors.border.withValues(alpha: 0.15),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        );
        break;

      case AppDividerVariant.subtle:
        solidColor = AppColors.border;
        break;
    }

    Widget lineWidget = Container(
      height: thickness,
      decoration: decoration ?? BoxDecoration(color: solidColor),
    );

    if (indent > 0 || endIndent > 0) {
      lineWidget = Padding(
        padding: EdgeInsets.only(left: indent, right: endIndent),
        child: lineWidget,
      );
    }

    if (height > thickness) {
      return SizedBox(
        height: height,
        child: Center(child: lineWidget),
      );
    }

    return lineWidget;
  }
}
