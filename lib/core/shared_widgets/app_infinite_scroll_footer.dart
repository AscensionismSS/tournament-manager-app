import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Rodapé padronizado e reutilizável para paginação progressiva (Infinite Scroll).
/// - Evita animação contínua de GPU (`CircularProgressIndicator`) quando ocioso (`!isLoadingMore`).
/// - Oferece fallback clicável (`onLoadMore`) caso a rolagem não seja suficiente em telas amplas.
class AppInfiniteScrollFooter extends StatelessWidget {
  final bool hasMore;
  final bool isLoadingMore;
  final bool showCompletedLabel;
  final String loadingLabel;
  final String idleLoadMoreLabel;
  final String completedLabel;
  final double horizontalPadding;
  final VoidCallback onLoadMore;

  const AppInfiniteScrollFooter({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.showCompletedLabel,
    required this.loadingLabel,
    required this.idleLoadMoreLabel,
    required this.completedLabel,
    required this.horizontalPadding,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (hasMore) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 32),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoadingMore ? null : onLoadMore,
                borderRadius: BorderRadius.circular(20),
                hoverColor: AppColors.primaryNeon.withValues(alpha: 0.08),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoadingMore)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryNeon,
                          ),
                        )
                      else
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 16,
                          color: AppColors.primaryNeon,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        isLoadingMore ? loadingLabel : idleLoadMoreLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (showCompletedLabel) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 32),
          child: Center(
            child: Text(
              completedLabel,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox(height: 16));
  }
}
