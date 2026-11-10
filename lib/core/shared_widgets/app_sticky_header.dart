import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Componente de cabeçalho persistente (Sticky Header) para tabelas e listas longas.
/// Evita o erro gravíssimo de "Perda de Contexto na Rolagem" (Loss of Context on Scroll),
/// mantendo colunas, filtros ou barras de ação fixas no topo com efeito frosted-glass esportivo.
class AppStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color? backgroundColor;
  final bool showBottomBorder;

  AppStickyHeaderDelegate({
    required this.child,
    this.height = 48.0,
    this.backgroundColor,
    this.showBottomBorder = true,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = backgroundColor ?? AppColors.navSurface.withValues(alpha: 0.95);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: bg,
            border: showBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.8),
                      width: 1.0,
                    ),
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant AppStickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showBottomBorder != showBottomBorder;
  }
}

/// Helper para instanciar rapidamente um SliverPersistentHeader com [AppStickyHeaderDelegate].
class AppSliverStickyHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final Color? backgroundColor;
  final bool showBottomBorder;

  const AppSliverStickyHeader({
    super.key,
    required this.child,
    this.height = 48.0,
    this.backgroundColor,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: AppStickyHeaderDelegate(
        child: child,
        height: height,
        backgroundColor: backgroundColor,
        showBottomBorder: showBottomBorder,
      ),
    );
  }
}
