import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../models/bracket_slot_dto.dart';
import '../../../models/match_series_dto.dart';
import '../playoff_series_card.dart';
import 'aegis_champion_card.dart';
import 'bracket_tree_layout.dart';
import 'bracket_tree_painter.dart';

/// Canvas Interativo Livre e Reativo da Árvore de Chaveamento.
/// Suporta arrasto livre com o mouse (Pan 2D), zoom suave sem reconstruir os cards (GPU Matrix),
/// ajuste automático à largura da tela e controles flutuantes integrados.
class BracketTreeCanvas extends StatefulWidget {
  final List<BracketSlotDto> slots;
  final Map<String, MatchSeriesDto> matchesByCode;
  final String? stageName;
  final Color activeLineColor;
  final void Function(BracketSlotDto slot, MatchSeriesDto? match)? onSeriesTap;

  const BracketTreeCanvas({
    super.key,
    required this.slots,
    required this.matchesByCode,
    this.stageName,
    this.activeLineColor = AppColors.dotaGold,
    this.onSeriesTap,
  });

  @override
  State<BracketTreeCanvas> createState() => _BracketTreeCanvasState();
}

class _BracketTreeCanvasState extends State<BracketTreeCanvas> {
  static const _engine = BracketTreeLayoutEngine(
    cardWidth: 280.0,
    cardHeight: 120.0,
    columnGap: 44.0,
    baseRowGap: 24.0,
  );

  late final TransformationController _transformationController;
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier<bool>(false);
  BracketTreeLayoutResult? _cachedLayout;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _recomputeLayoutIfNeeded();
  }

  @override
  void didUpdateWidget(covariant BracketTreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool stageChanged = oldWidget.stageName != widget.stageName;
    if (stageChanged) {
      // Ao trocar de filtro de chave (ex: TODAS -> GRANDE FINAL), reseta a matriz 2D
      // para evitar que uma chave menor fique deslocada para fora da tela.
      _transformationController.value = Matrix4.identity();
    }
    if (stageChanged ||
        !listEquals(oldWidget.slots, widget.slots) ||
        !mapEquals(oldWidget.matchesByCode, widget.matchesByCode)) {
      _cachedLayout = null;
      _recomputeLayoutIfNeeded();
    }
  }

  void _recomputeLayoutIfNeeded() {
    if (widget.slots.isEmpty) {
      _cachedLayout = null;
      return;
    }
    _cachedLayout ??= _engine.computeLayout(
      slots: widget.slots,
      matchesByCode: widget.matchesByCode,
      stageName: widget.stageName,
    );
  }

  @override
  void dispose() {
    _isDraggingNotifier.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final matrix = _transformationController.value.clone();
    // A escala 2D real no plano XY está armazenada em storage[0]
    final currentScale = matrix.storage[0];
    final newScale = (currentScale * factor).clamp(0.9, 1.8);
    if ((newScale - currentScale).abs() < 0.001) return;

    final scaleChange = newScale / currentScale;
    matrix.scaleByDouble(scaleChange, scaleChange, scaleChange, 1.0);
    _transformationController.value = matrix;
  }

  void _zoomIn() => _zoom(1.15);
  void _zoomOut() => _zoom(0.87);

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  void _fitToWidth(double totalWidth, double availableWidth) {
    if (totalWidth <= 0 || availableWidth <= 0) return;
    // O zoom nunca pode ser menor que 90% (0.90)
    final double targetScale =
        ((availableWidth - 48.0) / totalWidth).clamp(0.9, 1.0);
    _transformationController.value =
        Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slots.isEmpty) return const SizedBox.shrink();

    _recomputeLayoutIfNeeded();
    final layout = _cachedLayout!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.sizeOf(context).height;
        final isDesktop = availableWidth >= 900;

        final double contentHeight = layout.totalHeight + 52.0;
        final double totalChildHeight = contentHeight + 28.0;
        const double controlBarHeight = 44.0;
        final double viewportHeight = isDesktop
            ? (totalChildHeight + controlBarHeight)
            : math.min(totalChildHeight + controlBarHeight,
                math.max(480.0, screenHeight * 0.72));

        final Widget bracketContent = RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 24, 16),
            child: SizedBox(
              width: layout.totalWidth,
              height: contentHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A) Cabeçalhos das Colunas de Rodadas
                  _buildColumnHeaders(layout),
                  const SizedBox(height: 12),

                  // B) O Canvas com Linhas no Fundo e Cards na Frente
                  SizedBox(
                    width: layout.totalWidth,
                    height: layout.totalHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Camada de Fundo: Linhas Conectoras Curvas (CustomPainter na GPU)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: BracketTreePainter(
                              connections: layout.connections,
                              defaultLineColor: AppColors.border,
                              activeLineColor: widget.activeLineColor,
                            ),
                          ),
                        ),

                        // Banners de Identificação de Etapa no Canvas
                        for (final banner in layout.stageBanners)
                          Positioned(
                            left: banner.x,
                            top: banner.y,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(banner.icon,
                                    size: 15, color: banner.color),
                                const SizedBox(width: 6),
                                Text(
                                  banner.title,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: banner.color,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Camada Superior: Cards Interativos
                        for (final node in layout.nodes)
                          Positioned(
                            left: node.x,
                            top: node.y,
                            width: node.width,
                            child: PlayoffSeriesCard(
                              slot: node.slot,
                              match: node.match,
                              onTap: widget.onSeriesTap != null
                                  ? () => widget.onSeriesTap!(
                                      node.slot, node.match)
                                  : null,
                            ),
                          ),

                        // Camada do Troféu: Card do Campeão (Aegis Tsurus)
                        if (layout.championNode != null)
                          Positioned(
                            left: layout.championNode!.x,
                            top: layout.championNode!.y,
                            width: layout.championNode!.width,
                            child: AegisChampionCard(
                              node: layout.championNode!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return Container(
          width: double.infinity,
          height: viewportHeight,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra Reservada Fixa Superior de Navegação e Zoom (Espaço dedicado sem sobreposição)
              _buildDedicatedControlBar(
                totalWidth: layout.totalWidth,
                availableWidth: availableWidth,
                isMobile: !isDesktop,
              ),

              // 2. O Canvas Livre com Pan 2D (zero rebuilds da árvore durante o arrasto!)
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isDraggingNotifier,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.9,
                    maxScale: 1.8,
                    panEnabled: true,
                    scaleEnabled:
                        false, // Desativa zoom na rodinha do mouse para não conflitar com o scroll da página
                    boundaryMargin: EdgeInsets
                        .zero, // Limite estrito: trava na borda do 1º card e no final do último card
                    constrained: false,
                    onInteractionStart: (_) {
                      if (!_isDraggingNotifier.value) {
                        _isDraggingNotifier.value = true;
                      }
                    },
                    onInteractionEnd: (_) {
                      if (_isDraggingNotifier.value) {
                        _isDraggingNotifier.value = false;
                      }
                    },
                    child: bracketContent,
                  ),
                  builder: (context, isDragging, viewerChild) {
                    return MouseRegion(
                      cursor: isDragging
                          ? SystemMouseCursors.grabbing
                          : SystemMouseCursors.grab,
                      child: viewerChild,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDedicatedControlBar({
    required double totalWidth,
    required double availableWidth,
    required bool isMobile,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navSurface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Dica tátil de navegação
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pan_tool_alt_rounded,
                size: 14,
                color: AppColors.dotaGoldLight,
              ),
              const SizedBox(width: 8),
              const Text(
                'CHAVEAMENTO INTERATIVO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.dotaGoldLight,
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                const Text(
                  '•',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Arraste para mover pelo canvas',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Bloco de Controles de Zoom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.9),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom Out (-)
                AppIconButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Afastar (Zoom -)',
                  onPressed: _zoomOut,
                  size: AppIconButtonSize.compact,
                  variant: AppIconButtonVariant.ghost,
                ),

                // Reset (100%) - Atualiza isoladamente sem reconstruir o canvas
                Tooltip(
                  message: 'Tamanho original (100%)',
                  child: InkWell(
                    onTap: _resetView,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: ValueListenableBuilder<Matrix4>(
                        valueListenable: _transformationController,
                        builder: (context, matrix, _) {
                          final scalePct = (matrix.storage[0] * 100).round();
                          return Text(
                            '$scalePct%',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Zoom In (+)
                AppIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Aproximar (Zoom +)',
                  onPressed: _zoomIn,
                  size: AppIconButtonSize.compact,
                  variant: AppIconButtonVariant.ghost,
                ),

                Container(
                  width: 1,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: AppColors.border,
                ),

                // Ajustar à Largura da Tela
                AppIconButton(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'Ajustar chave completa na tela',
                  onPressed: () => _fitToWidth(totalWidth, availableWidth),
                  size: AppIconButtonSize.compact,
                  variant: AppIconButtonVariant.ghost,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders(BracketTreeLayoutResult layout) {
    final sortedCols = layout.columnTitles.keys.toList()..sort();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: sortedCols.map((colIndex) {
        final title = layout.columnTitles[colIndex] ?? 'RODADA ${colIndex + 1}';
        final slotsInCol =
            layout.nodes.where((n) => n.column == colIndex).length;
        final isChampion = title.toUpperCase().contains('CAMPEÃO');
        final isGrandFinal = title.toUpperCase().contains('GRANDE FINAL');
        final isPlayIn = title.toUpperCase().contains('PLAY-IN');

        Color? accentColor;
        if (isChampion || isGrandFinal) {
          accentColor = AppColors.dotaGold;
        } else if (isPlayIn) {
          accentColor = AppColors.feedbackWarning;
        }

        final badgeLabel = isChampion
            ? '1 TROFÉU'
            : '$slotsInCol ${slotsInCol == 1 ? "SÉRIE" : "SÉRIES"}';

        return Container(
          width: isChampion ? 280.0 : 260.0,
          margin: EdgeInsets.only(
            right: colIndex == sortedCols.last
                ? 0
                : (colIndex + 1 == sortedCols.last &&
                        layout.championNode != null
                    ? 76.0
                    : 44.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor != null
                ? accentColor.withValues(alpha: 0.08)
                : AppColors.surfaceHighlight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: accentColor != null
                  ? accentColor.withValues(alpha: 0.45)
                  : AppColors.border,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: accentColor ?? AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              AppBadge(
                label: badgeLabel,
                variant: AppBadgeVariant.neutral,
                customColor: accentColor,
                height: 17,
                fontSize: 8.5,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
