import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Utilitário e componentes oficiais para padronização de layout e enquadramento de telas (SRP & DRY).
/// Centraliza o padrão de container ergonômico (maxWidth: 1380) e Sticky Headers com sombra de scroll.
class AppPageLayout {
  /// Largura máxima canônica recomendada para telas amplas (ergonomia de leitura e consistência visual).
  static const double maxContentWidth = 1380.0;

  /// Calcula o padding horizontal responsivo centralizando o conteúdo em telas maiores.
  static double horizontalPadding(
    BuildContext context, {
    double? baseSidePadding,
    double maxWidth = maxContentWidth,
  }) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isMobile = screenWidth < 540;
    final double base = baseSidePadding ?? (isMobile ? 16.0 : 28.0);
    final double effectiveMaxWidth = math.min(screenWidth, maxWidth);
    final double extraHorizontalMargin =
        math.max(0.0, (screenWidth - effectiveMaxWidth) / 2.0);
    return base + extraHorizontalMargin;
  }

  /// Calcula a largura líquida disponível para o conteúdo após a dedução dos paddings laterais.
  static double availableWidth(
    BuildContext context, {
    double? baseSidePadding,
    double maxWidth = maxContentWidth,
  }) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double padding = horizontalPadding(
      context,
      baseSidePadding: baseSidePadding,
      maxWidth: maxWidth,
    );
    return screenWidth - (padding * 2);
  }
}

/// Container oficial para Cabeçalhos e Barras de Busca Fixas no topo da página (Sticky Header).
/// Exibe borda e elevação/sombra suaves automaticamente ao rolar a página para baixo.
class AppPageStickyBar extends StatelessWidget {
  final bool isScrolled;
  final double horizontalPadding;
  final Widget child;
  final EdgeInsetsGeometry? customPadding;

  const AppPageStickyBar({
    super.key,
    required this.isScrolled,
    required this.horizontalPadding,
    required this.child,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: isScrolled
                ? AppColors.border.withValues(alpha: 0.85)
                : AppColors.border.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: customPadding ??
          EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            14,
          ),
      child: child,
    );
  }
}
