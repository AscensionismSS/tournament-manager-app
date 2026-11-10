import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../../draft/models/draft_team_dto.dart';
import '../../models/bracket_slot_dto.dart';
import '../../models/match_series_dto.dart';
import '../../models/tournament_dto.dart';
import 'match_details/game_detail_dialog.dart';
import 'tournament_series_card.dart';

/// Item estruturado de confronto dos playoffs que associa o slot da chave com a série real ou placeholder.
class _PlayoffMatchItem {
  final BracketSlotDto slot;
  final MatchSeriesDto match;
  final bool isRealMatch;

  const _PlayoffMatchItem({
    required this.slot,
    required this.match,
    required this.isRealMatch,
  });

  String get stage => slot.stage;
  int get round => slot.round;
}

/// Visualização em lista dos confrontos de playoffs (Playoff Matches View).
/// Permite visualizar todas as séries do mata-mata agrupadas por fase e rodada,
/// com filtros canônicos de Fase, Rodada, Status e busca rápida por equipe.
class PlayoffMatchesListView extends StatefulWidget {
  final TournamentDto tournament;
  final List<BracketSlotDto> slots;
  final List<MatchSeriesDto> matches;
  final bool canManage;
  final List<DraftTeamDto>? draftTeams;
  final String? initialStage;
  final int? initialRound;
  final void Function(MatchSeriesDto match, int gameIndex)? onRecordResult;
  final void Function(MatchSeriesDto match, int gameIndex)? onEditResult;
  final void Function(MatchSeriesDto match)? onAdminManage;

  const PlayoffMatchesListView({
    super.key,
    required this.tournament,
    required this.slots,
    required this.matches,
    required this.canManage,
    this.draftTeams,
    this.initialStage,
    this.initialRound,
    this.onRecordResult,
    this.onEditResult,
    this.onAdminManage,
  });

  @override
  State<PlayoffMatchesListView> createState() => _PlayoffMatchesListViewState();
}

class _PlayoffMatchesListViewState extends State<PlayoffMatchesListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStage;
  int? _selectedRound;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.initialStage;
    _selectedRound = widget.initialRound;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedStage != null ||
      _selectedRound != null ||
      _selectedStatus != null;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStage = null;
      _selectedRound = null;
      _selectedStatus = null;
    });
  }

  /// Constrói os itens pareados de slot + partida (real ou sintética caso a série ainda não tenha sido gerada)
  List<_PlayoffMatchItem> _buildAllPlayoffItems() {
    final matchesByCode = <String, MatchSeriesDto>{
      for (final m in widget.matches) m.slotCode: m,
    };

    final items = <_PlayoffMatchItem>[];
    for (final slot in widget.slots) {
      final realMatch = matchesByCode[slot.code];
      if (realMatch != null) {
        items.add(_PlayoffMatchItem(
          slot: slot,
          match: realMatch,
          isRealMatch: true,
        ));
      } else {
        final placeholderMatch = MatchSeriesDto(
          id: 'slot_${slot.code}',
          tournamentId: widget.tournament.id,
          slotCode: slot.code,
          format: slot.seriesFormat,
          status: 'Pending',
          teamAName: BracketSlotDto.formatSeedSource(slot.teamASource),
          teamBName: BracketSlotDto.formatSeedSource(slot.teamBSource),
          round: slot.round,
        );
        items.add(_PlayoffMatchItem(
          slot: slot,
          match: placeholderMatch,
          isRealMatch: false,
        ));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _buildAllPlayoffItems();

    // Rodadas disponíveis nos slots dos playoffs
    final availableRounds = widget.slots.map((s) => s.round).toSet().toList()
      ..sort();

    // Aplicação reativa dos filtros
    final filteredItems = allItems.where((item) {
      // 1. Filtro por Busca de Equipe
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameA = item.match.displayTeamA.toLowerCase();
        final nameB = item.match.displayTeamB.toLowerCase();
        if (!nameA.contains(q) && !nameB.contains(q)) return false;
      }

      // 2. Filtro por Fase (Stage)
      if (_selectedStage != null) {
        if (_selectedStage == 'Lower') {
          if (item.stage != 'Lower' && item.stage != 'PlayIn') return false;
        } else if (item.stage != _selectedStage) {
          return false;
        }
      }

      // 3. Filtro por Rodada
      if (_selectedRound != null && item.round != _selectedRound) {
        return false;
      }

      // 4. Filtro por Status
      if (_selectedStatus != null) {
        final m = item.match;
        switch (_selectedStatus) {
          case 'pending':
            if (m.isCompleted || m.isOngoing || m.games.isNotEmpty) return false;
            break;
          case 'ongoing':
            if (!m.isOngoing && (m.isCompleted || m.games.isEmpty)) return false;
            break;
          case 'completed':
            if (!m.isCompleted) return false;
            break;
        }
      }

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Barra Canônica de Filtros (Busca em Linha 1, SelectBoxes em Linha 2 com altura padronizada de 46px)
        _buildFilterToolbar(availableRounds),
        const SizedBox(height: 16),

        // 2. Conteúdo dos Confrontos Agrupados ou Empty State
        if (filteredItems.isEmpty)
          AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'NENHUM CONFRONTO ENCONTRADO',
            message: _hasActiveFilters
                ? 'Nenhuma série dos playoffs corresponde aos filtros selecionados. Tente ajustar ou limpar os filtros.'
                : 'Não há confrontos de playoffs disponíveis no momento.',
            actionLabel: _hasActiveFilters ? 'LIMPAR FILTROS' : null,
            actionIcon: Icons.filter_alt_off_rounded,
            onActionPressed: _hasActiveFilters ? _clearFilters : null,
          )
        else
          _buildGroupedStageSections(filteredItems),
      ],
    );
  }

  /// Constrói a toolbar oficial de filtros no padrão do design system da aplicação
  Widget _buildFilterToolbar(List<int> availableRounds) {
    const stageOptions = [
      AppSelectOption<String?>(
        value: null,
        label: 'Todas as Fases',
        iconWidget: Icon(Icons.tune_rounded, size: 17, color: AppColors.primaryNeon),
      ),
      AppSelectOption<String?>(
        value: 'Upper',
        label: 'Chave Superior (Upper)',
        iconWidget: Icon(Icons.keyboard_double_arrow_up_rounded, size: 17, color: AppColors.feedbackSuccess),
      ),
      AppSelectOption<String?>(
        value: 'Lower',
        label: 'Chave Inferior (Lower)',
        iconWidget: Icon(Icons.keyboard_arrow_right_rounded, size: 17, color: AppColors.primaryNeon),
      ),
      AppSelectOption<String?>(
        value: 'GrandFinal',
        label: 'Grande Final',
        iconWidget: Icon(Icons.emoji_events_rounded, size: 17, color: AppColors.dotaGold),
      ),
    ];

    const statusOptions = [
      AppSelectOption<String?>(
        value: null,
        label: 'Todos os Status',
        iconWidget: Icon(Icons.tune_rounded, size: 17, color: AppColors.primaryNeon),
      ),
      AppSelectOption<String?>(
        value: 'pending',
        label: 'A Definir / Pendente',
        iconWidget: Icon(Icons.schedule_rounded, size: 17, color: AppColors.dotaGold),
      ),
      AppSelectOption<String?>(
        value: 'ongoing',
        label: 'Em Andamento',
        iconWidget: Icon(Icons.play_circle_fill_rounded, size: 17, color: AppColors.primaryNeon),
      ),
      AppSelectOption<String?>(
        value: 'completed',
        label: 'Finalizado',
        iconWidget: Icon(Icons.check_circle_rounded, size: 17, color: AppColors.feedbackSuccess),
      ),
    ];

    final roundOptions = [
      const AppSelectOption<int?>(
        value: null,
        label: 'Todas as Rodadas',
        iconWidget: Icon(Icons.tune_rounded, size: 17, color: AppColors.primaryNeon),
      ),
      ...availableRounds.map(
        (r) => AppSelectOption<int?>(
          value: r,
          label: 'Rodada $r',
          iconWidget: const Icon(Icons.calendar_month_rounded, size: 17, color: AppColors.dotaGold),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Linha 1: Busca Dedicada com label flutuante
        AppSearchBar(
          controller: _searchController,
          labelText: 'Buscar equipe nos playoffs',
          hintText: 'Digite o nome da equipe ou código do confronto...',
          onSearch: (val) => setState(() => _searchQuery = val.trim()),
          onClear: () => setState(() => _searchQuery = ''),
        ),
        const SizedBox(height: 10),

        // Linha 2: Controles de Filtros em 46px
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: AppSelectBox<String?>(
                value: _selectedStage,
                options: stageOptions,
                onChanged: (val) => setState(() => _selectedStage = val),
              ),
            ),
            SizedBox(
              width: 190,
              child: AppSelectBox<int?>(
                value: _selectedRound,
                options: roundOptions,
                onChanged: (val) => setState(() => _selectedRound = val),
              ),
            ),
            SizedBox(
              width: 200,
              child: AppSelectBox<String?>(
                value: _selectedStatus,
                options: statusOptions,
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
            ),
            if (_hasActiveFilters)
              AppFilterClearButton(
                hasActiveFilters: _hasActiveFilters,
                onClear: _clearFilters,
              ),
          ],
        ),
      ],
    );
  }

  /// Constrói os blocos de seções agrupadas por fase esportiva
  Widget _buildGroupedStageSections(List<_PlayoffMatchItem> items) {
    final upperItems = items.where((i) => i.stage == 'Upper').toList()
      ..sort((a, b) => a.round.compareTo(b.round));

    final lowerItems = items.where((i) => i.stage == 'Lower' || i.stage == 'PlayIn').toList()
      ..sort((a, b) => a.round.compareTo(b.round));

    final grandFinalItems = items.where((i) => i.stage == 'GrandFinal').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (upperItems.isNotEmpty) ...[
          _buildStageBlock(
            title: widget.tournament.isDoubleElimination
                ? 'CHAVE SUPERIOR (UPPER BRACKET)'
                : 'MATA-MATA PRINCIPAL',
            icon: Icons.keyboard_double_arrow_up_rounded,
            accentColor: AppColors.feedbackSuccess,
            items: upperItems,
          ),
          const SizedBox(height: 24),
        ],
        if (lowerItems.isNotEmpty) ...[
          _buildStageBlock(
            title: 'CHAVE INFERIOR & REPESCAGEM (LOWER BRACKET)',
            icon: Icons.keyboard_arrow_right_rounded,
            accentColor: AppColors.primaryNeon,
            items: lowerItems,
          ),
          const SizedBox(height: 24),
        ],
        if (grandFinalItems.isNotEmpty) ...[
          _buildStageBlock(
            title: 'GRANDE FINAL (DECISÃO DO TÍTULO)',
            icon: Icons.emoji_events_rounded,
            accentColor: AppColors.dotaGoldLight,
            items: grandFinalItems,
          ),
        ],
      ],
    );
  }

  Color _colorForSlot(BracketSlotDto slot) {
    if (slot.isPlayIn) return AppColors.dotaGold;
    switch (slot.stage) {
      case 'Upper':
        return AppColors.feedbackSuccess;
      case 'Lower':
        return AppColors.primaryNeon;
      case 'GrandFinal':
        return AppColors.dotaGoldLight;
      default:
        return AppColors.textPrimary;
    }
  }

  IconData _iconForSlot(BracketSlotDto slot) {
    if (slot.isPlayIn) return Icons.compare_arrows_rounded;
    if (slot.code == 'UF' || slot.code == 'LF') return Icons.workspace_premium_rounded;
    switch (slot.stage) {
      case 'Upper':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'Lower':
        return Icons.keyboard_arrow_right_rounded;
      case 'GrandFinal':
        return Icons.emoji_events_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  Widget _buildStageBlock({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<_PlayoffMatchItem> items,
  }) {
    final int count = items.length;
    final countLabel = count == 1 ? '1 CONFRONTO' : '$count CONFRONTOS';

    // Agrupa os confrontos pelas subfases internas da chave (ex: R1 Upper -> Final Upper; Play-In -> R1 Lower -> R2 Lower -> Final Lower)
    final groupedBySubStage = <String, List<_PlayoffMatchItem>>{};
    for (final item in items) {
      final key = item.slot.subStageGroupKey;
      groupedBySubStage.putIfAbsent(key, () => []).add(item);
    }
    final sortedKeys = groupedBySubStage.keys.toList()..sort();
    final bool hasMultipleSubStages = sortedKeys.length > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isMobile = availableWidth < 700;

        final int columns;
        if (availableWidth >= 1500) {
          columns = 3;
        } else if (availableWidth >= 1000) {
          columns = 2;
        } else {
          columns = 1;
        }

        const double spacing = 16.0;
        final double calculatedCardWidth = columns == 1
            ? availableWidth
            : ((availableWidth - (spacing * (columns - 1))) / columns).floorToDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho Principal da Chave (Upper, Lower & Repescagem ou Grande Final)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSectionHeader(
                title: title,
                countLabel: countLabel,
                accentColor: accentColor,
                icon: Icon(icon, size: 15, color: accentColor),
              ),
            ),

            // Subfases separadas levemente por rodada dentro da Chave
            for (int gIdx = 0; gIdx < sortedKeys.length; gIdx++) ...[
              if (gIdx > 0) const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final subItems = groupedBySubStage[sortedKeys[gIdx]]!;
                  final sampleSlot = subItems.first.slot;
                  final subColor = _colorForSlot(sampleSlot);
                  final subIcon = _iconForSlot(sampleSlot);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasMultipleSubStages || sampleSlot.isPlayIn)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: subColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: subColor.withValues(alpha: 0.55),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(subIcon, size: 12, color: subColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      sampleSlot.subStagePill,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: subColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  sampleSlot.subStageTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: sampleSlot.isPlayIn
                                        ? AppColors.dotaGoldLight
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: subColor.withValues(alpha: 0.18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment:
                            isMobile ? WrapAlignment.center : WrapAlignment.start,
                        children: subItems.map((item) {
                          final slotColor = _colorForSlot(item.slot);
                          final slotIcon = _iconForSlot(item.slot);

                          return TournamentSeriesCard(
                            match: item.match,
                            isMobile: isMobile,
                            customCardWidth: calculatedCardWidth,
                            isAdmin: widget.canManage && item.isRealMatch,
                            draftTeams: widget.draftTeams,
                            tournamentTeams: widget.tournament.teams,
                            stageBadgeLabel: item.slot.cardBadgeLabel,
                            stageBadgeColor: slotColor,
                            stageBadgeIcon: slotIcon,
                            isResultSubmissionLocked:
                                widget.tournament.isResultSubmissionLocked,
                            resultLockReason:
                                widget.tournament.resultLockReason,
                            onRecordResult:
                                item.isRealMatch ? widget.onRecordResult : null,
                            onEditResult:
                                item.isRealMatch ? widget.onEditResult : null,
                            onAdminManage:
                                item.isRealMatch ? widget.onAdminManage : null,
                            onTap: (match) {
                              if (!item.isRealMatch) {
                                AppFeedback.showInfo(
                                  context,
                                  message:
                                      'A série ${item.slot.code} ainda não foi gerada no backend.',
                                );
                                return;
                              }
                              GameDetailDialog.show(
                                context,
                                series: match,
                                initialGameNumber: 1,
                                draftTeams: widget.draftTeams,
                                tournamentTeams: widget.tournament.teams,
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
