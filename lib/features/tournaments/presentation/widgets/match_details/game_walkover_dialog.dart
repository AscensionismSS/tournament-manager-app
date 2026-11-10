import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/app_button.dart';
import '../../../../../core/shared_widgets/app_dialog.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../models/match_series_dto.dart';

/// Modal para declarar vitória por W.O. selecionando a equipe vencedora.
class GameWalkoverDialog extends StatefulWidget {
  final MatchSeriesDto series;
  final int gameNumber;

  const GameWalkoverDialog({
    super.key,
    required this.series,
    required this.gameNumber,
  });

  static Future<String?> show(
    BuildContext context, {
    required MatchSeriesDto series,
    required int gameNumber,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => GameWalkoverDialog(
        series: series,
        gameNumber: gameNumber,
      ),
    );
  }

  @override
  State<GameWalkoverDialog> createState() => _GameWalkoverDialogState();
}

class _GameWalkoverDialogState extends State<GameWalkoverDialog> {
  String? _selectedWinnerId;

  @override
  void initState() {
    super.initState();
    _selectedWinnerId = widget.series.teamAId;
  }

  @override
  Widget build(BuildContext context) {
    final teamAId = widget.series.teamAId ?? '';
    final teamBId = widget.series.teamBId ?? '';

    return AppDialog(
      title: 'Game #${widget.gameNumber} • Aplicar W.O.',
      icon: Icons.flag_rounded,
      maxWidth: 400,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Selecione a equipe que receberá a vitória por W.O. neste mapa:',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Opção Time A
          _buildTeamRadio(
            teamId: teamAId,
            teamName: widget.series.displayTeamA,
          ),
          const SizedBox(height: 10),

          // Opção Time B
          _buildTeamRadio(
            teamId: teamBId,
            teamName: widget.series.displayTeamB,
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(),
                size: AppButtonSize.medium,
                variant: AppButtonVariant.ghost,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Confirmar W.O.',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _selectedWinnerId != null
                    ? () => Navigator.of(context).pop(_selectedWinnerId)
                    : null,
                size: AppButtonSize.medium,
                variant: AppButtonVariant.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamRadio({
    required String teamId,
    required String teamName,
  }) {
    final isSelected = _selectedWinnerId == teamId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedWinnerId = teamId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryNeon.withValues(alpha: 0.10)
                : AppColors.surfaceHighlight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryNeon.withValues(alpha: 0.8)
                  : AppColors.border,
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: isSelected
                    ? AppColors.primaryNeon
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: AppColors.dotaGold,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

