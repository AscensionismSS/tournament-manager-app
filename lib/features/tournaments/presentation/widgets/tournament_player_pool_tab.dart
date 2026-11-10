import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/utils/safe_url_launcher.dart';
import '../../models/tournament_dto.dart';

/// Aba oficial de Pool de Jogadores do Torneio (SRP & Dumb UI).
/// Totalmente integrada ao Design System oficial através do [AppPlayerCard],
/// garantindo consistência visual premium com a lista de membros e cards do app:
/// - Desktop: Grade responsiva (GridView) com [AppPlayerCard] oficial de 176px.
/// - Mobile: Lista vertical harmônica com [AppPlayerCard] estilizado com marca d'água,
///   medalha do Dota com estrelas, ícones de funções, Steam ID e botões externos.
class TournamentPlayerPoolTab extends StatefulWidget {
  final TournamentDto tournament;
  final void Function(DraftPlayerSummaryDto player)? onOpenProfile;

  const TournamentPlayerPoolTab({
    super.key,
    required this.tournament,
    this.onOpenProfile,
  });

  @override
  State<TournamentPlayerPoolTab> createState() =>
      _TournamentPlayerPoolTabState();
}

class _TournamentPlayerPoolTabState extends State<TournamentPlayerPoolTab> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (_searchQuery != query) {
      setState(() => _searchQuery = query);
    }
  }

  Future<void> _handleOpenProfile(DraftPlayerSummaryDto player) async {
    if (widget.onOpenProfile != null) {
      widget.onOpenProfile!(player);
      return;
    }

    final url = player.computedSteamProfileUrl;
    if (url != null && url.trim().isNotEmpty) {
      await SafeUrlLauncher.launch(url, context: context);
    }
  }

  List<DraftPlayerSummaryDto> get _filteredPlayers {
    final pool = widget.tournament.draftPlayerPool;
    if (_searchQuery.isEmpty) return pool;

    return pool.where((p) {
      final nameMatches = p.name.toLowerCase().contains(_searchQuery);
      final idMatches =
          p.dotaFriendId?.toLowerCase().contains(_searchQuery) ?? false;
      final roleMatches =
          p.roles.any((r) => r.toLowerCase().contains(_searchQuery)) ||
              (p.preferredRole?.toLowerCase().contains(_searchQuery) ?? false);
      return nameMatches || idMatches || roleMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalPool = widget.tournament.draftPlayerPool;
    final filtered = _filteredPlayers;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    const double cardHeight = 176.0;

    if (totalPool.isEmpty) {
      return _buildEmptyState(
        title: 'NENHUM JOGADOR NO POOL',
        message:
            'Ainda não há jogadores inscritos no pool de draft deste campeonato.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Seção com contador dinâmico
        AppSectionHeader(
          title: 'POOL DE JOGADORES INSCRITOS',
          countLabel:
              '${totalPool.length} ${totalPool.length == 1 ? "JOGADOR" : "JOGADORES"}',
        ),
        const SizedBox(height: 12),

        // Barra de Busca Canônica (46px de altura, floating label)
        AppSearchBar(
          controller: _searchController,
          labelText: 'Buscar jogadores',
          hintText: 'Digite o nome, ID ou função do jogador...',
          onSearch: (value) =>
              setState(() => _searchQuery = value.trim().toLowerCase()),
          onClear: () => setState(() => _searchQuery = ''),
        ),
        const SizedBox(height: 18),

        if (filtered.isEmpty)
          _buildEmptyState(
            title: 'NENHUM JOGADOR ENCONTRADO',
            message:
                'Nenhum jogador corresponde à busca "$_searchQuery". Tente outros termos.',
          )
        else if (isMobile)
          // Mobile: Lista vertical com espaçamento harmônico de 14px
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final player = filtered[index];
              return SizedBox(
                height: cardHeight,
                child: _buildPlayerCard(
                  player: player,
                ),
              );
            },
          )
        else
          // Desktop: Grade responsiva (GridView) com espaçamento de 16px
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 460,
              mainAxisExtent: cardHeight,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final player = filtered[index];
              return _buildPlayerCard(
                player: player,
              );
            },
          ),
      ],
    );
  }

  /// Card de Jogador Oficial do Design System ([AppPlayerCard])
  /// Renderiza com a marca d'água da logo da arena, brilho dourado Aegis,
  /// medalha com estrelas, funções estilizadas e botões externos de perfil.
  Widget _buildPlayerCard({
    required DraftPlayerSummaryDto player,
  }) {
    return AppPlayerCard(
      nickname: player.name,
      initials: player.initials,
      avatarUrl: player.avatarUrl,
      rankDetail: player.rankDetail,
      rankStars: player.rankStars,
      steamId: player.dotaFriendId,
      openDotaUrl: player.openDotaUrl,
      steamProfileUrl: player.computedSteamProfileUrl,
      roles: player.roles,
      preferredRole: player.preferredRole,
      onOpenSteamProfile: player.computedSteamProfileUrl != null
          ? () => _handleOpenProfile(player)
          : null,
      onTap: () => _handleOpenProfile(player),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 36,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
