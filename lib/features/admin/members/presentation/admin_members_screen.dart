import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../../members/models/member_dto.dart';
import '../../../members/models/recovery_request_dto.dart';
import '../controllers/admin_members_controller.dart';
import 'admin_members_dialogs.dart';
import 'widgets/admin_member_mobile_card.dart';
import 'widgets/admin_members_filter_bar.dart';
import 'widgets/admin_members_tab_switcher.dart';
import 'widgets/admin_members_table.dart';
import 'widgets/recovery_request_mobile_card.dart';
import 'widgets/recovery_requests_table.dart';

/// Tela administrativa oficial para Gestão de Membros
/// e Solicitações de Troca de Steam (Orquestrador Enxuto & Dumb UI).
/// Segue o padrão unificado de enquadramento ergonômico (maxWidth: 1380) e Sticky Header com elevação.
class AdminMembersScreen extends StatefulWidget {
  final AdminMembersTab initialTab;

  const AdminMembersScreen({
    super.key,
    this.initialTab = AdminMembersTab.members,
  });

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  late final AdminMembersController _controller;
  final ScrollController _scrollController = ScrollController();
  Size? _lastViewportSize;
  bool _isFillCheckQueued = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller = AdminMembersController(initialTab: widget.initialTab);
    _controller.addListener(_scheduleViewportFillCheck);
    _controller.fetchMembers();
    _controller.fetchRecoveryRequests();
    _scrollController.addListener(_onScroll);
  }

  void _scheduleViewportFillCheck() {
    if (_isFillCheckQueued ||
        !mounted ||
        _controller.activeTab != AdminMembersTab.members ||
        !_controller.hasMoreMembers ||
        _controller.isLoadingMore) {
      return;
    }
    _isFillCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isFillCheckQueued = false;
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0 &&
          _controller.activeTab == AdminMembersTab.members &&
          _controller.hasMoreMembers &&
          !_controller.isLoadingMore) {
        _controller.loadMoreMembers();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final scrolled = _scrollController.offset > 8.0;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }

    if (_controller.activeTab != AdminMembersTab.members) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Quando a rolagem se aproxima do fim da página (350px de margem), busca o próximo lote
    if (maxScroll - currentScroll <= 350) {
      _controller.loadMoreMembers();
    }
  }

  @override
  void didUpdateWidget(covariant AdminMembersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab &&
        _controller.activeTab != widget.initialTab) {
      _controller.setActiveTab(widget.initialTab);
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

  void _onToggleStatus(MemberDto member) =>
      AdminMembersDialogs.toggleStatus(context, _controller, member);

  void _onApproveRecovery(RecoveryRequestDto req) =>
      AdminMembersDialogs.approveRecovery(context, _controller, req);

  void _onRejectRecovery(RecoveryRequestDto req) =>
      AdminMembersDialogs.rejectRecovery(context, _controller, req);

  @override
  Widget build(BuildContext context) {
    final viewportSize = MediaQuery.sizeOf(context);
    if (_lastViewportSize != viewportSize) {
      _lastViewportSize = viewportSize;
      _scheduleViewportFillCheck();
    }
    final screenWidth = viewportSize.width;
    final isMobile = screenWidth < 850;
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra Fixa (Sticky Header) com Abas e Filtros
              AppPageStickyBar(
                isScrolled: _isScrolled,
                horizontalPadding: horizontalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminMembersTabSwitcher(
                      activeTab: _controller.activeTab,
                      onTabChanged: (tab) {
                        _controller.setActiveTab(tab);
                        final targetPath =
                            tab == AdminMembersTab.recoveryRequests
                                ? '/admin/members?tab=requests'
                                : '/admin/members';
                        final currentUri =
                            GoRouterState.of(context).uri.toString();
                        if (currentUri != targetPath) {
                          context.go(targetPath);
                        }
                      },
                      pendingRequestsCount: _controller.pendingRequestsCount,
                    ),
                    const SizedBox(height: 12),
                    if (_controller.activeTab == AdminMembersTab.members)
                      AdminMembersFilterBar(controller: _controller)
                    else
                      AppSearchBar(
                        controller: _controller.requestsSearchController,
                        labelText: 'Buscar solicitações',
                        hintText: 'Digite o nome do jogador ou e-mail...',
                        onSearch: (_) {},
                        isLoading: _controller.isLoadingRequests,
                      ),
                  ],
                ),
              ),

              // 2. Conteúdo da Lista Virtualizada com Refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (_controller.activeTab == AdminMembersTab.members) {
                      await _controller.fetchMembers();
                    } else {
                      await _controller.fetchRecoveryRequests();
                    }
                  },
                  color: AppColors.primaryNeon,
                  backgroundColor: AppColors.surface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Espaçador inicial após a barra fixa
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),

                      // Aba 1: Gestão de Membros
                      if (_controller.activeTab == AdminMembersTab.members) ...[
                        if (_controller.isLoadingMembers &&
                            _controller.members.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: AppLoadingState(
                                message: 'Carregando membros da arena...',
                              ),
                            ),
                          )
                        else if (_controller.membersError != null &&
                            _controller.members.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: AppEmptyState(
                                icon: Icons.error_outline_rounded,
                                title: 'Erro ao carregar membros',
                                message: _controller.membersError!,
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
                                title: 'Nenhum membro encontrado',
                                message: _controller.hasActiveMemberFilters
                                    ? 'Nenhum membro corresponde aos filtros de busca aplicados.'
                                    : 'Nenhum membro cadastrado na plataforma.',
                                actionLabel: _controller.hasActiveMemberFilters
                                    ? 'Limpar Filtros'
                                    : null,
                                onActionPressed:
                                    _controller.hasActiveMemberFilters
                                        ? _controller.clearFilters
                                        : null,
                              ),
                            ),
                          )
                        else ...[
                          if (isMobile)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                0,
                                horizontalPadding,
                                16,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final member =
                                        _controller.visibleMembers[index];
                                    return AdminMemberMobileCard(
                                      member: member,
                                      isProcessing:
                                          _controller.processingUserId ==
                                              member.userId,
                                      onToggleStatus: _onToggleStatus,
                                    );
                                  },
                                  childCount: _controller.visibleMembers.length,
                                ),
                              ),
                            )
                          else if ((screenWidth - (horizontalPadding * 2)) >=
                              960.0) ...[
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding),
                              sliver: const SliverToBoxAdapter(
                                child: AdminMembersTableHeader(
                                    roundTopCorners: true),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                0,
                                horizontalPadding,
                                16,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final visible = _controller.visibleMembers;
                                    final member = visible[index];
                                    return AdminMembersTableRow(
                                      member: member,
                                      isProcessing:
                                          _controller.processingUserId ==
                                              member.userId,
                                      onToggleStatus: _onToggleStatus,
                                      framed: true,
                                      isLast: index == visible.length - 1,
                                    );
                                  },
                                  childCount: _controller.visibleMembers.length,
                                ),
                              ),
                            ),
                          ] else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                0,
                                horizontalPadding,
                                16,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: AdminMembersTable(
                                  members: _controller.visibleMembers,
                                  processingUserId: _controller.processingUserId,
                                  onToggleStatus: _onToggleStatus,
                                ),
                              ),
                            ),

                          // Rodapé do Infinite Scroll na aba de Membros
                          AppInfiniteScrollFooter(
                            hasMore: _controller.hasMoreMembers,
                            isLoadingMore: _controller.isLoadingMore,
                            showCompletedLabel: _controller.members.length >
                                AdminMembersController.pageSize,
                            loadingLabel: 'Carregando mais membros...',
                            idleLoadMoreLabel: 'Carregar mais membros',
                            completedLabel:
                                'Todos os ${_controller.members.length} membros foram carregados',
                            horizontalPadding: horizontalPadding,
                            onLoadMore: _controller.loadMoreMembers,
                          ),
                        ],
                      ],

                      // Aba 2: Solicitações de Troca de Steam
                      if (_controller.activeTab ==
                          AdminMembersTab.recoveryRequests) ...[
                        if (_controller.isLoadingRequests &&
                            _controller.recoveryRequests.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: AppLoadingState(
                                message:
                                    'Carregando solicitações de troca de Steam...',
                              ),
                            ),
                          )
                        else if (_controller.requestsError != null &&
                            _controller.recoveryRequests.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: AppEmptyState(
                                icon: Icons.error_outline_rounded,
                                title: 'Erro ao carregar solicitações',
                                message: _controller.requestsError!,
                                actionLabel: 'Tentar Novamente',
                                onActionPressed:
                                    _controller.fetchRecoveryRequests,
                              ),
                            ),
                          )
                        else if (_controller
                            .filteredRecoveryRequests.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: AppEmptyState(
                                icon: Icons.mark_email_read_outlined,
                                title: _controller.requestsSearchController.text
                                        .trim()
                                        .isNotEmpty
                                    ? 'Nenhuma solicitação encontrada'
                                    : 'Nenhuma solicitação pendente',
                                message: _controller.requestsSearchController.text
                                        .trim()
                                        .isNotEmpty
                                    ? 'Nenhuma solicitação corresponde ao termo pesquisado.'
                                    : 'Não há solicitações de troca de Steam registradas no momento.',
                                actionLabel: _controller.requestsSearchController
                                        .text
                                        .trim()
                                        .isNotEmpty
                                    ? 'Limpar Busca'
                                    : null,
                                onActionPressed: _controller
                                        .requestsSearchController
                                        .text
                                        .trim()
                                        .isNotEmpty
                                    ? _controller.requestsSearchController.clear
                                    : null,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              32,
                            ),
                            sliver: isMobile
                                ? SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final req = _controller
                                            .filteredRecoveryRequests[index];
                                        final member = _controller
                                            .getMemberByUserId(req.userId);
                                        return RecoveryRequestMobileCard(
                                          request: req,
                                          member: member,
                                          isProcessing: _controller
                                                  .processingRequestId ==
                                              req.id,
                                          onApprove: _onApproveRecovery,
                                          onReject: _onRejectRecovery,
                                        );
                                      },
                                      childCount: _controller
                                          .filteredRecoveryRequests.length,
                                    ),
                                  )
                                : SliverToBoxAdapter(
                                    child: RecoveryRequestsTable(
                                      requests:
                                          _controller.filteredRecoveryRequests,
                                      processingRequestId:
                                          _controller.processingRequestId,
                                      onApprove: _onApproveRecovery,
                                      onReject: _onRejectRecovery,
                                      getMember: _controller.getMemberByUserId,
                                    ),
                                  ),
                          ),
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
}
