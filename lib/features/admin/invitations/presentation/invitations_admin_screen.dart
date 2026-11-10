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
/// Layout harmônico: barra de busca padronizada com botão "+ NOVO CONVITE" de 46px ao lado,
/// abas de filtro clicáveis com contadores e modal completo com switch de horas (24h/48h/72h).
class InvitationsAdminScreen extends StatefulWidget {
  const InvitationsAdminScreen({super.key});

  @override
  State<InvitationsAdminScreen> createState() => _InvitationsAdminScreenState();
}

class _InvitationsAdminScreenState extends State<InvitationsAdminScreen> {
  late final InvitationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InvitationsController();
    _controller.fetchInvitations();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreateDialog() async {
    final created = await CreateInvitationDialog.show(context, controller: _controller);
    if (created == true && mounted) {
      await _controller.fetchInvitations();
    }
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 780;
    final horizontalPadding = isMobile ? 16.0 : 28.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _controller.fetchInvitations,
            color: AppColors.primaryNeon,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Barra Integrada de Busca, Filtro de Status (AppSelectBox) e Botão de Ação (46px)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      16,
                    ),
                    child: InvitationsFilterBar(
                      controller: _controller,
                      onNewInvite: _openCreateDialog,
                    ),
                  ),
                ),

                // 2. Estados de Loading / Erro / Vazio
                if (_controller.isLoading && _controller.invitations.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppLoadingState(
                        message: 'Carregando convites da plataforma...',
                      ),
                    ),
                  )
                else if (_controller.errorMessage != null && _controller.invitations.isEmpty)
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
                else
                  // 4. Lista de Convites (Tabela Desktop ou Cards Mobile)
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
                                final invite = _controller.invitations[index];
                                return InvitationMobileCard(
                                  invite: invite,
                                  isRevoking: _controller.revokingId == invite.id,
                                  onCopyCode: _copyToClipboard,
                                  onRevoke: _handleRevoke,
                                );
                              },
                              childCount: _controller.invitations.length,
                            ),
                          )
                        : SliverToBoxAdapter(
                            child: InvitationTable(
                              invitations: _controller.invitations,
                              revokingId: _controller.revokingId,
                              onCopyCode: _copyToClipboard,
                              onRevoke: _handleRevoke,
                            ),
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
