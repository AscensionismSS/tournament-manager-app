import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/bracket_slot_dto.dart';
import '../../models/tournament_dto.dart';
import '../../controllers/tournament_details_controller.dart';
import '../../models/match_series_dto.dart';
import 'bracket_tree/bracket_tree_canvas.dart';
import 'playoff_matches_list_view.dart';
import 'tournament_rules_button.dart';

enum PlayoffBracketFilter { all, upper, lower, grandFinal }

enum PlayoffViewMode { tree, matches }

/// Aba 4: Playoffs & Chaveamento Esportivo do Campeonato (100% Dumb UI).
/// Suporta 2 modos oficiais de visualização:
/// 1. [PlayoffViewMode.tree] - Árvore Visual interativa (canvas com pan e zoom).
/// 2. [PlayoffViewMode.matches] - Lista de confrontos detalhados (com datas, G1-G3, upload de replays e filtros).
class TournamentPlayoffsTab extends StatefulWidget {
  final TournamentDto tournament;
  final TournamentDetailsController controller;
  final bool canManage;
  final void Function(MatchSeriesDto match, int gameIndex)? onRecordResult;
  final void Function(MatchSeriesDto match, int gameIndex)? onEditResult;
  final void Function(MatchSeriesDto match)? onAdminManage;

  const TournamentPlayoffsTab({
    super.key,
    required this.tournament,
    required this.controller,
    required this.canManage,
    this.onRecordResult,
    this.onEditResult,
    this.onAdminManage,
  });

  @override
  State<TournamentPlayoffsTab> createState() => _TournamentPlayoffsTabState();
}

class _TournamentPlayoffsTabState extends State<TournamentPlayoffsTab> {
  PlayoffViewMode _viewMode = PlayoffViewMode.tree;
  PlayoffBracketFilter _activeFilter = PlayoffBracketFilter.all;
  String? _initialListStageFilter;
  int? _initialListRoundFilter;
  int _listFilterRevision = 0;

  bool get _isDoubleElimination => widget.tournament.isDoubleElimination;

  @override
  Widget build(BuildContext context) {
    final slots = widget.tournament.bracketSlots;

    if (slots.isEmpty) {
      final availableHeight =
          (MediaQuery.sizeOf(context).height - 420).clamp(320.0, 720.0);
      return AppEmptyState(
        icon: Icons.account_tree_rounded,
        title: 'CHAVEAMENTO NÃO INICIADO',
        message:
            'Os confrontos de mata-mata dos playoffs serão gerados após a conclusão da fase anterior.',
        minHeight: availableHeight,
      );
    }

    // Mapeia partidas por SlotCode para acesso rápido e passivo
    final matchesByCode = {
      for (final m in widget.controller.matches) m.slotCode: m,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cabeçalho da Seção
        AppSectionHeader(
          title: 'CHAVEAMENTO DOS PLAYOFFS',
          countLabel:
              '${widget.tournament.playoffFormatLabel} • ${widget.tournament.playoffMdLabel}',
          trailing: TournamentRulesButton(
            tournament: widget.tournament,
            label: 'REGRAS & FORMATO',
            tooltipMessage: 'Regras de Classificação & Formato dos Playoffs',
          ),
        ),
        const SizedBox(height: 14),

        // 2. Menu / Barra de Botões de Visualização abaixo do cabeçalho (amplo e de alta legibilidade)
        _buildViewModeMenuBar(),
        const SizedBox(height: 16),

        // 3. Renderização Condicional pelo Modo de Visualização Escolhido
        if (_viewMode == PlayoffViewMode.matches) ...[
          // MODO LISTA DE PARTIDAS: Cards estruturados, filtros e datas
          PlayoffMatchesListView(
            key: ValueKey('playoff_list_$_listFilterRevision'),
            tournament: widget.tournament,
            slots: slots,
            matches: widget.controller.matches,
            canManage: widget.canManage,
            draftTeams: widget.controller.draftSnapshot?.teams,
            initialStage: _initialListStageFilter,
            initialRound: _initialListRoundFilter,
            onRecordResult: widget.onRecordResult,
            onEditResult: widget.onEditResult,
            onAdminManage: widget.onAdminManage,
          ),
        ] else ...[
          // MODO CHAVEAMENTO VISUAL: Árvore interativa com zoom e pan
          if (_activeFilter == PlayoffBracketFilter.all) ...[
            // ÁRVORE UNIFICADA DE E-SPORTS: Upper + Lower + Grande Final conectada
            BracketTreeCanvas(
              slots: slots,
              matchesByCode: matchesByCode,
              stageName: 'TODAS',
              activeLineColor: AppColors.dotaGold,
              onSeriesTap: _onSeriesTap,
            ),
          ] else if (_activeFilter == PlayoffBracketFilter.upper) ...[
            _buildStageSection(
              title: _isDoubleElimination
                  ? 'CHAVE SUPERIOR (UPPER BRACKET)'
                  : 'MATA-MATA PRINCIPAL',
              icon: Icons.keyboard_double_arrow_up_rounded,
              accentColor: AppColors.feedbackSuccess,
              stageSlots: slots.where((s) => s.stage == 'Upper').toList(),
              matchesByCode: matchesByCode,
            ),
          ] else if (_activeFilter == PlayoffBracketFilter.lower) ...[
            _buildStageSection(
              title: 'CHAVE INFERIOR & REPESCAGEM (LOWER BRACKET)',
              icon: Icons.keyboard_arrow_right_rounded,
              accentColor: AppColors.primaryNeon,
              stageSlots: slots
                  .where((s) => s.stage == 'Lower' || s.stage == 'PlayIn')
                  .toList(),
              matchesByCode: matchesByCode,
            ),
          ] else if (_activeFilter == PlayoffBracketFilter.grandFinal) ...[
            _buildGrandFinalSection(
              slots.where((s) => s.stage == 'GrandFinal').toList(),
              matchesByCode,
            ),
          ],
        ],
      ],
    );
  }

  /// Menu de navegação abaixo do cabeçalho com 2 botões grandes e legíveis (Chaveamento x Lista de Partidas)
  /// + filtros rápidos de chave quando no modo Árvore.
  Widget _buildViewModeMenuBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 2 Botões Principais de Modo de Visualização (42px de altura, fonte 12.5px branca/dourada nítida)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildViewModeButton(
                mode: PlayoffViewMode.tree,
                label: 'CHAVEAMENTO (ÁRVORE)',
                icon: Icons.account_tree_rounded,
              ),
              _buildViewModeButton(
                mode: PlayoffViewMode.matches,
                label: 'LISTA DE PARTIDAS',
                icon: Icons.format_list_bulleted_rounded,
              ),
            ],
          ),

          // Filtros de Chave (quando na visualização de Árvore em Eliminatória Dupla)
          if (_viewMode == PlayoffViewMode.tree && _isDoubleElimination)
            _buildFilterTabs(),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required PlayoffViewMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _viewMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          if (mode == PlayoffViewMode.matches && _viewMode != mode) {
            _initialListStageFilter = null;
            _initialListRoundFilter = null;
            _listFilterRevision++;
          }
          _viewMode = mode;
        }),
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.dotaGold.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.dotaGold.withValues(alpha: 0.18)
                : AppColors.canvasSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.dotaGold
                  : AppColors.border.withValues(alpha: 0.8),
              width: isSelected ? 1.3 : 0.9,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.dotaGold.withValues(alpha: 0.15),
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
                icon,
                size: 17,
                color: isSelected
                    ? AppColors.dotaGoldLight
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSeriesTap(BracketSlotDto slot, MatchSeriesDto? match) {
    final targetStage =
        (slot.stage == 'Lower' || slot.stage == 'PlayIn') ? 'Lower' : slot.stage;

    setState(() {
      _initialListStageFilter = targetStage;
      _initialListRoundFilter = slot.round;
      _listFilterRevision++;
      _viewMode = PlayoffViewMode.matches;
    });
  }

  Widget _buildFilterTabs() {
    final filters = [
      (PlayoffBracketFilter.all, 'TODAS AS CHAVES', Icons.grid_view_rounded),
      (
        PlayoffBracketFilter.upper,
        'UPPER BRACKET',
        Icons.keyboard_double_arrow_up_rounded
      ),
      (
        PlayoffBracketFilter.lower,
        'LOWER BRACKET',
        Icons.keyboard_arrow_right_rounded
      ),
      (
        PlayoffBracketFilter.grandFinal,
        'GRANDE FINAL',
        Icons.emoji_events_rounded
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _activeFilter = f.$1),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryNeon.withValues(alpha: 0.16)
                      : AppColors.canvasSurface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primaryNeon : AppColors.border,
                    width: isSelected ? 1.1 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.$3,
                      size: 15,
                      color: isSelected
                          ? AppColors.primaryNeon
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStageSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<BracketSlotDto> stageSlots,
    required Map<String, MatchSeriesDto> matchesByCode,
  }) {
    if (stageSlots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da Chave (limpo, sem subtítulo)
        Row(
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Canvas Dinâmico com Árvore Geométrica e Linhas Conectoras
        BracketTreeCanvas(
          slots: stageSlots,
          matchesByCode: matchesByCode,
          stageName: title,
          activeLineColor: accentColor,
          onSeriesTap: _onSeriesTap,
        ),
      ],
    );
  }

  Widget _buildGrandFinalSection(
    List<BracketSlotDto> gfSlots,
    Map<String, MatchSeriesDto> matchesByCode,
  ) {
    if (gfSlots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da Grande Final (limpo, sem subtítulo)
        const Row(
          children: [
            Icon(Icons.emoji_events_rounded,
                size: 18, color: AppColors.dotaGold),
            SizedBox(width: 8),
            Text(
              'GRANDE FINAL & TROFÉU DO CAMPEÃO',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.dotaGoldLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Canvas com Grande Final conectada ao Troféu Aegis Tsurus
        BracketTreeCanvas(
          slots: gfSlots,
          matchesByCode: matchesByCode,
          stageName: 'GRANDE FINAL',
          activeLineColor: AppColors.dotaGold,
          onSeriesTap: _onSeriesTap,
        ),
      ],
    );
  }
}
