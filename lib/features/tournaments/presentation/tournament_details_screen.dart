import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_mode.dart';
import '../../../core/network/tournament_events_service.dart';
import '../../../core/network/tournament_webhook_event_dto.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/theme.dart';
import '../controllers/tournament_details_controller.dart';
import '../models/tournament_dto.dart';
import '../../auth/models/login_response.dart';
import '../../draft/presentation/widgets/draft_redirect_card.dart';
import 'widgets/tournament_action_dialogs.dart';
import 'widgets/tournament_details_header.dart';
import 'widgets/tournament_group_stage_tab.dart';
import 'widgets/tournament_matches_tab.dart';
import 'widgets/tournament_overview_tab.dart';
import 'widgets/tournament_player_pool_tab.dart';
import 'widgets/tournament_playoffs_tab.dart';
import 'widgets/tournament_teams_tab.dart';

/// Página interna do Campeonato (`/tournaments/:id`) em Modo Híbrido (Jogador & Controles Rápidos Admin).
/// Enxuta e modular (SRP & Dumb UI).
class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentId;
  final TournamentDto? initialTournament;
  final TournamentDetailTab initialTab;

  const TournamentDetailsScreen({
    super.key,
    required this.tournamentId,
    this.initialTournament,
    this.initialTab = TournamentDetailTab.overview,
  });

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  late final TournamentDetailsController _controller;
  bool _hasNotifiedPlayoffsReady = false;

  @override
  void initState() {
    super.initState();
    TokenStorage.getUserProfile();
    _controller = TournamentDetailsController(
      tournamentId: widget.tournamentId,
      initialTournament: widget.initialTournament,
      initialTab: widget.initialTab,
    );
    _controller.addListener(_onControllerUpdated);
    _controller.fetchTournament();
  }

  void _onControllerUpdated() {
    if (!mounted) return;
    final canManage =
        TokenStorage.profileNotifier.value?.canManageTournaments ?? false;
    final t = _controller.tournament;
    if (canManage &&
        t != null &&
        _controller.canAdvanceToPlayoffs &&
        !_hasNotifiedPlayoffsReady) {
      _hasNotifiedPlayoffsReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        TournamentEventsService.instance.pushNotification(
          TournamentWebhookEventDto(
            tournamentId: t.id,
            tournamentName: t.name,
            eventType: 'GroupStageCompleted',
            message:
                'Fase de Grupos 100% concluída (${_controller.groupStageProgressLabel})! Clique em "GERAR PLAYOFFS" para avançar o campeonato.',
            version: 999,
            status: t.status.name,
            timestampUtc: DateTime.now().toUtc(),
          ),
        );
      });
    } else if (!_controller.canAdvanceToPlayoffs) {
      _hasNotifiedPlayoffsReady = false;
    }
  }

  @override
  void didUpdateWidget(covariant TournamentDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _controller.setActiveTab(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdated);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;

    return ValueListenableBuilder<LoginResponse?>(
      valueListenable: TokenStorage.profileNotifier,
      builder: (context, userProfile, _) {
        final canManage = userProfile?.canManageTournaments ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.tournament;

              if (_controller.isLoading && t == null) {
                return const Center(
                  child: AppLoadingState(
                    message: 'Carregando dados do campeonato...',
                  ),
                );
              }

              if (_controller.errorMessage != null && t == null) {
                return Center(
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Erro ao carregar campeonato',
                    message: _controller.errorMessage!,
                    actionLabel: 'Tentar Novamente',
                    onActionPressed: _controller.fetchTournament,
                  ),
                );
              }

              if (t == null) return const SizedBox.shrink();

              return RefreshIndicator(
                onRefresh: _controller.fetchTournament,
                color: AppColors.primaryNeon,
                backgroundColor: AppColors.surface,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TournamentDetailsHeader(
                            tournament: t,
                            controller: _controller,
                            canManage: canManage,
                            onBack: () {
                              final isFromAdmin = GoRouterState.of(context).uri.queryParameters['from'] == 'admin' ||
                                  (AppModeState.isAdmin && canManage);
                              if (isFromAdmin && canManage) {
                                AppModeState.setMode(AppMode.admin);
                                context.go('/admin/tournaments');
                              } else {
                                AppModeState.setMode(AppMode.player);
                                context.go('/tournaments');
                              }
                            },
                            onSelectTab: (tab) {
                              if (tab == TournamentDetailTab.draft) {
                                TournamentActionDialogs.openDraftRoom(context, t);
                                return;
                              }
                              _controller.setActiveTab(tab);
                              final isFromAdmin = GoRouterState.of(context).uri.queryParameters['from'] == 'admin' ||
                                  (AppModeState.isAdmin && canManage);
                              final query = isFromAdmin ? '?from=admin' : '';
                              context.go(
                                '/tournaments/${widget.tournamentId}/${tab.slug}$query',
                                extra: t,
                              );
                            },
                            onRegisterAction: () =>
                                TournamentActionDialogs.register(
                              context,
                              _controller,
                              t,
                            ),
                            onOpenRegistrations: () =>
                                TournamentActionDialogs.openRegistrations(
                              context,
                              _controller,
                            ),
                            onCloseRegistrations: () =>
                                TournamentActionDialogs.closeRegistrations(
                              context,
                              _controller,
                            ),
                            onStartTournament: () =>
                                TournamentActionDialogs.startTournament(
                              context,
                              _controller,
                            ),
                            onOpenDraftRoom: () =>
                                TournamentActionDialogs.openDraftRoom(
                              context,
                              t,
                            ),
                            onAdvanceToPlayoffs: () =>
                                TournamentActionDialogs.advanceToPlayoffs(
                              context,
                              _controller,
                            ),
                            onRevertToGroupStage: () =>
                                TournamentActionDialogs.revertToGroupStage(
                              context,
                              _controller,
                            ),
                            onCancelTournament: () =>
                                TournamentActionDialogs.cancelTournament(
                              context,
                              _controller,
                            ),
                            onDeleteTournament: () =>
                                TournamentActionDialogs.deleteTournament(
                              context,
                              _controller,
                            ),
                            onLockResults: () =>
                                TournamentActionDialogs.lockResults(
                              context,
                              _controller,
                            ),
                            onUnlockResults: () =>
                                TournamentActionDialogs.unlockResults(
                              context,
                              _controller,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActiveTabContent(t, canManage: canManage),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveTabContent(TournamentDto t, {required bool canManage}) {
    switch (_controller.activeTab) {
      case TournamentDetailTab.overview:
        return TournamentOverviewTab(tournament: t);
      case TournamentDetailTab.playerPool:
        return TournamentPlayerPoolTab(tournament: t);
      case TournamentDetailTab.draft:
        return DraftRedirectCard(
          tournament: t,
          onOpenDraftRoom: () =>
              TournamentActionDialogs.openDraftRoom(context, t),
        );
      case TournamentDetailTab.teams:
        return TournamentTeamsTab(
          tournament: t,
          draftSnapshot: _controller.draftSnapshot,
          canManage: canManage,
        );
      case TournamentDetailTab.groupStage:
        return TournamentGroupStageTab(
          tournament: t,
          groupTables: _controller.groupTables,
        );
      case TournamentDetailTab.matches:
        return TournamentMatchesTab(
          tournament: t,
          matches: _controller.matches,
          draftTeams: _controller.draftSnapshot?.teams,
          isAdmin: canManage,
          onRecordResult: canManage
              ? (match, gIdx) => TournamentActionDialogs.recordResult(
                    context,
                    _controller,
                    match,
                    gIdx,
                  )
              : null,
          onEditResult: canManage
              ? (match, gIdx) => TournamentActionDialogs.editResult(
                    context,
                    _controller,
                    match,
                    gIdx,
                  )
              : null,
        );
      case TournamentDetailTab.playoffs:
        return TournamentPlayoffsTab(
          tournament: t,
          controller: _controller,
          canManage: canManage,
          onRecordResult: canManage
              ? (match, gIdx) => TournamentActionDialogs.recordResult(
                    context,
                    _controller,
                    match,
                    gIdx,
                  )
              : null,
          onEditResult: canManage
              ? (match, gIdx) => TournamentActionDialogs.editResult(
                    context,
                    _controller,
                    match,
                    gIdx,
                  )
              : null,
        );
    }
  }
}
