import 'package:flutter/material.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import '../controllers/members_controller.dart';
import '../models/member_dto.dart';
import 'widgets/members_filter_bar.dart';

/// Tela oficial de Membros da Comunidade / Times (SRP).
/// - Barra de busca e filtros fixa (Sticky) no topo para acesso imediato durante o Infinite Scroll.
/// - Container centralizado (`maxWidth: 1380`) para ergonomia de leitura em telas amplas.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  static const double _cardHeight = 152.0;

  late final MembersController _controller;
  final ScrollController _scrollController = ScrollController();
  Size? _lastViewportSize;
  bool _isFillCheckQueued = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller = MembersController();
    _controller.addListener(_scheduleViewportFillCheck);
    _controller.fetchMembers();
    _scrollController.addListener(_onScroll);
  }

  void _scheduleViewportFillCheck() {
    if (_isFillCheckQueued ||
        !mounted ||
        !_controller.hasMore ||
        _controller.isLoadingMore) {
      return;
    }
    _isFillCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isFillCheckQueued = false;
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0 &&
          _controller.hasMore &&
          !_controller.isLoadingMore) {
        _controller.loadMore();
      }
    });
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

    final maxScroll = _scrollController.position.maxScrollExtent;
    // Quando a rolagem se aproxima do fim da página (350px de margem), busca o próximo lote
    if (maxScroll - currentScroll <= 350) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_scheduleViewportFillCheck);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    if (_lastViewportSize != viewportSize) {
      _lastViewportSize = viewportSize;
      _scheduleViewportFillCheck();
    }
    final double horizontalPadding = AppPageLayout.horizontalPadding(context);
    final double availableWidth = AppPageLayout.availableWidth(context);
    final int crossAxisCount =
        availableWidth < 680 ? 1 : (availableWidth < 1080 ? 2 : 3);
    const double crossAxisSpacing = 20.0;
    const double mainAxisSpacing = 16.0;
    final double itemWidth = crossAxisCount == 1
        ? availableWidth
        : (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
            crossAxisCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra de Busca e Filtros Fixa no Topo (Sticky Header Canônico)
              AppPageStickyBar(
                isScrolled: _isScrolled,
                horizontalPadding: horizontalPadding,
                child: MembersFilterBar(controller: _controller),
              ),

              // 2. Área Rolável de Jogadores com Infinite Scroll
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.fetchMembers,
                  color: AppColors.primaryNeon,
                  backgroundColor: AppColors.surface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (_controller.isLoading && _controller.members.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppLoadingState(
                              message: 'Carregando membros da arena...',
                            ),
                          ),
                        )
                      else if (_controller.errorMessage != null &&
                          _controller.members.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.error_outline_rounded,
                              title: 'Não foi possível carregar',
                              message: _controller.errorMessage!,
                              actionLabel: 'Tentar Novamente',
                              onActionPressed: _controller.fetchMembers,
                            ),
                          ),
                        )
                      else if (_controller.members.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.person_search_rounded,
                              title: 'Nenhum Jogador Encontrado',
                              message:
                                  'Nenhum membro corresponde aos filtros ou termo de busca informado.',
                              actionLabel: 'Limpar Filtros',
                              onActionPressed: _controller.clearFilters,
                            ),
                          ),
                        )
                      else ...[
                        // 3. Seção do Usuário Autenticado (SEU PERFIL DE JOGADOR)
                        if (_controller.myMember != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                18,
                                horizontalPadding,
                                10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AppSectionHeader(
                                    title: 'SEU PERFIL DE JOGADOR',
                                    countLabel: 'Você',
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: itemWidth,
                                    height: _cardHeight,
                                    child: _buildMemberCard(_controller.myMember!),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Divisória estética isolando o próprio perfil dos demais jogadores
                        if (_controller.myMember != null &&
                            _controller.otherMembers.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                12,
                                horizontalPadding,
                                18,
                              ),
                              child: const AppDivider.neon(),
                            ),
                          ),

                        // 4. Seção dos Demais Membros da Comunidade
                        if (_controller.otherMembers.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                _controller.myMember != null ? 2 : 18,
                                horizontalPadding,
                                14,
                              ),
                              child: AppSectionHeader(
                                title: _controller.myMember != null
                                    ? 'OUTROS JOGADORES DA COMUNIDADE'
                                    : 'JOGADORES ENCONTRADOS',
                                countLabel: _controller.hasMore
                                    ? '${_controller.visibleOtherMembers.length} de ${_controller.otherMembers.length} jogadores'
                                    : '${_controller.otherMembers.length} ${_controller.otherMembers.length == 1 ? "jogador" : "jogadores"}',
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              16,
                            ),
                            sliver: crossAxisCount == 1
                                ? SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final member =
                                            _controller.visibleOtherMembers[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: mainAxisSpacing,
                                          ),
                                          child: SizedBox(
                                            width: itemWidth,
                                            height: _cardHeight,
                                            child: _buildMemberCard(member),
                                          ),
                                        );
                                      },
                                      childCount:
                                          _controller.visibleOtherMembers.length,
                                    ),
                                  )
                                : SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisExtent: _cardHeight,
                                      crossAxisSpacing: crossAxisSpacing,
                                      mainAxisSpacing: mainAxisSpacing,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final member =
                                            _controller.visibleOtherMembers[index];
                                        return _buildMemberCard(member);
                                      },
                                      childCount:
                                          _controller.visibleOtherMembers.length,
                                    ),
                                  ),
                          ),

                          // Rodapé do Infinite Scroll
                          AppInfiniteScrollFooter(
                            hasMore: _controller.hasMore,
                            isLoadingMore: _controller.isLoadingMore,
                            showCompletedLabel: _controller.otherMembers.length >
                                MembersController.pageSize,
                            loadingLabel: 'Carregando mais jogadores...',
                            idleLoadMoreLabel: 'Carregar mais jogadores',
                            completedLabel:
                                'Todos os ${_controller.otherMembers.length} jogadores foram carregados',
                            horizontalPadding: horizontalPadding,
                            onLoadMore: _controller.loadMore,
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

  Widget _buildMemberCard(MemberDto member) {
    return AppPlayerCard(
      nickname: member.effectiveNickname,
      initials: member.initials,
      avatarUrl: member.avatarUrl,
      rankDetail: member.rankDetail,
      rankStars: member.rankStars,
      leaderboardRank: member.leaderboardRank,
      steamId: member.dotaFriendId,
      openDotaUrl: member.openDotaUrl,
      steamProfileUrl: member.computedSteamProfileUrl,
      roles: member.roles,
      preferredRole: member.preferredRole,
      isMe: member.userId == _controller.currentUserId,
    );
  }
}
