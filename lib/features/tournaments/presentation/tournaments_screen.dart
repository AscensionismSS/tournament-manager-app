import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import '../models/tournament_dto.dart';
import '../controllers/tournaments_controller.dart';
import 'widgets/tournaments_filter_bar.dart';

/// Tela oficial de Torneios do Modo Jogador (SRP & Dumb UI).
/// Lista os campeonatos em cards ([AppTournamentCard]) com barra de busca e filtros
/// de Inscrições Abertas/Fechadas e Fases do Torneio.
/// - Barra de busca e filtros fixa (Sticky Header) no topo com sombra dinâmica.
/// - Container centralizado ergonômico (`maxWidth: 1380`) padronizado via [AppPageLayout].
class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  late final TournamentsController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller = TournamentsController();
    _controller.fetchTournaments();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final currentScroll = _scrollController.position.pixels;
    final scrolledNow = currentScroll > 6.0;
    if (_isScrolled != scrolledNow && mounted) {
      setState(() {
        _isScrolled = scrolledNow;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onOpenTournament(TournamentDto tournament) {
    context.go('/tournaments/${tournament.id}/overview', extra: tournament);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isMobile = screenWidth < 620;
    final double horizontalPadding = AppPageLayout.horizontalPadding(context);
    final double cardHeight = isMobile ? 260.0 : 168.0;

    // Card estendido em lista ocupando a largura total (dentro do limite ergonômico de 1380px)
    const int crossAxisCount = 1;
    const double crossAxisSpacing = 0.0;
    const double mainAxisSpacing = 14.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final openTournaments = _controller.openRegistrationTournaments;
          final closedTournaments = _controller.closedRegistrationTournaments;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra de Busca e Filtros Fixa no Topo (Sticky Header Canônico)
              AppPageStickyBar(
                isScrolled: _isScrolled,
                horizontalPadding: horizontalPadding,
                child: TournamentsFilterBar(controller: _controller),
              ),

              // 2. Área Rolável de Campeonatos
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.fetchTournaments,
                  color: AppColors.primaryNeon,
                  backgroundColor: AppColors.surface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Estados de Loading / Erro / Vazio
                      if (_controller.isLoading && _controller.tournaments.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppLoadingState(
                              message: 'Carregando campeonatos da arena...',
                            ),
                          ),
                        )
                      else if (_controller.errorMessage != null &&
                          _controller.tournaments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.error_outline_rounded,
                              title: 'Não foi possível carregar',
                              message: _controller.errorMessage!,
                              actionLabel: 'Tentar Novamente',
                              onActionPressed: _controller.fetchTournaments,
                            ),
                          ),
                        )
                      else if (_controller.filteredTournaments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.emoji_events_outlined,
                              title: _controller.hasActiveFilters
                                  ? 'Nenhum Campeonato Encontrado'
                                  : 'Nenhum Campeonato Disponível',
                              message: _controller.hasActiveFilters
                                  ? 'Nenhum torneio corresponde aos filtros de inscrição ou busca informados.'
                                  : 'Ainda não há campeonatos publicados na arena competitiva.',
                              actionLabel:
                                  _controller.hasActiveFilters ? 'Limpar Filtros' : null,
                              onActionPressed: _controller.hasActiveFilters
                                  ? _controller.clearFilters
                                  : null,
                            ),
                          ),
                        )
                      else ...[
                        // 3. Seção de Campeonatos com Inscrições Abertas
                        if (openTournaments.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                18,
                                horizontalPadding,
                                14,
                              ),
                              child: AppSectionHeader(
                                title: 'INSCRIÇÕES ABERTAS',
                                countLabel:
                                    '${openTournaments.length} ${openTournaments.length == 1 ? "aberto" : "abertos"}',
                              ),
                            ),
                          ),
                          _buildTournamentsSliver(
                            items: openTournaments,
                            crossAxisCount: crossAxisCount,
                            cardHeight: cardHeight,
                            crossAxisSpacing: crossAxisSpacing,
                            mainAxisSpacing: mainAxisSpacing,
                            horizontalPadding: horizontalPadding,
                            bottomPadding: closedTournaments.isNotEmpty ? 12 : 32,
                          ),
                        ],

                        // Divisória estética entre Inscrições Abertas e Fechadas
                        if (openTournaments.isNotEmpty && closedTournaments.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                10,
                                horizontalPadding,
                                20,
                              ),
                              child: const AppDivider.neon(),
                            ),
                          ),

                        // 4. Seção de Campeonatos com Inscrições Fechadas (Em Andamento / Concluídos)
                        if (closedTournaments.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                openTournaments.isNotEmpty ? 4 : 18,
                                horizontalPadding,
                                14,
                              ),
                              child: AppSectionHeader(
                                title:
                                    'INSCRIÇÕES FECHADAS / EM ANDAMENTO & CONCLUÍDOS',
                                countLabel:
                                    '${closedTournaments.length} ${closedTournaments.length == 1 ? "torneio" : "torneios"}',
                              ),
                            ),
                          ),
                          _buildTournamentsSliver(
                            items: closedTournaments,
                            crossAxisCount: crossAxisCount,
                            cardHeight: cardHeight,
                            crossAxisSpacing: crossAxisSpacing,
                            mainAxisSpacing: mainAxisSpacing,
                            horizontalPadding: horizontalPadding,
                            bottomPadding: 32,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTournamentsSliver({
    required List<TournamentDto> items,
    required int crossAxisCount,
    required double cardHeight,
    required double crossAxisSpacing,
    required double mainAxisSpacing,
    required double horizontalPadding,
    required double bottomPadding,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        bottomPadding,
      ),
      sliver: crossAxisCount == 1
          ? SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tournament = items[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: mainAxisSpacing),
                    child: AppTournamentCard(
                      tournament: tournament,
                      onTap: () => _onOpenTournament(tournament),
                    ),
                  );
                },
                childCount: items.length,
              ),
            )
          : SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: cardHeight,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tournament = items[index];
                  return AppTournamentCard(
                    tournament: tournament,
                    onTap: () => _onOpenTournament(tournament),
                  );
                },
                childCount: items.length,
              ),
            ),
    );
  }
}

