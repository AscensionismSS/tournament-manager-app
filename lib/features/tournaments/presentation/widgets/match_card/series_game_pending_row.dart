import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';

/// Sub-widget SRP para exibir a linha de mapa quando a partida ainda não foi iniciada.
/// Possui exatamente a mesma altura física (62.5px) da linha de jogo disputada,
/// evitando layout shift e mantendo o alinhamento pixel-perfect do card.
/// Quando visualizado por um Administrador, oferece micro-hover sutil no padrão Dark/Aegis
/// para registrar o resultado do mapa diretamente.
class SeriesGamePendingRow extends StatefulWidget {
  final int gameIndex;
  final bool isAdmin;
  final bool isSeriesCompleted;
  final bool isLocked;
  final void Function(int gameIndex)? onTap;

  const SeriesGamePendingRow({
    super.key,
    required this.gameIndex,
    this.isAdmin = false,
    this.isSeriesCompleted = false,
    this.isLocked = false,
    this.onTap,
  });

  @override
  State<SeriesGamePendingRow> createState() => _SeriesGamePendingRowState();
}

class _SeriesGamePendingRowState extends State<SeriesGamePendingRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isNotNeeded = widget.isSeriesCompleted;
    final isLocked = widget.isLocked;
    final canInteract = !isNotNeeded && widget.isAdmin && widget.onTap != null;
    final isHovered = _isHovered && canInteract;

    final String displayLabel = isNotNeeded
        ? 'PARTIDA NÃO NECESSÁRIA (SÉRIE DECIDIDA)'
        : (isLocked
            ? (isHovered
                ? 'ENVIO SUSPENSO (CLIQUE P/ MOTIVO)'
                : 'RESULTADOS BLOQUEADOS')
            : (isHovered ? 'ENVIAR RESULTADO' : 'PARTIDA AINDA NÃO INICIADA'));
    final IconData displayIcon = isNotNeeded
        ? Icons.check_circle_outline_rounded
        : (isLocked
            ? Icons.lock_clock_rounded
            : (isHovered ? Icons.edit_note_rounded : Icons.schedule_rounded));

    final child = Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6.0),
      decoration: BoxDecoration(
        color: isNotNeeded
            ? AppColors.canvasSurface.withValues(alpha: 0.45)
            : (isHovered
                ? AppColors.surfaceHighlight.withValues(alpha: 0.50)
                : AppColors.canvasSurface.withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNotNeeded
              ? AppColors.border.withValues(alpha: 0.40)
              : (isLocked
                  ? AppColors.feedbackWarning
                      .withValues(alpha: isHovered ? 0.65 : 0.35)
                  : (isHovered
                      ? AppColors.dotaGold.withValues(alpha: 0.45)
                      : AppColors.borderHighlight.withValues(alpha: 0.65))),
          width: isNotNeeded ? 1.0 : 1.5,
        ),
      ),
      child: SizedBox(
        height: 50.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Identificador do mapa (G1, G2, etc.) na extrema esquerda
            SizedBox(
              width: 22,
              child: Text(
                'G${widget.gameIndex}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isNotNeeded
                      ? AppColors.textSecondary.withValues(alpha: 0.40)
                      : (isLocked
                          ? AppColors.feedbackWarning
                          : (isHovered
                              ? AppColors.dotaGoldLight
                              : AppColors.textSecondary.withValues(alpha: 0.65))),
                ),
              ),
            ),
            const SizedBox(width: 3),

            // Centro: Conteúdo contextual harmônico
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    displayIcon,
                    size: 14.5,
                    color: isNotNeeded
                        ? AppColors.textSecondary.withValues(alpha: 0.40)
                        : (isLocked
                            ? AppColors.feedbackWarning
                            : (isHovered
                                ? AppColors.dotaGoldLight
                                : AppColors.textSecondary.withValues(alpha: 0.55))),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isNotNeeded
                            ? AppColors.textSecondary.withValues(alpha: 0.45)
                            : (isLocked
                                ? AppColors.feedbackWarning
                                : (isHovered
                                    ? AppColors.dotaGoldLight
                                    : AppColors.textSecondary
                                        .withValues(alpha: 0.70))),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Espaçador para espelhar a simetria exata de 22px + 3px
            const SizedBox(width: 25),
          ],
        ),
      ),
    );

    if (!canInteract) return child;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap!(widget.gameIndex),
        child: child,
      ),
    );
  }
}
