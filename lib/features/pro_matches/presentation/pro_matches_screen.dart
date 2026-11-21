import 'package:flutter/material.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import '../controllers/pro_matches_controller.dart';
import 'widgets/pro_matches_filter_bar.dart';
import 'widgets/pro_tournament_section.dart';

/// Tela isolada do Cenário Profissional de Dota 2 (`pro_matches`).
/// Segue o padrão canônico de Toolbar ([ProMatchesFilterBar]), [AppPageStickyBar]
/// e seções por campeonato ([ProTournamentSection]) com cooldown anti-flood no refresh.
class ProMatchesScreen extends StatefulWidget {
  const ProMatchesScreen({super.key});

  @override
  State<ProMatchesScreen> createState() => _ProMatchesScreenState();
}

class _ProMatchesScreenState extends State<ProMatchesScreen> {
  late final ProMatchesController _controller;
  late final ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller = ProMatchesController();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _controller.fetchOverview();
  }

  void _handleScroll() {
    final scrolled = _scrollController.hasClients && _scrollController.offset > 8;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  Future<void> _onRefresh() => _controller.fetchOverview(force: true);

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final overview = _controller.overview;
          final filteredTournaments = _controller.filteredTournaments;

          return Column(
            children: [
              // 1. Barra Canônica de Busca, Filtros (Nível + Campeonato) e Botão Atualizar com Cooldown
              AppPageStickyBar(
                isScrolled: _isScrolled,
                horizontalPadding: horizontalPadding,
                child: ProMatchesFilterBar(
                  controller: _controller,
                  onRefresh: _onRefresh,
                ),
              ),

              // 2. Corpo Principal Rolável
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.primaryNeon,
                  backgroundColor: AppColors.surface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (_controller.isLoading && overview == null)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppLoadingState(
                              message: 'Carregando partidas do cenário profissional...',
                            ),
                          ),
                        )
                      else if (_controller.errorMessage != null && overview == null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.error_outline_rounded,
                              title: 'Não foi possível carregar',
                              message: _controller.errorMessage!,
                              actionLabel: 'Tentar Novamente',
                              onActionPressed: _onRefresh,
                            ),
                          ),
                        )
                      else if (overview != null && !overview.isConfigured)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.settings_input_antenna_rounded,
                              title: 'Integração Pro Não Ativada',
                              message:
                                  'A integração com os campeonatos profissionais de Dota 2 ainda não foi ativada no servidor.',
                            ),
                          ),
                        )
                      else if (filteredTournaments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.live_tv_rounded,
                              title: _controller.hasActiveFilters
                                  ? 'Nenhuma Partida Encontrada'
                                  : 'Nenhum Campeonato no Momento',
                              message: _controller.hasActiveFilters
                                  ? 'Nenhum campeonato ou partida corresponde aos filtros aplicados.'
                                  : 'Não há partidas profissionais Tier S ou Tier A ao vivo ou agendadas no momento.',
                              actionLabel: _controller.hasActiveFilters
                                  ? 'Limpar Filtros'
                                  : _controller.refreshButtonLabel,
                              onActionPressed: _controller.hasActiveFilters
                                  ? _controller.clearFilters
                                  : (_controller.canRefresh ? _onRefresh : null),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            18,
                            horizontalPadding,
                            32,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tournament = filteredTournaments[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: ProTournamentSection(
                                    tournament: tournament,
                                    activeFilter: _controller.activeFilter,
                                    searchQuery: _controller.searchQuery,
                                  ),
                                );
                              },
                              childCount: filteredTournaments.length,
                            ),
                          ),
                        ),
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
}
