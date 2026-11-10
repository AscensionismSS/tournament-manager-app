import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/app_dialog.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../models/match_series_dto.dart';

enum GameResultType {
  replay,
  manual,
  walkover,
  undoLastGame,
  rollback,
}

/// Modal simples, limpo e direto para escolher como registrar ou editar o resultado do jogo.
/// Cada opção é um card espaçoso com ícone, título e ícone (i) de informação no canto.
class GameResultTypeDialog extends StatelessWidget {
  final MatchSeriesDto series;
  final int gameNumber;
  final bool isEditing;

  const GameResultTypeDialog({
    super.key,
    required this.series,
    required this.gameNumber,
    this.isEditing = false,
  });

  static Future<GameResultType?> show(
    BuildContext context, {
    required MatchSeriesDto series,
    required int gameNumber,
    bool isEditing = false,
  }) {
    return showDialog<GameResultType>(
      context: context,
      barrierDismissible: true,
      builder: (_) => GameResultTypeDialog(
        series: series,
        gameNumber: gameNumber,
        isEditing: isEditing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: isEditing
          ? 'Game #$gameNumber • Editar Resultado'
          : 'Game #$gameNumber • Enviar Resultado',
      icon: Icons.sports_esports_rounded,
      maxWidth: 420,
      onClose: () => Navigator.of(context).pop(),
      contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isEditing) ...[
            // 1. Opção: Replay (.dem)
            _buildOptionCard(
              context,
              type: GameResultType.replay,
              icon: Icons.upload_file_rounded,
              iconColor: AppColors.dotaGold,
              title: 'Enviar Replay (.dem)',
              infoTooltip:
                  'Parser automático de abates, heróis, itens e estatísticas de draft.',
            ),
            const SizedBox(height: 12),

            // 2. Opção: Lançamento Manual
            _buildOptionCard(
              context,
              type: GameResultType.manual,
              icon: Icons.edit_note_rounded,
              iconColor: AppColors.primaryNeon,
              title: 'Lançar Manualmente',
              infoTooltip:
                  'Preencha vencedor, duração e abates através de formulário rápido.',
            ),
            const SizedBox(height: 12),

            // 3. Opção: Declarar W.O.
            _buildOptionCard(
              context,
              type: GameResultType.walkover,
              icon: Icons.flag_rounded,
              iconColor: AppColors.feedbackWarning,
              title: 'Vitória por W.O.',
              infoTooltip:
                  'Atribua vitória por desistência ou ausência da equipe adversária.',
            ),
          ] else ...[
            // 1. Substituir por Replay (.dem)
            _buildOptionCard(
              context,
              type: GameResultType.replay,
              icon: Icons.upload_file_rounded,
              iconColor: AppColors.dotaGold,
              title: 'Substituir por Replay (.dem)',
              infoTooltip:
                  'Reprocessa o jogo via parser oficial, atualizando estatísticas ricas e chaveamento.',
            ),
            const SizedBox(height: 12),

            // 2. Edição Manual (Atualiza placar, abates e vencedor diretamente no backend)
            _buildOptionCard(
              context,
              type: GameResultType.manual,
              icon: Icons.edit_note_rounded,
              iconColor: AppColors.primaryNeon,
              title: 'Editar Dados Manualmente',
              infoTooltip:
                  'Altere o vencedor, duração e contagem de abates do Game #$gameNumber.',
            ),
            const SizedBox(height: 12),

            // 3. Aplicar / Editar W.O. no Mapa
            _buildOptionCard(
              context,
              type: GameResultType.walkover,
              icon: Icons.flag_rounded,
              iconColor: AppColors.feedbackWarning,
              title: 'Aplicar W.O. no Game #$gameNumber',
              infoTooltip:
                  'Define vitória por W.O. neste mapa específico e recalcula a pontuação.',
            ),

            if (series.games.isNotEmpty) ...[
              const SizedBox(height: 12),

              // 4. Desfazer Último Mapa
              _buildOptionCard(
                context,
                type: GameResultType.undoLastGame,
                icon: Icons.undo_rounded,
                iconColor: AppColors.textSecondary,
                title: 'Desfazer Último Mapa (Game #${series.games.length})',
                infoTooltip:
                    'Remove o último mapa registrado e reabre a série para novos envios.',
              ),
              const SizedBox(height: 12),

              // 5. Reverter Série Completa
              _buildOptionCard(
                context,
                type: GameResultType.rollback,
                icon: Icons.restart_alt_rounded,
                iconColor: AppColors.feedbackError,
                title: 'Reverter Série Completa',
                infoTooltip:
                    'Zera todos os jogos da série (0 x 0) e cancela progressões de chave.',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required GameResultType type,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String infoTooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(type),
        borderRadius: BorderRadius.circular(10),
        hoverColor: iconColor.withValues(alpha: 0.10),
        splashColor: iconColor.withValues(alpha: 0.18),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone temático limpo
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),

              // Título limpo e direto
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Ícone (i) no canto com tooltip explicativo
              Tooltip(
                message: infoTooltip,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.canvasSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Seta sutil de navegação
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
