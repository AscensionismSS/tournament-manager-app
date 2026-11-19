import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/system_security_service.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/admin_tournaments_controller.dart';
import 'create_tournament_dialog.dart';
import 'widgets/admin_tournament_mobile_card.dart';
import 'widgets/admin_tournaments_filter_bar.dart';

/// Tela administrativa oficial para Gestão e Criação de Torneios (Orquestrador Enxuto & Dumb UI).
/// Segue o padrão unificado de enquadramento ergonômico (maxWidth: 1380) e Sticky Header com elevação.
class AdminTournamentsScreen extends StatefulWidget {
  const AdminTournamentsScreen({super.key});

  @override
  State<AdminTournamentsScreen> createState() => _AdminTournamentsScreenState();
}

class _AdminTournamentsScreenState extends State<AdminTournamentsScreen> {
  late final AdminTournamentsController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller = AdminTournamentsController();
    _controller.fetchTournaments();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final scrolled = _scrollController.offset > 8.0;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onOpenCreateDialog() async {
    if (SystemSecurityService.instance.isTournamentCreationLocked) {
      final msg = SystemSecurityService.instance.message;
      AppFeedback.showWarning(
        context,
        title: 'CRIAÇÃO DE TORNEIOS BLOQUEADA',
        message: (msg != null && msg.trim().isNotEmpty)
            ? msg.trim()
            : 'A criação de novos torneios está temporariamente bloqueada pela administração do sistema.',
      );
      return;
    }

    await CreateTournamentDialog.show(
      context,
      controller: _controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra de Busca e Filtros Canônica Fixa (Sticky) com sombra de scroll
              AppPageStickyBar(
                isScrolled: _isScrolled,
                horizontalPadding: horizontalPadding,
                child: AdminTournamentsFilterBar(
                  controller: _controller,
                  onNewTournament: _onOpenCreateDialog,
                ),
              ),

              // 2. Conteúdo da Lista com Refresh e Scroll Virtualizado
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.fetchTournaments,
                  color: AppColors.primaryNeon,
                  backgroundColor: AppColors.surface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Espaçador inicial entre a barra fixa e a lista
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),

                      // Estado de Carregamento Inicial
                      if (_controller.isLoading && _controller.tournaments.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppLoadingState(
                              message: 'Carregando campeonatos da arena...',
                            ),
                          ),
                        )
                      // Estado de Erro Inicial
                      else if (_controller.error != null &&
                          _controller.tournaments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.error_outline_rounded,
                              title: 'Erro ao carregar torneios',
                              message: _controller.error!,
                              actionLabel: 'Tentar Novamente',
                              onActionPressed: _controller.fetchTournaments,
                            ),
                          ),
                        )
                      // Estado Vazio (Sem resultados ou sem torneios)
                      else if (_controller.filteredTournaments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.emoji_events_outlined,
                              title: _controller.hasActiveFilters
                                  ? 'Nenhum torneio encontrado'
                                  : 'Nenhum campeonato cadastrado',
                              message: _controller.hasActiveFilters
                                  ? 'Nenhum torneio corresponde aos filtros aplicados.'
                                  : 'Crie seu primeiro campeonato competitivo para iniciar as fases de draft.',
                              actionLabel: _controller.hasActiveFilters
                                  ? 'Limpar Filtros'
                                  : 'Criar Primeiro Torneio',
                              onActionPressed: _controller.hasActiveFilters
                                  ? _controller.clearFilters
                                  : _onOpenCreateDialog,
                            ),
                          ),
                        )
                      // Lista de Torneios
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            32,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tournament =
                                    _controller.filteredTournaments[index];
                                return AdminTournamentMobileCard(
                                  tournament: tournament,
                                  onTap: (t) => context.go(
                                    '/tournaments/${t.id}/overview?from=admin',
                                    extra: t,
                                  ),
                                );
                              },
                              childCount: _controller.filteredTournaments.length,
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
