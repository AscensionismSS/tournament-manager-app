import 'package:flutter/material.dart';
import '../../../../core/services/system_security_service.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/draft_controller.dart';
import '../../models/draft_player_dto.dart';
import '../../models/draft_state_snapshot_dto.dart';
import '../../models/draft_team_dto.dart';
import 'add_late_player_dialog.dart';
import 'draft_player_bucket.dart';
import 'draft_team_starters_card.dart';
import 'draft_turn_hud_banners.dart';

/// Visão da Fase 3 do Draft: Escolha de Titulares no formato Snake Draft (SRP & Dumb UI).
/// Segue a mesma excelência de layout e ergonomia da Fase de Capitães:
/// - À esquerda: Grid responsivo de Equipes exibindo o Capitão já definido e os 4 placeholders/titulares.
/// - Destaque em Ouro/Aegis para a Equipe que possui o Turno Atual de Escolha.
/// - À direita: Bucket oficial de jogadores com busca, filtros de roles e adição via [+].
class DraftStartersPhaseView extends StatefulWidget {
  final DraftController controller;
  final DraftStateSnapshotDto snapshot;
  final bool canManage;
  final bool isLockedByPlayoffs;

  const DraftStartersPhaseView({
    super.key,
    required this.controller,
    required this.snapshot,
    required this.canManage,
    this.isLockedByPlayoffs = false,
  });

  @override
  State<DraftStartersPhaseView> createState() => _DraftStartersPhaseViewState();
}

class _DraftStartersPhaseViewState extends State<DraftStartersPhaseView> {
  bool _isBucketVisible = true;
  bool _isBucketExpanded = false;
  bool _isMutating = false;
  String? _lastTurnTeamId;
  String? _selectedTeamForReserveId;

  // Gerenciamento local seguro de substituição para reservas:
  // Garante a mesma ergonomia visual e bloqueio dos titulares, sem estourar o DomainException do backend.
  DraftPlayerDto? _substitutingReservePlayer;
  String? _substitutingReserveTeamId;

  @override
  void initState() {
    super.initState();
    if (widget.snapshot.currentTurnTeamId != null) {
      _lastTurnTeamId = widget.snapshot.currentTurnTeamId;
    }
    if (_selectedTeamForReserveId == null && widget.snapshot.teams.isNotEmpty) {
      _selectedTeamForReserveId = widget.snapshot.teams.first.id;
    }
  }

  @override
  void didUpdateWidget(DraftStartersPhaseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot.currentTurnTeamId != null) {
      _lastTurnTeamId = widget.snapshot.currentTurnTeamId;
    }
    if (_selectedTeamForReserveId == null && widget.snapshot.teams.isNotEmpty) {
      _selectedTeamForReserveId = widget.snapshot.teams.first.id;
    }
    // Se o jogador reserva em substituição não estiver mais presente, limpa o estado
    if (_substitutingReservePlayer != null && _substitutingReserveTeamId != null) {
      final team = widget.snapshot.teams
          .where((t) => t.id == _substitutingReserveTeamId)
          .firstOrNull;
      final stillInReserves =
          team?.reserves.any((p) => p.id == _substitutingReservePlayer!.id) ??
              false;
      if (!stillInReserves) {
        _substitutingReservePlayer = null;
        _substitutingReserveTeamId = null;
      }
    }
  }

  double get _bucketWidth => _isBucketExpanded ? 540.0 : 360.0;

  String? get _activeSubstitutingPlayerId =>
      widget.snapshot.substitutingPlayerId ?? _substitutingReservePlayer?.id;

  String? get _activeSubstitutingTeamId =>
      widget.snapshot.substitutingTeamId ?? _substitutingReserveTeamId;

  bool get _isAnySubstituting => _activeSubstitutingPlayerId != null;

  DraftTeamDto? get _effectiveTurnTeam {
    final turnId = widget.snapshot.currentTurnTeamId ?? _lastTurnTeamId;
    if (turnId == null) return null;
    for (final t in widget.snapshot.teams) {
      if (t.id == turnId) return t;
    }
    return null;
  }

  DraftTeamDto? get _selectedReserveTeam {
    final id = _selectedTeamForReserveId ?? widget.snapshot.teams.firstOrNull?.id;
    if (id == null) return null;
    for (final t in widget.snapshot.teams) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _handlePlayerAction(
    DraftPlayerDto player,
    String? targetTeamId,
  ) async {
    if (_isMutating) return;
    _isMutating = true;

    try {
      // 1. Caso A: Substituição ativa de um jogador RESERVA
      if (_substitutingReservePlayer != null) {
        final reserveTeamId = _substitutingReserveTeamId!;
        final outReservePlayer = _substitutingReservePlayer!;

        final removeError = await widget.controller.removeReserve(
          teamId: reserveTeamId,
          playerId: outReservePlayer.id,
        );

        if (removeError != null) {
          if (mounted) {
            AppFeedback.showError(context, message: removeError);
          }
          return;
        }

        final allocateError = await widget.controller.allocateReserve(
          teamId: reserveTeamId,
          playerId: player.id,
        );

        if (!mounted) return;

        setState(() {
          _substitutingReservePlayer = null;
          _substitutingReserveTeamId = null;
        });

        if (allocateError == null) {
          AppFeedback.showSuccess(
            context,
            message: '${player.name} substituiu ${outReservePlayer.name} na reserva!',
          );
        } else {
          AppFeedback.showError(context, message: allocateError);
        }
        return;
      }

      // 2. Caso B: Substituição de Titular ativa (Backend)
      final bool isStarterSubstitution =
          widget.snapshot.substitutingPlayerId != null;

      final String? error;
      if (isStarterSubstitution) {
        error = await widget.controller.confirmSubstitution(
          inPlayerId: player.id,
        );
      } else if (widget.snapshot.isDraftingSubstitutes ||
          widget.snapshot.isCompleted) {
        final teamId = targetTeamId ??
            _selectedTeamForReserveId ??
            widget.snapshot.teams.firstOrNull?.id;
        if (teamId == null || teamId.isEmpty) {
          AppFeedback.showWarning(
            context,
            message: 'Selecione uma equipe para adicionar o reserva.',
          );
          return;
        }
        final targetTeam = widget.snapshot.teams.firstWhere(
          (t) => t.id == teamId,
          orElse: () => widget.snapshot.teams.first,
        );
        if (targetTeam.reserves.length >= 2) {
          AppFeedback.showWarning(
            context,
            message:
                'A equipe ${targetTeam.name} já atingiu o limite de 2 reservas.',
          );
          return;
        }
        error = await widget.controller.allocateReserve(
          teamId: teamId,
          playerId: player.id,
        );
      } else {
        if (SystemSecurityService.instance.isDraftPicksLocked) {
          final detail = SystemSecurityService.instance.message;
          AppFeedback.showWarning(
            context,
            title: 'ESCOLHAS DE DRAFT BLOQUEADAS',
            message: (detail != null && detail.trim().isNotEmpty)
                ? 'As escolhas de draft estão temporariamente bloqueadas pela administração. Motivo: $detail'
                : 'As escolhas de draft estão temporariamente bloqueadas pela administração do sistema.',
          );
          return;
        }
        error = await widget.controller.pickStarterPlayer(
          playerId: player.id,
        );
      }

      if (!mounted) return;

      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: isStarterSubstitution
              ? '${player.name} entrou como substituto com sucesso!'
              : (widget.snapshot.isDraftingSubstitutes || widget.snapshot.isCompleted)
                  ? '${player.name} foi adicionado como reserva!'
                  : '${player.name} foi draftado para ${_effectiveTurnTeam?.name ?? 'a equipe'}!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    } finally {
      if (mounted) _isMutating = false;
    }
  }

  Future<void> _handleStartSubstitution(
    DraftTeamDto team,
    DraftPlayerDto player,
  ) async {
    final bool isStarter = team.starters.any((p) => p.id == player.id);

    if (isStarter) {
      if (_isMutating) return;
      _isMutating = true;

      try {
        final error = await widget.controller.startSubstitution(
          teamId: team.id,
          outPlayerId: player.id,
        );
        if (!mounted) return;

        if (error == null) {
          AppFeedback.showInfo(
            context,
            message: 'Selecione o substituto de ${player.name} no Bucket [+].',
          );
        } else {
          AppFeedback.showError(context, message: error);
        }
      } finally {
        if (mounted) _isMutating = false;
      }
    } else {
      // Substituição de Reserva: gerencia localmente com bloqueio visual consistente
      setState(() {
        _substitutingReservePlayer = player;
        _substitutingReserveTeamId = team.id;
      });
      AppFeedback.showInfo(
        context,
        message: 'Selecione o substituto de ${player.name} no Bucket [+].',
      );
    }
  }

  Future<void> _handleCancelSubstitution() async {
    if (_substitutingReservePlayer != null) {
      setState(() {
        _substitutingReservePlayer = null;
        _substitutingReserveTeamId = null;
      });
      AppFeedback.showInfo(context, message: 'Substituição cancelada.');
      return;
    }

    if (_isMutating) return;
    _isMutating = true;

    try {
      final error = await widget.controller.cancelSubstitution();
      if (!mounted) return;

      if (error == null) {
        AppFeedback.showInfo(context, message: 'Substituição cancelada.');
      } else {
        AppFeedback.showError(context, message: error);
      }
    } finally {
      if (mounted) _isMutating = false;
    }
  }

  Future<void> _handleRemoveReserve(
    DraftTeamDto team,
    DraftPlayerDto player,
  ) async {
    if (_isMutating) return;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'REMOVER RESERVA',
      message:
          'Deseja realmente remover o jogador ${player.name} da reserva da equipe ${team.name}?',
      confirmLabel: 'REMOVER',
      cancelLabel: 'CANCELAR',
      isDestructive: true,
      icon: Icons.person_remove_rounded,
    );

    if (confirmed != true || !mounted) return;

    _isMutating = true;
    try {
      final error = await widget.controller.removeReserve(
        teamId: team.id,
        playerId: player.id,
      );
      if (!mounted) return;

      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Reserva ${player.name} removido com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    } finally {
      if (mounted) _isMutating = false;
    }
  }

  Set<String> _collectExistingIdentifiers() {
    final identifiers = <String>{};
    for (final p in widget.snapshot.playerPool) {
      if (p.id.isNotEmpty) identifiers.add(p.id.toLowerCase());
      if (p.externalUserId != null && p.externalUserId!.isNotEmpty) {
        identifiers.add(p.externalUserId!.toLowerCase());
      }
      if (p.name.isNotEmpty) identifiers.add(p.name.trim().toLowerCase());
    }
    for (final team in widget.snapshot.teams) {
      final allTeamPlayers = [
        ...team.starters,
        ...team.reserves,
      ];
      for (final p in allTeamPlayers) {
        if (p.id.isNotEmpty) identifiers.add(p.id.toLowerCase());
        if (p.externalUserId != null && p.externalUserId!.isNotEmpty) {
          identifiers.add(p.externalUserId!.toLowerCase());
        }
        if (p.name.isNotEmpty) identifiers.add(p.name.trim().toLowerCase());
      }
    }
    return identifiers;
  }

  Future<void> _handleOpenAddLatePlayer() async {
    final added = await AddLatePlayerDialog.show(
      context,
      existingIdentifiers: _collectExistingIdentifiers(),
      onAdd: ({
        required String name,
        required String playerId,
        required List<String> roles,
        required String preferredRole,
        int? rankTier,
        String? avatarUrl,
      }) {
        return widget.controller.addLatePlayer(
          name: name,
          playerId: playerId,
          roles: roles,
          preferredRole: preferredRole,
          rankTier: rankTier,
          avatarUrl: avatarUrl,
        );
      },
    );

    if (added == true && mounted) {
      AppFeedback.showSuccess(
        context,
        message: 'Jogador adicionado à pool com sucesso!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 960;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Coluna Principal de Equipes (com rolagem vertical independente apenas aqui)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 20),
              child: _buildTeamsSection(),
            ),
          ),

          // 2. Coluna Lateral do Bucket de Jogadores ou Aba no Canto da Tela
          if (_isBucketVisible) ...[
            const SizedBox(width: 14),
            SizedBox(
              width: _bucketWidth,
              child: _buildPlayerBucket(),
            ),
          ] else ...[
            const SizedBox(width: 8),
            DraftCornerBucketOpener(
              poolCount: widget.snapshot.playerPool.length,
              onTap: () => setState(() => _isBucketVisible = true),
            ),
          ],
        ],
      );
    }

    // Layout Mobile / Telas Compactas: Botão evidente para abrir o bucket em bottom-sheet
    final isSubstituting = _isAnySubstituting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: _buildTeamsSection(),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: isSubstituting
              ? 'SELECIONAR SUBSTITUTO NO BUCKET'
              : 'ABRIR BUCKET DE JOGADORES (${widget.snapshot.playerPool.length})',
          icon: isSubstituting
              ? Icons.swap_horiz_rounded
              : Icons.storage_rounded,
          size: AppButtonSize.large,
          variant: isSubstituting
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: _openMobileBucket,
        ),
      ],
    );
  }

  Widget _buildPlayerBucket() {
    final isSubstituting = _isAnySubstituting;
    final isReservesPhase =
        widget.snapshot.isDraftingSubstitutes || widget.snapshot.isCompleted;

    return RepaintBoundary(
      child: DraftPlayerBucket(
        snapshot: widget.snapshot,
        selectedTeamId: _activeSubstitutingTeamId ??
            (isReservesPhase ? _selectedTeamForReserveId : widget.snapshot.currentTurnTeamId) ??
            _lastTurnTeamId,
        canManage: widget.canManage,
        isExpanded: _isBucketExpanded,
        onToggleExpand: () =>
            setState(() => _isBucketExpanded = !_isBucketExpanded),
        onHide: () => setState(() => _isBucketVisible = false),
        isReplacing: isSubstituting,
        onAddPlayer: _handlePlayerAction,
        onRemovePlayer: (entry) async {
          // Na Fase de Titulares e Reservas, substituição é o fluxo canônico
        },
        onAddLatePlayer: _handleOpenAddLatePlayer,
      ),
    );
  }

  void _openMobileBucket() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, __) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildPlayerBucket(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamsSection() {
    final isSubstituting = _isAnySubstituting;
    final isReservesPhase =
        widget.snapshot.isDraftingSubstitutes || widget.snapshot.isCompleted;
    final turnTeam = _effectiveTurnTeam;
    final reserveTeam = _selectedReserveTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Barra de Status Contextual (Fase de Reservas ou Turno do Snake)
        if (isReservesPhase && reserveTeam != null) ...[
          DraftReservesHudBanner(
            reserveTeam: reserveTeam,
            isSubstituting: isSubstituting,
            isDraftCompleted: widget.snapshot.isCompleted,
          ),
          const SizedBox(height: 12),
        ] else if (turnTeam != null) ...[
          DraftSnakeTurnHudBanner(
            turnTeam: turnTeam,
            isPausedForSubstitution: isSubstituting,
          ),
          const SizedBox(height: 12),
        ],

        // 2. Grid Responsivo de Equipes com Placeholders
        LayoutBuilder(
          builder: (context, constraints) {
            int columns = 1;
            if (constraints.maxWidth >= 1050) {
              columns = 3;
            } else if (constraints.maxWidth >= 640) {
              columns = 2;
            }

            if (columns == 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.snapshot.teams.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _buildTeamCard(widget.snapshot.teams[i]),
                  ],
                ],
              );
            }

            final rows = <Widget>[];
            for (int i = 0; i < widget.snapshot.teams.length; i += columns) {
              final rowItems = <Widget>[];
              for (int j = 0; j < columns; j++) {
                final index = i + j;
                if (index < widget.snapshot.teams.length) {
                  rowItems.add(
                    Expanded(
                      child: _buildTeamCard(widget.snapshot.teams[index]),
                    ),
                  );
                } else {
                  rowItems.add(const Expanded(child: SizedBox.shrink()));
                }
                if (j < columns - 1) {
                  rowItems.add(const SizedBox(width: 12));
                }
              }

              if (rows.isNotEmpty) {
                rows.add(const SizedBox(height: 12));
              }
              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rowItems,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: rows,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTeamCard(DraftTeamDto team) {
    final effectiveTurnId =
        widget.snapshot.currentTurnTeamId ?? _lastTurnTeamId;
    final bool isReservesPhase =
        widget.snapshot.isDraftingSubstitutes || widget.snapshot.isCompleted;
    final String? activeSubstitutingPlayerId = _activeSubstitutingPlayerId;
    final String? activeSubstitutingTeamId = _activeSubstitutingTeamId;
    final bool isSubstituting = activeSubstitutingTeamId == team.id;
    final bool isSelectedForReserve =
        isReservesPhase && (_selectedTeamForReserveId == team.id);
    final bool isCurrentTurn = !isReservesPhase && (effectiveTurnId == team.id);

    return RepaintBoundary(
      child: DraftTeamStartersCard(
        team: team,
        isCurrentTurn: isCurrentTurn,
        currentTurnPickNumber: widget.snapshot.displayCurrentPick,
        isSubstituting: isSubstituting,
        substitutingPlayerId: activeSubstitutingPlayerId,
        isDraftingSubstitutes: isReservesPhase,
        isSelectedForReserve: isSelectedForReserve,
        onSelectForReserve: (isReservesPhase && activeSubstitutingPlayerId == null)
            ? () => setState(() => _selectedTeamForReserveId = team.id)
            : null,
        canManage: widget.canManage,
        onStartSubstitution: (player) =>
            _handleStartSubstitution(team, player),
        onCancelSubstitution: _handleCancelSubstitution,
        onRemoveReserve: (player) => _handleRemoveReserve(team, player),
        onRenameTeam: (widget.canManage && !widget.isLockedByPlayoffs)
            ? (teamId, newName) => widget.controller
                .renameTeam(teamId: teamId, newName: newName)
            : null,
        isLockedByPlayoffs: widget.isLockedByPlayoffs,
      ),
    );
  }
}
