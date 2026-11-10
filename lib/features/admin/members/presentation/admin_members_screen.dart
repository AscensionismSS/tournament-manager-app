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

  @override
  void initState() {
    super.initState();
    _controller = AdminMembersController(initialTab: widget.initialTab);
    _controller.fetchMembers();
    _controller.fetchRecoveryRequests();
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 800;
    final horizontalPadding = isMobile ? 16.0 : 28.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return RefreshIndicator(
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
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Abas Superiores (Membros vs Troca de Steam)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 14),
                    child: AdminMembersTabSwitcher(
                      activeTab: _controller.activeTab,
                      onTabChanged: (tab) {
                        _controller.setActiveTab(tab);
                        final targetPath = tab == AdminMembersTab.recoveryRequests
                            ? '/admin/members?tab=requests'
                            : '/admin/members';
                        final currentUri = GoRouterState.of(context).uri.toString();
                        if (currentUri != targetPath) {
                          context.go(targetPath);
                        }
                      },
                      pendingRequestsCount: _controller.pendingRequestsCount,
                    ),
                  ),
                ),

                // 2. Conteúdo da Aba 1: Gestão de Membros
                if (_controller.activeTab == AdminMembersTab.members) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 16),
                      child: AdminMembersFilterBar(controller: _controller),
                    ),
                  ),

                  if (_controller.isLoadingMembers && _controller.members.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppLoadingState(
                          message: 'Carregando membros da arena...',
                        ),
                      ),
                    )
                  else if (_controller.membersError != null && _controller.members.isEmpty)
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
                          actionLabel: _controller.hasActiveMemberFilters ? 'Limpar Filtros' : null,
                          onActionPressed:
                              _controller.hasActiveMemberFilters ? _controller.clearFilters : null,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
                      sliver: isMobile
                          ? SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final member = _controller.members[index];
                                  return AdminMemberMobileCard(
                                    member: member,
                                    isProcessing: _controller.processingUserId == member.userId,
                                    onToggleStatus: _onToggleStatus,
                                  );
                                },
                                childCount: _controller.members.length,
                              ),
                            )
                          : SliverToBoxAdapter(
                              child: AdminMembersTable(
                                members: _controller.members,
                                processingUserId: _controller.processingUserId,
                                onToggleStatus: _onToggleStatus,
                              ),
                            ),
                    ),
                ],

                // 3. Conteúdo da Aba 2: Solicitações de Troca de Steam
                if (_controller.activeTab == AdminMembersTab.recoveryRequests) ...[
                  // Barra de busca dedicada de solicitações (nome ou e-mail)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 16),
                      child: AppSearchBar(
                        controller: _controller.requestsSearchController,
                        labelText: 'Buscar solicitações',
                        hintText: 'Digite o nome do jogador ou e-mail...',
                        onSearch: (_) => _controller.fetchRecoveryRequests(),
                        isLoading: _controller.isLoadingRequests,
                      ),
                    ),
                  ),

                  if (_controller.isLoadingRequests && _controller.recoveryRequests.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppLoadingState(
                          message: 'Carregando solicitações de troca de Steam...',
                        ),
                      ),
                    )
                  else if (_controller.requestsError != null && _controller.recoveryRequests.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppEmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Erro ao carregar solicitações',
                          message: _controller.requestsError!,
                          actionLabel: 'Tentar Novamente',
                          onActionPressed: _controller.fetchRecoveryRequests,
                        ),
                      ),
                    )
                  else if (_controller.filteredRecoveryRequests.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppEmptyState(
                          icon: Icons.mark_email_read_outlined,
                          title: _controller.requestsSearchController.text.trim().isNotEmpty
                              ? 'Nenhuma solicitação encontrada'
                              : 'Nenhuma solicitação pendente',
                          message: _controller.requestsSearchController.text.trim().isNotEmpty
                              ? 'Nenhuma solicitação corresponde ao termo pesquisado.'
                              : 'Não há solicitações de troca de Steam registradas no momento.',
                          actionLabel: _controller.requestsSearchController.text.trim().isNotEmpty
                              ? 'Limpar Busca'
                              : null,
                          onActionPressed: _controller.requestsSearchController.text.trim().isNotEmpty
                              ? _controller.requestsSearchController.clear
                              : null,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
                      sliver: isMobile
                          ? SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final req = _controller.filteredRecoveryRequests[index];
                                  final member = _controller.getMemberByUserId(req.userId);
                                  return RecoveryRequestMobileCard(
                                    request: req,
                                    member: member,
                                    isProcessing: _controller.processingRequestId == req.id,
                                    onApprove: _onApproveRecovery,
                                    onReject: _onRejectRecovery,
                                  );
                                },
                                childCount: _controller.filteredRecoveryRequests.length,
                              ),
                            )
                          : SliverToBoxAdapter(
                              child: RecoveryRequestsTable(
                                requests: _controller.filteredRecoveryRequests,
                                processingRequestId: _controller.processingRequestId,
                                onApprove: _onApproveRecovery,
                                onReject: _onRejectRecovery,
                                getMember: _controller.getMemberByUserId,
                              ),
                            ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
