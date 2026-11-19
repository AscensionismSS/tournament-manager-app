import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../models/tournament_dto.dart';
import 'qualification_legend_dialog.dart';

/// Botão de ação unificado no cabeçalho das abas para abrir o modal de Regras & Formato.
/// Segue o padrão contornado suave com micro-hover dourado Aegis.
class TournamentRulesButton extends StatefulWidget {
  final TournamentDto tournament;
  final String label;
  final String tooltipMessage;

  const TournamentRulesButton({
    super.key,
    required this.tournament,
    this.label = 'REGRAS & FORMATO',
    this.tooltipMessage = 'Regras de Formato, Folga (BYE) & Classificação',
  });

  @override
  State<TournamentRulesButton> createState() => _TournamentRulesButtonState();
}

class _TournamentRulesButtonState extends State<TournamentRulesButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    return Tooltip(
      message: widget.tooltipMessage,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => QualificationLegendDialog.show(context, widget.tournament),
          borderRadius: BorderRadius.circular(5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 26,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 10,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.dotaGold.withValues(alpha: 0.16)
                  : AppColors.canvasSurface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _isHovered
                    ? AppColors.dotaGold.withValues(alpha: 0.70)
                    : AppColors.border.withValues(alpha: 0.75),
                width: 0.85,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: _isHovered
                      ? AppColors.dotaGoldLight
                      : AppColors.dotaGold.withValues(alpha: 0.85),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.45,
                      color: _isHovered
                          ? AppColors.dotaGoldLight
                          : Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
