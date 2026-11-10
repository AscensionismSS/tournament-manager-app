import 'package:flutter/material.dart';
import '../../../../../core/feedback/app_feedback.dart';
import '../../../../../core/shared_widgets/app_button.dart';
import '../../../../../core/shared_widgets/app_dialog.dart';
import '../../../../../core/shared_widgets/app_input.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../models/match_game_dto.dart';
import '../../../models/match_series_dto.dart';

/// Modal focado e enxuto para inserção ou edição manual de resultados essenciais do Game.
/// Envia apenas os dados consolidados exigidos pelo backend:
/// - Vencedor do mapa
/// - Duração em segundos
/// - Abates Time A e Time B
/// - First Pick (opcional)
class GameManualResultDialog extends StatefulWidget {
  final MatchSeriesDto series;
  final int gameNumber;
  final MatchGameDto? existingGame;

  const GameManualResultDialog({
    super.key,
    required this.series,
    required this.gameNumber,
    this.existingGame,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required MatchSeriesDto series,
    required int gameNumber,
    MatchGameDto? existingGame,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameManualResultDialog(
        series: series,
        gameNumber: gameNumber,
        existingGame: existingGame,
      ),
    );
  }

  @override
  State<GameManualResultDialog> createState() => _GameManualResultDialogState();
}

class _GameManualResultDialogState extends State<GameManualResultDialog> {
  final _formKey = GlobalKey<FormState>();

  late String? _selectedWinnerTeamId;
  late String? _selectedFirstPickTeamId;
  late final TextEditingController _durationController;
  late final TextEditingController _teamAKillsController;
  late final TextEditingController _teamBKillsController;

  @override
  void initState() {
    super.initState();
    final game = widget.existingGame;

    _selectedWinnerTeamId = game?.winnerTeamId ?? widget.series.teamAId;
    _selectedFirstPickTeamId = game?.firstPickTeamId ?? widget.series.teamAId;

    final durationSecs = game?.durationSeconds ?? 0;
    final mins = durationSecs ~/ 60;
    final secs = durationSecs % 60;
    final formattedDuration = durationSecs > 0
        ? '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
        : '35:00';

    _durationController = TextEditingController(text: formattedDuration);
    _teamAKillsController = TextEditingController(
      text: game != null ? '${game.teamAKills}' : '0',
    );
    _teamBKillsController = TextEditingController(
      text: game != null ? '${game.teamBKills}' : '0',
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _teamAKillsController.dispose();
    _teamBKillsController.dispose();
    super.dispose();
  }

  int _parseDurationToSeconds(String raw) {
    final clean = raw.trim();
    if (!clean.contains(':')) {
      final mins = int.tryParse(clean) ?? 0;
      return mins * 60;
    }
    final parts = clean.split(':');
    final mins = int.tryParse(parts[0]) ?? 0;
    final secs = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return (mins * 60) + secs;
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWinnerTeamId == null || _selectedWinnerTeamId!.isEmpty) {
      AppFeedback.showWarning(
        context,
        message: 'Por favor, selecione a equipe vencedora do mapa.',
      );
      return;
    }

    final durationSecs = _parseDurationToSeconds(_durationController.text);
    if (durationSecs <= 0) {
      AppFeedback.showWarning(
        context,
        message: 'A duração da partida deve ser maior que zero.',
      );
      return;
    }

    final killsA = int.tryParse(_teamAKillsController.text) ?? 0;
    final killsB = int.tryParse(_teamBKillsController.text) ?? 0;

    Navigator.of(context).pop({
      'winnerTeamId': _selectedWinnerTeamId,
      'firstPickTeamId': _selectedFirstPickTeamId,
      'durationSeconds': durationSecs,
      'teamAKills': killsA,
      'teamBKills': killsB,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGame != null;
    final teamA = widget.series.displayTeamA;
    final teamB = widget.series.displayTeamB;

    return AppDialog(
      title: isEditing
          ? 'Game #${widget.gameNumber} • Editar Dados'
          : 'Game #${widget.gameNumber} • Lançamento Rápido',
      icon: isEditing
          ? Icons.edit_note_rounded
          : Icons.add_circle_outline_rounded,
      maxWidth: 400,
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      onClose: () => Navigator.of(context).pop(),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Seleção da Equipe Vencedora
            const Text(
              'EQUIPE VENCEDORA DO MAPA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.dotaGoldLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTeamChoiceButton(
                    teamName: teamA,
                    teamId: widget.series.teamAId,
                    isSelected: _selectedWinnerTeamId == widget.series.teamAId,
                    onSelect: () => setState(
                      () => _selectedWinnerTeamId = widget.series.teamAId,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTeamChoiceButton(
                    teamName: teamB,
                    teamId: widget.series.teamBId,
                    isSelected: _selectedWinnerTeamId == widget.series.teamBId,
                    onSelect: () => setState(
                      () => _selectedWinnerTeamId = widget.series.teamBId,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Duração da Partida
            AppInput(
              controller: _durationController,
              labelText: 'Duração da Partida (MM:SS)',
              hintText: 'Ex: 35:40',
              prefixIcon: Icons.timer_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe a duração';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // 3. Abates (Kills) de cada equipe
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: _teamAKillsController,
                    labelText: 'Abates $teamA',
                    hintText: '0',
                    prefixIcon: Icons.sports_score_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Obrigatório';
                      if (int.tryParse(v) == null) return 'Inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppInput(
                    controller: _teamBKillsController,
                    labelText: 'Abates $teamB',
                    hintText: '0',
                    prefixIcon: Icons.sports_score_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Obrigatório';
                      if (int.tryParse(v) == null) return 'Inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. First Pick (Opcional)
            const Text(
              'FIRST PICK (PRIMEIRA ESCOLHA NO DRAFT)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildFpChoiceButton(
                    label: teamA,
                    teamId: widget.series.teamAId,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildFpChoiceButton(
                    label: teamB,
                    teamId: widget.series.teamBId,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildFpChoiceButton(
                    label: 'Nenhum',
                    teamId: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Botões de Ação
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancelar',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    text: isEditing ? 'Salvar Dados' : 'Confirmar',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                    onPressed: _onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamChoiceButton({
    required String teamName,
    required String? teamId,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.dotaGold.withValues(alpha: 0.18)
                : AppColors.canvasSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.dotaGold
                  : AppColors.border.withValues(alpha: 0.7),
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 15,
                color: isSelected
                    ? AppColors.dotaGoldLight
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFpChoiceButton({
    required String label,
    required String? teamId,
  }) {
    final isSelected = _selectedFirstPickTeamId == teamId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFirstPickTeamId = teamId),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryNeon.withValues(alpha: 0.15)
                : AppColors.canvasSurface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryNeon
                  : AppColors.border.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryNeon
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
