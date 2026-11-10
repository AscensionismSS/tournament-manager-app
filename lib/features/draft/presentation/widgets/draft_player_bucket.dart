import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/chosen_player_entry.dart';
import '../../models/draft_player_dto.dart';
import '../../models/draft_state_snapshot_dto.dart';
import 'dota_roles_guide_dialog.dart';
import 'draft_bucket_chosen_list.dart';
import 'draft_bucket_filter_bar.dart';
import 'draft_bucket_player_list.dart';
import 'draft_bucket_tabs.dart';

/// Orquestrador do Bucket de Jogadores da Sala de Draft (SRP & Dumb UI).
/// Compõe a busca, os filtros de função, as abas e as listas de jogadores.
class DraftPlayerBucket extends StatefulWidget {
  final DraftStateSnapshotDto snapshot;
  final String? selectedTeamId;
  final bool canManage;
  final Future<void> Function(DraftPlayerDto player, String? targetTeamId) onAddPlayer;
  final Future<void> Function(ChosenPlayerEntry entry) onRemovePlayer;
  final VoidCallback? onAddLatePlayer;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onHide;
  final bool isReplacing;

  const DraftPlayerBucket({
    super.key,
    required this.snapshot,
    this.selectedTeamId,
    required this.canManage,
    required this.onAddPlayer,
    required this.onRemovePlayer,
    this.onAddLatePlayer,
    this.isExpanded = false,
    this.onToggleExpand,
    this.onHide,
    this.isReplacing = false,
  });

  @override
  State<DraftPlayerBucket> createState() => _DraftPlayerBucketState();
}

class _DraftPlayerBucketState extends State<DraftPlayerBucket> {
  late final ScrollController _availableScrollController;
  late final ScrollController _chosenScrollController;

  String _searchQuery = '';
  DotaRoleType? _selectedRole;
  PlayerNameSort _nameSort = PlayerNameSort.none;
  PlayerRankSort _rankSort = PlayerRankSort.none;
  int _activeTabIndex = 0; // 0: Disponíveis, 1: Escolhidos
  String? _processingPlayerId;

  @override
  void initState() {
    super.initState();
    _availableScrollController = ScrollController();
    _chosenScrollController = ScrollController();
    if (widget.isReplacing) {
      _activeTabIndex = 0;
    }
  }

  @override
  void didUpdateWidget(covariant DraftPlayerBucket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReplacing && _activeTabIndex != 0) {
      setState(() => _activeTabIndex = 0);
    }
  }

  @override
  void dispose() {
    _availableScrollController.dispose();
    _chosenScrollController.dispose();
    super.dispose();
  }

  void _cycleNameSort() {
    setState(() {
      _rankSort = PlayerRankSort.none;
      switch (_nameSort) {
        case PlayerNameSort.none:
          _nameSort = PlayerNameSort.asc;
          break;
        case PlayerNameSort.asc:
          _nameSort = PlayerNameSort.desc;
          break;
        case PlayerNameSort.desc:
          _nameSort = PlayerNameSort.none;
          break;
      }
    });
  }

  void _cycleRankSort() {
    setState(() {
      _nameSort = PlayerNameSort.none;
      switch (_rankSort) {
        case PlayerRankSort.none:
          _rankSort = PlayerRankSort.desc;
          break;
        case PlayerRankSort.desc:
          _rankSort = PlayerRankSort.asc;
          break;
        case PlayerRankSort.asc:
          _rankSort = PlayerRankSort.none;
          break;
      }
    });
  }

  List<DraftPlayerDto> _filterAndSortAvailable(List<DraftPlayerDto> pool) {
    var list = List<DraftPlayerDto>.from(pool);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final idMatch = p.dotaFriendId?.toLowerCase().contains(q) ?? false;
        final roleMatch = p.roles.any((r) => r.toLowerCase().contains(q)) ||
            (p.preferredRole?.toLowerCase().contains(q) ?? false);
        return nameMatch || idMatch || roleMatch;
      }).toList();
    }

    if (_selectedRole != null) {
      list = list.where((p) {
        final pref = DotaRoleType.fromKey(p.preferredRole);
        if (pref == _selectedRole) return true;
        return p.roles.any((r) => DotaRoleType.fromKey(r) == _selectedRole);
      }).toList();
    }

    if (_nameSort == PlayerNameSort.asc) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_nameSort == PlayerNameSort.desc) {
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_rankSort == PlayerRankSort.desc) {
      list.sort((a, b) => (b.rankTier ?? 0).compareTo(a.rankTier ?? 0));
    } else if (_rankSort == PlayerRankSort.asc) {
      list.sort((a, b) => (a.rankTier ?? 0).compareTo(b.rankTier ?? 0));
    }

    return list;
  }

  List<ChosenPlayerEntry> _getChosenEntries() {
    final List<ChosenPlayerEntry> entries = [];
    for (final team in widget.snapshot.teams) {
      for (final starter in team.starters) {
        entries.add(ChosenPlayerEntry(
          player: starter,
          team: team,
          isCaptain: starter.id == team.captainId,
        ));
      }
      for (final reserve in team.reserves) {
        entries.add(ChosenPlayerEntry(
          player: reserve,
          team: team,
          isCaptain: false,
        ));
      }
    }

    var list = entries;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((e) {
        final p = e.player;
        final nameMatch = p.name.toLowerCase().contains(q);
        final teamMatch = e.team.name.toLowerCase().contains(q);
        final idMatch = p.dotaFriendId?.toLowerCase().contains(q) ?? false;
        return nameMatch || teamMatch || idMatch;
      }).toList();
    }

    if (_selectedRole != null) {
      list = list.where((e) {
        final pref = DotaRoleType.fromKey(e.player.preferredRole);
        if (pref == _selectedRole) return true;
        return e.player.roles.any((r) => DotaRoleType.fromKey(r) == _selectedRole);
      }).toList();
    }

    if (_nameSort == PlayerNameSort.asc) {
      list.sort((a, b) => a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase()));
    } else if (_nameSort == PlayerNameSort.desc) {
      list.sort((a, b) => b.player.name.toLowerCase().compareTo(a.player.name.toLowerCase()));
    } else if (_rankSort == PlayerRankSort.desc) {
      list.sort((a, b) => (b.player.rankTier ?? 0).compareTo(a.player.rankTier ?? 0));
    } else if (_rankSort == PlayerRankSort.asc) {
      list.sort((a, b) => (a.player.rankTier ?? 0).compareTo(b.player.rankTier ?? 0));
    }

    return list;
  }

  Future<void> _onAdd(DraftPlayerDto player) async {
    if (_processingPlayerId != null) return;
    setState(() => _processingPlayerId = player.id);
    try {
      await widget.onAddPlayer(player, widget.selectedTeamId);
    } finally {
      if (mounted) setState(() => _processingPlayerId = null);
    }
  }

  Future<void> _onRemove(ChosenPlayerEntry entry) async {
    if (_processingPlayerId != null) return;
    setState(() => _processingPlayerId = entry.player.id);
    try {
      await widget.onRemovePlayer(entry);
    } finally {
      if (mounted) setState(() => _processingPlayerId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _filterAndSortAvailable(widget.snapshot.playerPool);
    final chosen = _getChosenEntries();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabeçalho do Bucket com Badge Oficial Ouro e Botão de Expandir
          Row(
            children: [
              const Icon(Icons.storage_rounded, size: 16, color: AppColors.dotaGold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BUCKET DE JOGADORES',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
              AppBadge(
                label: '${widget.snapshot.playerPool.length + chosen.length} TOTAL',
                variant: AppBadgeVariant.warning,
              ),
              if (widget.onToggleExpand != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: widget.isExpanded
                      ? 'Recolher para 1 coluna'
                      : 'Expandir para 2 colunas',
                  child: AppIconButton(
                    icon: widget.isExpanded
                        ? Icons.keyboard_double_arrow_right_rounded
                        : Icons.keyboard_double_arrow_left_rounded,
                    size: AppIconButtonSize.compact,
                    variant: AppIconButtonVariant.ghost,
                    customColor: AppColors.dotaGold,
                    onPressed: widget.onToggleExpand!,
                  ),
                ),
              ],
              if (widget.onHide != null) ...[
                const SizedBox(width: 2),
                Tooltip(
                  message: 'Ocultar Bucket (Ver equipes em tela cheia)',
                  child: AppIconButton(
                    icon: Icons.chevron_right_rounded,
                    size: AppIconButtonSize.compact,
                    variant: AppIconButtonVariant.ghost,
                    onPressed: widget.onHide!,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // 2. Busca Canônica Padronizada (46px com contorno dourado)
          AppSearchBar(
            labelText: 'Buscar no bucket',
            hintText: 'Digite o nick, ID ou função...',
            onSearch: (q) => setState(() => _searchQuery = q),
          ),

          const SizedBox(height: 10),

          // 3. Filtros Modulares de Função e Ordenação
          DraftBucketFilterBar(
            selectedRole: _selectedRole,
            onRoleSelected: (r) => setState(() => _selectedRole = r),
            nameSort: _nameSort,
            onCycleNameSort: _cycleNameSort,
            rankSort: _rankSort,
            onCycleRankSort: _cycleRankSort,
            onOpenRolesGuide: () => DotaRolesGuideDialog.show(context),
          ),

          const SizedBox(height: 10),

          // 4. Abas Segmentadas: DISPONÍVEIS vs ESCOLHIDOS (travada em Disponíveis se substituindo)
          DraftBucketTabs(
            activeIndex: _activeTabIndex,
            availableCount: available.length,
            chosenCount: chosen.length,
            isLocked: widget.isReplacing,
            onTabChanged: (idx) => setState(() => _activeTabIndex = idx),
          ),

          const SizedBox(height: 10),

          // 5. Lista de Jogadores Responsiva (com RawScrollbar e calha de 12px)
          Expanded(
            child: _activeTabIndex == 0
                ? DraftBucketPlayerList(
                    scrollController: _availableScrollController,
                    players: available,
                    processingPlayerId: _processingPlayerId,
                    canManage: widget.canManage,
                    emptyMessage: _searchQuery.isNotEmpty || _selectedRole != null
                        ? 'Nenhum jogador disponível no filtro.'
                        : 'Todos os jogadores da pool foram escolhidos!',
                    onAddPlayer: _onAdd,
                  )
                : DraftBucketChosenList(
                    scrollController: _chosenScrollController,
                    entries: chosen,
                    processingPlayerId: _processingPlayerId,
                    canManage: widget.canManage,
                    onRemovePlayer: _onRemove,
                  ),
          ),

          // 6. Botão de Adicionar Jogador na Base do Bucket
          if (widget.canManage && widget.onAddLatePlayer != null) ...[
            const SizedBox(height: 10),
            AppButton(
              text: 'ADICIONAR JOGADOR À POOL',
              icon: Icons.person_add_rounded,
              size: AppButtonSize.medium,
              variant: AppButtonVariant.primary,
              onPressed: widget.onAddLatePlayer,
            ),
          ],
        ],
      ),
    );
  }
}
