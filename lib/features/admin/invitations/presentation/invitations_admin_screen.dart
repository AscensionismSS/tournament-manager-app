import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/invitations_controller.dart';
import '../models/invitation_dto.dart';
import 'create_invitation_dialog.dart';
import 'widgets/invitation_mobile_card.dart';
import 'widgets/invitation_table.dart';
import 'widgets/invitations_filter_bar.dart';

/// Tela administrativa oficial para gerenciamento e emissão de convites.
/// Layout harmônico com enquadramento ergonômico (maxWidth: 1380), Sticky Header e Infinite Scroll.
class InvitationsAdminScreen extends StatefulWidget {
  const InvitationsAdminScreen({super.key});

  @override
  State<InvitationsAdminScreen> createState() => _InvitationsAdminScreenState();
}

class _InvitationsAdminScreenState extends State<InvitationsAdminScreen> {
  late final InvitationsController _controller;
  final ScrollController _scrollController = ScrollController();
  Size? _lastViewportSize;
  bool _isFillCheckQueued = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller = InvitationsController();
    _controller.addListener(_scheduleViewportFillCheck);
    _controller.fetchInvitations();
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

    final scrolled = _scrollController.offset > 8.0;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
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

  Future<void> _openCreateDialog() async {
    await CreateInvitationDialog.show(context, controller: _controller);
  }

  Future<void> _handleRevoke(InvitationDto invite) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'REVOGAR CONVITE',
      message:
          'Deseja desativar o convite de "${invite.email}"? O código atual perderá a validade imediatamente.',
      confirmLabel: 'REVOGAR',
      cancelLabel: 'CANCELAR',
      isDestructive: true,
      icon: Icons.cancel_outlined,
    );

    if (confirm && mounted) {
      final success = await _controller.revokeInvitation(invite.id);
      if (mounted) {
        if (success) {
          AppFeedback.showSuccess(context, message: 'Convite revogado com sucesso.');
        } else {
          AppFeedback.showError(
            context,
            message: _controller.errorMessage ?? 'Falha ao revogar convite.',
          );
        }
      }
    }
  }

  void _copyToClipboard(InvitationDto invite) {
    Clipboard.setData(ClipboardData(text: invite.inviteLink));
    AppFeedback.showSuccess(
      context,
      message: 'Link de convite copiado para a área de transferência!',
    );
  }

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
    final availableWidth = AppPageLayout.availableWidth(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final visible = _controller.visibleInvitations;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra Integrada Fixa (Sticky Header) com Busca, Filtro de Status e Botão (46px)
              AppPageStickyBar(
                isScrolled: _isScrolled,
                horizontalPadding: horizontalPadding,
                child: InvitationsFilterBar(
                  controller: _controller,
                  onNewInvite: _openCreateDialog,
                ),
              ),

              // 2. Lista Virtualizada com Refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.fetchInvitations,
                  color: AppColors.primaryNeon,
                  backgroundColor: AppColors.surface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Espaçador inicial após a barra fixa
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),

                      // Estados de Loading / Erro / Vazio
                      if (_controller.isLoading && _controller.invitations.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppLoadingState(
                              message: 'Carregando convites da plataforma...',
                            ),
                          ),
                        )
                      else if (_controller.errorMessage != null &&
                          _controller.invitations.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.error_outline_rounded,
                              title: 'Erro ao carregar convites',
                              message: _controller.errorMessage!,
                              actionLabel: 'Tentar Novamente',
                              onActionPressed: _controller.fetchInvitations,
                            ),
                          ),
                        )
                      else if (_controller.invitations.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: AppEmptyState(
                              icon: Icons.mark_email_read_outlined,
                              title: 'Nenhum convite encontrado',
                              message: _controller.hasActiveFilters
                                  ? 'Nenhum convite corresponde aos filtros ou termo pesquisado.'
                                  : 'Nenhum convite cadastrado no sistema.',
                              actionLabel: _controller.hasActiveFilters
                                  ? 'LIMPAR FILTROS'
                                  : '+ CRIAR PRIMEIRO CONVITE',
                              onActionPressed: _controller.hasActiveFilters
                                  ? _controller.clearFilters
                                  : _openCreateDialog,
                            ),
                          ),
                        )
                      else ...[
                        // Lista de Convites (Cards Mobile ou Tabela Desktop Virtualizada via Slivers)
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
                                  final invite = visible[index];
                                  return InvitationMobileCard(
                                    invite: invite,
                                    isRevoking:
                                        _controller.revokingId == invite.id,
                                    onCopyCode: _copyToClipboard,
                                    onRevoke: _handleRevoke,
                                  );
                                },
                                childCount: visible.length,
                              ),
                            ),
                          )
                        else if (availableWidth >= 840.0) ...[
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            sliver: const SliverToBoxAdapter(
                              child:
                                  InvitationTableHeader(roundTopCorners: true),
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
                                  final invite = visible[index];
                                  return InvitationTableRow(
                                    invite: invite,
                                    isRevoking:
                                        _controller.revokingId == invite.id,
                                    onCopyCode: _copyToClipboard,
                                    onRevoke: _handleRevoke,
                                    framed: true,
                                    isLast: index == visible.length - 1,
                                  );
                                },
                                childCount: visible.length,
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
                              child: InvitationTable(
                                invitations: visible,
                                revokingId: _controller.revokingId,
                                onCopyCode: _copyToClipboard,
                                onRevoke: _handleRevoke,
                              ),
                            ),
                          ),

                        // Rodapé de Paginação Progressiva (Infinite Scroll)
                        AppInfiniteScrollFooter(
                          hasMore: _controller.hasMore,
                          isLoadingMore: _controller.isLoadingMore,
                          showCompletedLabel: _controller.invitations.length >
                              InvitationsController.pageSize,
                          loadingLabel: 'Carregando mais convites...',
                          idleLoadMoreLabel: 'Carregar mais convites',
                          completedLabel:
                              'Todos os ${_controller.invitations.length} convites foram carregados',
                          horizontalPadding: horizontalPadding,
                          onLoadMore: _controller.loadMore,
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
