import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/tournament_details_controller.dart';

/// Item individual de aba do campeonato em estilo transparente moderno com pill flutuante sutil e barra neon inferior (SRP).
class TournamentNavTabItem extends StatefulWidget {
  final TournamentDetailTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const TournamentNavTabItem({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<TournamentNavTabItem> createState() => _TournamentNavTabItemState();
}

class _TournamentNavTabItemState extends State<TournamentNavTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final Color textColor;

    if (isSelected) {
      bgColor = AppColors.primaryNeon.withValues(alpha: 0.12);
      borderColor = AppColors.primaryNeon.withValues(alpha: 0.85);
      iconColor = AppColors.primaryNeon;
      textColor = Colors.white;
    } else if (_isHovered) {
      bgColor = AppColors.surfaceHighlight.withValues(alpha: 0.45);
      borderColor = AppColors.border.withValues(alpha: 0.85);
      iconColor = Colors.white;
      textColor = Colors.white;
    } else {
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
      iconColor = AppColors.textSecondary.withValues(alpha: 0.75);
      textColor = AppColors.textSecondary.withValues(alpha: 0.80);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryNeon.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.tab.icon,
                size: 15,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.tab.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.6,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
