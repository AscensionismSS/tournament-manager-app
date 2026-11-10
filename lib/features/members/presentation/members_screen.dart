import 'package:flutter/material.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import '../controllers/members_controller.dart';
import '../models/member_dto.dart';
import 'widgets/members_filter_bar.dart';

/// Tela oficial de Membros da Comunidade / Times (SRP).
/// Focada exclusivamente em renderização e composição de sub-widgets (Dumb UI).
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late final MembersController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MembersController();
    _controller.fetchMembers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isMobile = screenWidth < 540;
    final double horizontalPadding = isMobile ? 16.0 : 24.0;
    const double cardHeight = 176.0;

    final double availableWidth = screenWidth - (horizontalPadding * 2);
    final int crossAxisCount = availableWidth < 960 ? 1 : (availableWidth < 1500 ? 2 : 3);
    const double crossAxisSpacing = 18.0;
    final double itemWidth = crossAxisCount == 1
        ? availableWidth
        : (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) / crossAxisCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _controller.fetchMembers,
            color: AppColors.primaryNeon,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Cabeçalho Superior Fixo e Área de Filtros (Sub-widget modular)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 14),
                    child: MembersFilterBar(controller: _controller),
                  ),
                ),

                // 2. Estados de Loading / Erro / Vazio
                if (_controller.isLoading && _controller.members.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppLoadingState(
                        message: 'Carregando membros da arena...',
                      ),
                    ),
                  )
                else if (_controller.errorMessage != null && _controller.members.isEmpty)
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
                        message: 'Nenhum membro corresponde aos filtros ou termo de busca informado.',
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
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 12),
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
                              height: cardHeight,
                              child: _buildMemberCard(_controller.myMember!),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Divisória estética isolando o próprio perfil dos demais jogadores
                  if (_controller.myMember != null && _controller.otherMembers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 22),
                        child: const AppDivider.neon(),
                      ),
                    ),

                  // 4. Seção dos Demais Membros da Comunidade
                  if (_controller.otherMembers.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 14),
                        child: AppSectionHeader(
                          title: _controller.myMember != null
                              ? 'OUTROS JOGADORES DA COMUNIDADE'
                              : 'JOGADORES ENCONTRADOS',
                          countLabel:
                              '${_controller.otherMembers.length} ${_controller.otherMembers.length == 1 ? "jogador" : "jogadores"}',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
                      sliver: crossAxisCount == 1
                          ? SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final member = _controller.otherMembers[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: SizedBox(
                                      width: itemWidth,
                                      height: cardHeight,
                                      child: _buildMemberCard(member),
                                    ),
                                  );
                                },
                                childCount: _controller.otherMembers.length,
                              ),
                            )
                          : SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: cardHeight,
                                crossAxisSpacing: crossAxisSpacing,
                                mainAxisSpacing: 18,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final member = _controller.otherMembers[index];
                                  return _buildMemberCard(member);
                                },
                                childCount: _controller.otherMembers.length,
                              ),
                            ),
                    ),
                  ],
                ],
              ],
            ),
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
