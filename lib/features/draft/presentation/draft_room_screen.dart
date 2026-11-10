import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/theme.dart';
import '../../tournaments/models/tournament_dto.dart';
import '../../tournaments/models/tournament_status.dart';
import '../controllers/draft_controller.dart';
import '../models/draft_state_snapshot_dto.dart';
import 'draft_starters_completed_dialog.dart';
import 'widgets/draft_captains_phase_view.dart';
import 'widgets/draft_header_stepper.dart';
import 'widgets/draft_order_selection_dialog.dart';
import 'widgets/draft_starters_phase_view.dart';

/// Tela dedicada em tela cheia para a Sala de Draft oficial da Arena (SRP & Dumb UI).
/// Proporciona espaço amplo para visualização das equipes, HUD em tempo real e o Bucket lateral de jogadores.
class DraftRoomScreen extends StatefulWidget {
  final String tournamentId;
  final TournamentDto? initialTournament;

  const DraftRoomScreen({
    super.key,
    required this.tournamentId,
    this.initialTournament,
  });

  @override
  State<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends State<DraftRoomScreen> {
  TournamentDto? _tournament;
  late final DraftController _draftController;
  bool _isLoadingTournament = false;
  String? _tournamentError;

  @override
  void initState() {
    super.initState();
    TokenStorage.getUserProfile();
    _tournament = widget.initialTournament;
    _draftController = DraftController();

    if (_tournament != null && _tournament!.draftSessionId != null) {
      _draftController.fetchSnapshot(_tournament!.draftSessionId!);
    } else {
      _loadTournamentAndDraft();
    }
  }

  Future<void> _loadTournamentAndDraft() async {
    setState(() {
      _isLoadingTournament = true;
      _tournamentError = null;
    });

    try {
      final response = await ApiClient.get(
        ApiEndpoints.tournamentById(widget.tournamentId),
      );
      final t = TournamentDto.fromJson(response);
      if (mounted) {
        setState(() {
          _tournament = t;
          _isLoadingTournament = false;
        });

        if (t.draftSessionId != null) {
          await _draftController.fetchSnapshot(t.draftSessionId!);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _tournamentError = e.message;
          _isLoadingTournament = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tournamentError = 'Falha ao carregar campeonato: $e';
          _isLoadingTournament = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  void _onBack() {
    context.go('/tournaments/${widget.tournamentId}');
  }

  Future<void> _handleAdvanceToOrder() async {
    final snapshot = _draftController.snapshot;
    if (snapshot == null) return;

    final confirmed = await DraftOrderSelectionDialog.show(
      context,
      snapshot: snapshot,
      onConfirm: ({
        required int orderType,
        List<String>? manualOrderIds,
      }) {
        return _draftController.finalizeCaptainOrder(
          orderType: orderType,
          manualOrderIds: manualOrderIds,
        );
      },
    );

    if (confirmed == true && mounted) {
      AppFeedback.showSuccess(
        context,
        message: 'Ordem do Snake Draft confirmada com sucesso!',
      );
    }
  }

  Future<void> _handleCompleteDraft() async {
    final snapshot = _draftController.snapshot;
    if (snapshot?.substitutingPlayerId != null) {
      AppFeedback.showWarning(
        context,
        message: 'Cancele ou conclua a substituição ativa antes de encerrar o draft.',
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Concluir Draft e Iniciar Campeonato?',
      message:
          'Deseja encerrar o draft, consolidar as equipes e gerar a tabela/chaves de partidas do campeonato?',
      confirmLabel: 'Concluir e Gerar Partidas',
      cancelLabel: 'Continuar no Draft',
    );

    if (confirmed == true && mounted) {
      final error = await _draftController.completeDraft(startTournament: true);
      if (!mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message:
              'Draft concluído com sucesso! Equipes consolidadas no campeonato.',
        );
        context.go('/tournaments/${widget.tournamentId}/teams');
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  Widget? _buildStepAction(DraftStateSnapshotDto snapshot, bool canManage) {
    if (!canManage) return null;

    // Se o draft já estiver concluído, disponibiliza o atalho rápido para ver as equipes
    if (snapshot.isCompleted) {
      return AppButton(
        text: 'VER EQUIPES DO CAMPEONATO',
        icon: Icons.groups_rounded,
        size: AppButtonSize.small,
        variant: AppButtonVariant.primary,
        customColor: AppColors.dotaGold,
        onPressed: () => context.go('/tournaments/${widget.tournamentId}/teams'),
      );
    }

    // Etapa 1 & 2: Definir ordem do Snake Draft
    if ((snapshot.isSelectingCaptains && snapshot.allCaptainsAssigned) ||
        snapshot.isCaptainOrderSelection) {
      return AppButton(
        text: 'DEFINIR ORDEM DO DRAFT',
        icon: Icons.arrow_forward_rounded,
        size: AppButtonSize.small,
        variant: AppButtonVariant.primary,
        isLoading: _draftController.isActionInProgress,
        onPressed: _handleAdvanceToOrder,
      );
    }

    // Etapa 3: Titulares (Snake) -> Botão para avançar para Reservas
    if (snapshot.isDraftingStarters || snapshot.currentStepNumber == 3) {
      final bool allPicked = snapshot.allStartersPicked;

      return AppButton(
        text: 'AVANÇAR PARA RESERVAS',
        icon: Icons.arrow_forward_rounded,
        size: AppButtonSize.small,
        variant: allPicked ? AppButtonVariant.primary : AppButtonVariant.secondary,
        customColor: allPicked ? AppColors.dotaGold : null,
        isLoading: _draftController.isActionInProgress,
        onPressed: allPicked
            ? () => DraftStartersCompletedDialog.show(
                  context,
                  controller: _draftController,
                  snapshot: snapshot,
                )
            : null,
      );
    }

    // Etapa 4: Reservas & Conclusão -> Botão para Concluir Draft
    if (snapshot.isDraftingSubstitutes || snapshot.currentStepNumber == 4) {
      return AppButton(
        text: 'CONCLUIR DRAFT & INICIAR',
        icon: Icons.check_circle_outline_rounded,
        size: AppButtonSize.small,
        variant: AppButtonVariant.primary,
        customColor: AppColors.dotaGold,
        isLoading: _draftController.isActionInProgress,
        onPressed: _handleCompleteDraft,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Validação de Resolução Mínima HD (Mínimo 1200x520 para visualização do tabuleiro de draft)
    final screenSize = MediaQuery.sizeOf(context);
    const double minSupportedWidth = 1200.0;
    const double minSupportedHeight = 520.0;
    if (screenSize.width < minSupportedWidth ||
        screenSize.height < minSupportedHeight) {
      return _buildResolutionBlockedScreen(
        screenSize.width,
        screenSize.height,
      );
    }

    final canManage =
        TokenStorage.profileNotifier.value?.canManageTournaments ?? false;

    if (_isLoadingTournament && _tournament == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: AppLoadingState(message: 'Carregando dados do campeonato...'),
        ),
      );
    }

    if (_tournamentError != null && _tournament == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Erro ao carregar campeonato',
            message: _tournamentError!,
            actionLabel: 'Tentar Novamente',
            onActionPressed: _loadTournamentAndDraft,
          ),
        ),
      );
    }

    final t = _tournament;
    if (t == null || t.draftSessionId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: AppEmptyState(
            icon: Icons.shuffle_rounded,
            title: 'SESSÃO DE DRAFT NÃO ENCONTRADA',
            message: 'Este campeonato não possui uma sessão de draft válida.',
            actionLabel: 'Voltar ao Campeonato',
            onActionPressed: _onBack,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _draftController,
          builder: (context, _) {
            if (_draftController.isLoading && _draftController.snapshot == null) {
              return const Center(
                child: AppLoadingState(
                  message: 'Conectando à Sala de Draft em tempo real...',
                ),
              );
            }

            if (_draftController.errorMessage != null &&
                _draftController.snapshot == null) {
              return Center(
                child: AppEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Erro ao carregar estado do Draft',
                  message: _draftController.errorMessage!,
                  actionLabel: 'Tentar Novamente',
                  onActionPressed: () =>
                      _draftController.fetchSnapshot(t.draftSessionId!),
                ),
              );
            }

            final snapshot = _draftController.snapshot;
            if (snapshot == null) {
              return const Center(
                child: AppEmptyState(
                  icon: Icons.hourglass_empty_rounded,
                  title: 'AGUARDANDO DADOS DO DRAFT',
                  message: 'Nenhum snapshot de draft recebido.',
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Barra de Navegação Superior da Sala de Draft
                      _buildTopNavigationHeader(t, snapshot),

                      const SizedBox(height: 12),

                      // 2. Stepper das 4 Etapas com Ação Integrada de Avanço
                      DraftHeaderStepper(
                        currentStep: snapshot.currentStepNumber,
                        stateLabel: snapshot.state,
                        action: _buildStepAction(snapshot, canManage),
                      ),

                      const SizedBox(height: 14),

                      // 3. Conteúdo Principal com Espaço Amplo (Teams Grid + Player Bucket)
                      Expanded(
                        child: (snapshot.currentStepNumber >= 3 ||
                                snapshot.isDraftingStarters ||
                                snapshot.isDraftingSubstitutes ||
                                snapshot.isCompleted)
                            ? DraftStartersPhaseView(
                                controller: _draftController,
                                snapshot: snapshot,
                                canManage: canManage,
                                isLockedByPlayoffs: t.status ==
                                        TournamentStatus.playoffs ||
                                    t.status == TournamentStatus.completed,
                              )
                            : DraftCaptainsPhaseView(
                                controller: _draftController,
                                snapshot: snapshot,
                                canManage: canManage,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopNavigationHeader(
    TournamentDto tournament,
    dynamic snapshot,
  ) {
    return Row(
      children: [
        // Botão Voltar para o Campeonato
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onBack,
            borderRadius: BorderRadius.circular(6),
            hoverColor: AppColors.primaryNeon.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryNeon.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 15,
                    color: AppColors.primaryNeon,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'VOLTAR AO CAMPEONATO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Título do Campeonato
        Expanded(
          child: Text(
            tournament.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Badge de Sala Oficial
        const AppBadge(
          label: 'SALA OFICIAL DE DRAFT',
          variant: AppBadgeVariant.neutral,
          customColor: AppColors.dotaGold,
        ),
      ],
    );
  }

  /// Tela informativa exibida quando a resolução for inferior a HD (1280x720) ou em mobile,
  /// instruindo o usuário a maximizar a janela ou acessar em um computador.
  Widget _buildResolutionBlockedScreen(
    double currentWidth,
    double currentHeight,
  ) {
    final tournamentName = _tournament?.name ?? widget.initialTournament?.name;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botão Voltar ao Campeonato no topo
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _onBack,
                        borderRadius: BorderRadius.circular(6),
                        hoverColor:
                            AppColors.primaryNeon.withValues(alpha: 0.12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryNeon.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  AppColors.primaryNeon.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_rounded,
                                size: 15,
                                color: AppColors.primaryNeon,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'VOLTAR AO CAMPEONATO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cartão Principal de Bloqueio por Resolução
                  AppCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Ícone Monitor / Desktop com Glow
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                AppColors.primaryNeon.withValues(alpha: 0.12),
                            border: Border.all(
                              color:
                                  AppColors.primaryNeon.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNeon
                                    .withValues(alpha: 0.15),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.desktop_windows_outlined,
                            size: 32,
                            color: AppColors.primaryNeon,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'SALA DE DRAFT REQUER TELA HD',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),

                        if (tournamentName != null &&
                            tournamentName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            tournamentName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.dotaGold,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        const Text(
                          'A Sala Oficial de Draft foi projetada exclusivamente para computadores e monitores com resolução mínima HD (1280x720) para assegurar a visualização tática de todas as equipes, slots e pool de jogadores sem cortes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Painel comparativo de resolução
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Resolução Atual
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'SUA RESOLUÇÃO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${currentWidth.toInt()} x ${currentHeight.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.feedbackError,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const AppBadge(
                                      label: 'INSUFICIENTE',
                                      variant: AppBadgeVariant.error,
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                width: 1,
                                height: 50,
                                color: AppColors.border.withValues(alpha: 0.4),
                              ),

                              // Resolução Mínima
                              const Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'MÍNIMO EXIGIDO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '1280 x 720 (HD)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.dotaGoldLight,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    AppBadge(
                                      label: 'REQUERIDO',
                                      variant: AppBadgeVariant.neutral,
                                      customColor: AppColors.dotaGold,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Dicas de ação
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dotaGold.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.dotaGold.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.dotaGoldLight,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Se estiver no computador, maximize a janela do navegador ou diminua o zoom. Em celulares, acesse pelo computador.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Botão de ação
                        AppButton(
                          text: 'VOLTAR AO CAMPEONATO',
                          icon: Icons.arrow_back_rounded,
                          size: AppButtonSize.medium,
                          variant: AppButtonVariant.primary,
                          onPressed: _onBack,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

