import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/dota_item_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/dota_item_helper.dart';
import '../../../../draft/models/draft_team_dto.dart';
import '../../../models/player_game_stats_dto.dart';
import 'game_player_stats_view.dart';

/// Barra superior de controle das estatísticas da partida:
/// Seletor de Abas [ GERAL | OBJETIVOS | ITENS ] + Alternador [ TORNEIO | STEAM ].
class GameStatsControlBar extends StatelessWidget {
  final GameStatsTab currentTab;
  final ValueChanged<GameStatsTab> onTabChanged;
  final PlayerNameDisplayMode nameMode;
  final ValueChanged<PlayerNameDisplayMode> onNameModeChanged;
  final bool enabled;

  const GameStatsControlBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.nameMode,
    required this.onNameModeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.38,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            // 1. Abas de Estatísticas
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.canvasSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TabButton(
                    label: 'GERAL',
                    icon: Icons.bar_chart_rounded,
                    isSelected: enabled && currentTab == GameStatsTab.general,
                    onTap: () => onTabChanged(GameStatsTab.general),
                  ),
                  const SizedBox(width: 4),
                  _TabButton(
                    label: 'OBJETIVOS',
                    icon: Icons.flag_rounded,
                    isSelected:
                        enabled && currentTab == GameStatsTab.objectives,
                    onTap: () => onTabChanged(GameStatsTab.objectives),
                  ),
                  const SizedBox(width: 4),
                  _TabButton(
                    label: 'ITENS',
                    icon: Icons.backpack_rounded,
                    isSelected: enabled && currentTab == GameStatsTab.items,
                    onTap: () => onTabChanged(GameStatsTab.items),
                  ),
                ],
              ),
            ),

            // 2. Switch de Nome de Jogador (DISPLAY NAME: TORNEIO / STEAM)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DISPLAY NAME:',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: AppColors.canvasSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SegmentButton(
                        label: 'TORNEIO',
                        tooltip: 'Exibir nicknames cadastrados no torneio',
                        isSelected: enabled &&
                            nameMode == PlayerNameDisplayMode.tsurus,
                        onTap: () =>
                            onNameModeChanged(PlayerNameDisplayMode.tsurus),
                      ),
                      _SegmentButton(
                        label: 'STEAM',
                        tooltip: 'Exibir nicknames da Steam no replay',
                        isSelected:
                            enabled && nameMode == PlayerNameDisplayMode.steam,
                        onTap: () =>
                            onNameModeChanged(PlayerNameDisplayMode.steam),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Seção de tabela de estatísticas de uma equipe (Cabeçalho + Objetivos Globais + Tabela da Aba Ativa).
class GameTeamStatsSection extends StatelessWidget {
  final String teamName;
  final String? teamId;
  final List<PlayerGameStatsDto> players;
  final List<DraftTeamDto>? draftTeams;
  final GameStatsTab currentTab;
  final PlayerNameDisplayMode nameMode;
  final int roshanKills;
  final int aegisStolen;

  /// Largura mínima estável unificada (720px) para prevenir pulos de layout ao alternar abas
  static const double minTableWidth = 720.0;

  const GameTeamStatsSection({
    super.key,
    required this.teamName,
    required this.teamId,
    required this.players,
    required this.draftTeams,
    required this.currentTab,
    required this.nameMode,
    required this.roshanKills,
    required this.aegisStolen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.dotaGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      teamName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DotaObjectiveBadges(
              roshanKills: roshanKills,
              aegisStolen: aegisStolen,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final needsScroll = constraints.maxWidth < minTableWidth;
              final tableWidget = switch (currentTab) {
                GameStatsTab.general => _buildGeneralTable(),
                GameStatsTab.objectives => _buildObjectivesTable(),
                GameStatsTab.items => _buildItemsTable(),
              };

              if (needsScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: minTableWidth,
                    child: tableWidget,
                  ),
                );
              }
              return tableWidget;
            },
          ),
        ),
      ],
    );
  }

  String _playerNameFor(PlayerGameStatsDto p, int index) {
    return p.resolveDisplayName(
      draftTeams: draftTeams,
      teamId: teamId,
      playerIndex: index,
      useSteamName: nameMode == PlayerNameDisplayMode.steam,
    );
  }

  // -------------------------------------------------------------
  // ABA 1: GERAL (K/D/A, Net Worth, GPM, XPM)
  // -------------------------------------------------------------
  Widget _buildGeneralTable() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FixedColumnWidth(215),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.0),
        4: FlexColumnWidth(1.0),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: const [
            _TableHeaderCell('JOGADOR / HERÓI', alignment: Alignment.centerLeft),
            _TableHeaderCell('K / D / A', alignment: Alignment.center),
            _TableHeaderCell('NET WORTH', alignment: Alignment.centerRight),
            _TableHeaderCell('GPM', alignment: Alignment.center),
            _TableHeaderCell('XPM', alignment: Alignment.center),
          ],
        ),
        for (int i = 0; i < players.length; i++)
          _buildGeneralRow(players[i], i),
      ],
    );
  }

  TableRow _buildGeneralRow(PlayerGameStatsDto p, int index) {
    return TableRow(
      children: [
        DotaHeroPlayerCell(
          heroId: p.heroId,
          heroName: p.heroName,
          playerName: _playerNameFor(p, index),
        ),
        _MetricCell(
          text: p.kdaFormatted,
          color: AppColors.dotaGoldLight,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
        _MetricCell(
          text: p.formattedNetWorth,
          alignment: Alignment.centerRight,
          horizontalPadding: 8,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        _MetricCell(
          text: '${p.goldPerMinute}',
          color: AppColors.textSecondary,
          fontSize: 11.5,
        ),
        _MetricCell(
          text: '${p.experiencePerMinute}',
          color: AppColors.textSecondary,
          fontSize: 11.5,
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // ABA 2: OBJETIVOS (Dano Heróis, Estruturas, Cura, Wards)
  // -------------------------------------------------------------
  Widget _buildObjectivesTable() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FixedColumnWidth(215),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.3),
        5: FlexColumnWidth(1.3),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: const [
            _TableHeaderCell('JOGADOR / HERÓI', alignment: Alignment.centerLeft),
            _TableHeaderCell('DANO A HERÓIS', alignment: Alignment.center),
            _TableHeaderCell('DANO A TORRES', alignment: Alignment.center),
            _TableHeaderCell('CURA', alignment: Alignment.center),
            _TableHeaderCell('WARDS COLOCADAS', alignment: Alignment.center),
            _TableHeaderCell('WARDS DESTRUÍDAS', alignment: Alignment.center),
          ],
        ),
        for (int i = 0; i < players.length; i++)
          _buildObjectivesRow(players[i], i),
      ],
    );
  }

  TableRow _buildObjectivesRow(PlayerGameStatsDto p, int index) {
    return TableRow(
      children: [
        DotaHeroPlayerCell(
          heroId: p.heroId,
          heroName: p.heroName,
          playerName: _playerNameFor(p, index),
        ),
        _MetricCell(
          text: p.formattedHeroDamage,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        _MetricCell(
          text: p.formattedTowerDamage,
          color: AppColors.dotaGoldLight,
          fontWeight: FontWeight.w800,
        ),
        _MetricCell(
          text: p.formattedHeroHealing,
          color: p.heroHealing > 0
              ? AppColors.feedbackSuccess
              : AppColors.textSecondary,
        ),
        _MetricCell(
          text: '${p.wardsPlaced}',
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        _MetricCell(
          text: '${p.wardsDestroyed}',
          color: AppColors.textPrimary,
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // ABA 3: ITENS (Inventário, Mochila, Sequência de Neutros & Buffs por Tier, Buffs Aghanim)
  // -------------------------------------------------------------
  Widget _buildItemsTable() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FixedColumnWidth(215),
        1: FlexColumnWidth(3.35),
        2: FlexColumnWidth(1.15),
        3: FlexColumnWidth(2.45),
        4: FlexColumnWidth(0.85),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: const [
            _TableHeaderCell('JOGADOR / HERÓI', alignment: Alignment.centerLeft),
            _TableHeaderCell('INVENTÁRIO (6 SLOTS)', alignment: Alignment.center),
            _TableHeaderCell('MOCHILA', alignment: Alignment.center),
            _TableHeaderCell('NEUTRO & BUFF JUNGLE', alignment: Alignment.center),
            _TableHeaderCell('BUFFS', alignment: Alignment.center),
          ],
        ),
        for (int i = 0; i < players.length; i++) _buildItemsRow(players[i], i),
      ],
    );
  }

  TableRow _buildItemsRow(PlayerGameStatsDto p, int index) {
    final tiers = p.neutralTierProgression
        .map(
          (t) => DotaNeutralTierData(
            tierNumber: t.tierNumber,
            neutralItem: t.neutralItem,
            jungleBuff: t.jungleBuff,
            isLatest: t.isLatest,
          ),
        )
        .toList();

    return TableRow(
      children: [
        DotaHeroPlayerCell(
          heroId: p.heroId,
          heroName: p.heroName,
          playerName: _playerNameFor(p, index),
        ),
        // 1. 6 Slots Principais
        Container(
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(6, (slotIdx) {
                final String? itemName =
                    slotIdx < p.itemNames.length ? p.itemNames[slotIdx] : null;
                final int? itemId =
                    slotIdx < p.itemIds.length ? p.itemIds[slotIdx] : null;
                return Padding(
                  padding: EdgeInsets.only(right: slotIdx < 5 ? 3.5 : 0),
                  child: DotaItemSlot(itemName: itemName, itemId: itemId),
                );
              }),
            ),
          ),
        ),
        // 2. Mochila (3 Slots)
        Container(
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (bpIdx) {
                final String? bpName = bpIdx < p.backpackNames.length
                    ? p.backpackNames[bpIdx]
                    : null;
                return Padding(
                  padding: EdgeInsets.only(right: bpIdx < 2 ? 3 : 0),
                  child: DotaItemSlot(itemName: bpName, isBackpack: true),
                );
              }),
            ),
          ),
        ),
        // 3. Sequência de Tiers de Item Neutro + Buff da Jungle acoplado (Opção 1)
        Container(
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DotaNeutralProgressionRow(tiers: tiers),
          ),
        ),
        // 4. Buffs de Aghanim (Cetro + Shard)
        Container(
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DotaAghanimSlot(
                  assetPath: DotaItemHelper.scepterAsset,
                  tooltip: "Aghanim's Scepter (Cetro)",
                  isActive: p.hasAghanimScepter,
                  activeColor: AppColors.dotaGoldLight,
                ),
                const SizedBox(width: 5),
                DotaAghanimSlot(
                  assetPath: DotaItemHelper.shardAsset,
                  tooltip: "Aghanim's Shard (Fragmento)",
                  isActive: p.hasAghanimShard,
                  activeColor: AppColors.primaryNeon,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final Alignment alignment;
  final double horizontalPadding;

  const _MetricCell({
    required this.text,
    required this.color,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w700,
    this.alignment = Alignment.center,
    this.horizontalPadding = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final Alignment alignment;

  const _TableHeaderCell(
    this.text, {
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.dotaGold.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? AppColors.dotaGold : Colors.transparent,
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.dotaGoldLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0.5,
                color: isSelected ? AppColors.dotaGoldLight : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.dotaGold : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0.4,
              color: isSelected ? AppColors.background : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

