import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../models/tournament_dto.dart';
import 'qualification_legend_dialog.dart';

/// Botão de ação unificado no cabeçalho das abas para abrir o modal de Regras & Formato.
class TournamentRulesButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    return Tooltip(
      message: tooltipMessage,
      child: InkWell(
        onTap: () => QualificationLegendDialog.show(context, tournament),
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 24,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.dotaGold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: AppColors.dotaGold.withValues(alpha: 0.38),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: AppColors.dotaGoldLight,
              ),
              if (!isMobile) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.dotaGoldLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
