import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/draft_controller.dart';
import '../../models/chosen_player_entry.dart';
import '../../models/draft_player_dto.dart';
import '../../models/draft_state_snapshot_dto.dart';
import '../../models/draft_team_dto.dart';
import 'add_late_player_dialog.dart';
import 'draft_player_bucket.dart';
import 'draft_team_captain_card.dart';

/// Visão da Fase 1 do Draft: Seleção e Definição de Capitães (SRP & Dumb UI).
/// Totalmente dinâmica para qualquer quantidade de equipes (4, 5, 6, 7, 8 times).
/// Composta pelo Grid de Equipes (via [DraftTeamCaptainCard]) e o [DraftPlayerBucket].
class DraftCaptainsPhaseView extends StatefulWidget {
  final DraftController controller;
  final DraftStateSnapshotDto snapshot;
  final bool canManage;

  const DraftCaptainsPhaseView({
    super.key,
    required this.controller,
    required this.snapshot,
    required this.canManage,
  });

  @override
  State<DraftCaptainsPhaseView> createState() => _DraftCaptainsPhaseViewState();
}

class _DraftCaptainsPhaseViewState extends State<DraftCaptainsPhaseView> {
  String? _selectedTeamId;
  String? _replacingTeamId;
  bool _isBucketVisible = true;
  bool _isBucketExpanded = false;
  bool _isMutating = false;

  double get _bucketWidth => _isBucketExpanded ? 540.0 : 360.0;

  DraftTeamDto? get _effectiveSelectedTeam {
    if (_replacingTeamId != null) {
      for (final t in widget.snapshot.teams) {
        if (t.id == _replacingTeamId) return t;
      }
    }
    if (_selectedTeamId != null) {
      for (final t in widget.snapshot.teams) {
        if (t.id == _selectedTeamId) return t;
      }
    }
    for (final t in widget.snapshot.teams) {
      if (t.captainId == null) return t;
    }
    return widget.snapshot.teams.isNotEmpty ? widget.snapshot.teams.first : null;
  }

  Future<void> _handleAddPlayer(DraftPlayerDto player, String? targetTeamId) async {
    if (_isMutating) return;
    _isMutating = true;

    final bool isSubstitution = _replacingTeamId != null;
    final effectiveTeam = _effectiveSelectedTeam;
    final teamId = targetTeamId ?? effectiveTeam?.id;

    if (teamId == null) {
      _isMutating = false;
      AppFeedback.showInfo(context, message: 'Todas as equipes já possuem capitão!');
      return;
    }

    try {
      final String? error;
      if (isSubstitution) {
        error = await widget.controller.replaceCaptain(
          teamId: teamId,
          newPlayerId: player.id,
        );
      } else {
        error = await widget.controller.selectCaptain(
          playerId: player.id,
          teamId: teamId,
        );
      }

      if (!mounted) return;

      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: isSubstitution
              ? '${player.name} substituiu o capitão da ${effectiveTeam?.name}!'
              : '${player.name} foi atribuído como Capitão!',
        );
        setState(() {
          _selectedTeamId = null;
          _replacingTeamId = null;
        });
      } else {
        AppFeedback.showError(context, message: error);
      }
    } finally {
      if (mounted) _isMutating = false;
    }
  }

  Future<void> _handleRemovePlayer(ChosenPlayerEntry entry) async {
    if (_isMutating) return;
    _isMutating = true;

    try {
      final error = await widget.controller.removeCaptain(teamId: entry.team.id);
      if (!mounted) return;

      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Capitão da ${entry.team.name} removido com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    } finally {
      if (mounted) _isMutating = false;
    }
  }

  Future<void> _handleRemoveCaptainFromTeam(DraftTeamDto team) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'REMOVER CAPITÃO?',
      message:
          'Deseja remover o capitão da equipe "${team.name}"? O jogador retornará imediatamente para a pool.',
      confirmLabel: 'REMOVER',
      cancelLabel: 'CANCELAR',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final error = await widget.controller.removeCaptain(teamId: team.id);
      if (!mounted) return;

      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Capitão removido da equipe "${team.name}" com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
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
          // 1. Coluna Principal de Equipes (rolagem vertical independente apenas aqui)
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
              child: RepaintBoundary(
                child: DraftPlayerBucket(
                  snapshot: widget.snapshot,
                  selectedTeamId: _effectiveSelectedTeam?.id,
                  canManage: widget.canManage,
                  isExpanded: _isBucketExpanded,
                  onToggleExpand: () =>
                      setState(() => _isBucketExpanded = !_isBucketExpanded),
                  onHide: () => setState(() => _isBucketVisible = false),
                  isReplacing: _replacingTeamId != null,
                  onAddPlayer: _handleAddPlayer,
                  onRemovePlayer: _handleRemovePlayer,
                  onAddLatePlayer: _handleOpenAddLatePlayer,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 8),
            _buildCornerBucketOpener(),
          ],
        ],
      );
    }

    // Layout Mobile / Telas Compactas: Botão evidente para abrir o bucket em bottom-sheet
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
          text: _replacingTeamId != null
              ? 'SELECIONAR SUBSTITUTO NO BUCKET'
              : 'ABRIR BUCKET DE JOGADORES (${widget.snapshot.playerPool.length})',
          icon: _replacingTeamId != null
              ? Icons.swap_horiz_rounded
              : Icons.storage_rounded,
          size: AppButtonSize.large,
          variant: _replacingTeamId != null
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: _openMobileBucket,
        ),
      ],
    );
  }

  /// Aba vertical elegante ancorada no canto da tela com a seta dourada
  Widget _buildCornerBucketOpener() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isBucketVisible = true),
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.dotaGold.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.dotaGold.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dotaGold.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: AppColors.dotaGold,
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.storage_rounded,
                  size: 16,
                  color: AppColors.dotaGold,
                ),
                const SizedBox(height: 8),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'BUCKET (${widget.snapshot.playerPool.length})',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.dotaGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMobileBucket() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.sizeOf(context).height * 0.88,
          decoration: const BoxDecoration(
            color: AppColors.canvasSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.dotaGold, width: 1.5),
              left: BorderSide(color: AppColors.border, width: 0.8),
              right: BorderSide(color: AppColors.border, width: 0.8),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: DraftPlayerBucket(
                  snapshot: widget.snapshot,
                  selectedTeamId: _effectiveSelectedTeam?.id,
                  canManage: widget.canManage,
                  isReplacing: _replacingTeamId != null,
                  onAddPlayer: (player, teamId) async {
                    Navigator.of(modalContext).pop();
                    await _handleAddPlayer(player, teamId);
                  },
                  onRemovePlayer: _handleRemovePlayer,
                  onAddLatePlayer: _handleOpenAddLatePlayer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamsSection() {
    final int totalTeams = widget.snapshot.totalCaptainsRequired;
    final int assignedCount = widget.snapshot.assignedCaptainsCount;
    final bool allDone = widget.snapshot.allCaptainsAssigned;
    final effectiveTeam = _effectiveSelectedTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra Superior Compacta com Status e Ação de Avanço
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBadge(
                  label: '$assignedCount / $totalTeams CAPITÃES',
                  variant: allDone ? AppBadgeVariant.success : AppBadgeVariant.neutral,
                  customColor: allDone ? AppColors.dotaGold : null,
                ),
                if (_replacingTeamId != null && effectiveTeam != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Substituindo capitão da: ${effectiveTeam.name}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dotaGold,
                    ),
                  ),
                ] else if (!allDone && effectiveTeam != null && widget.canManage) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Atribuindo para: ${effectiveTeam.name}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dotaGoldLight,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Grid Dinâmico de Equipes (Trata 4, 5, 6, 7, 8 times fluidamente)
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            int crossAxisCount = 3;
            if (width < 640) {
              crossAxisCount = 1;
            } else if (width < 1000) {
              crossAxisCount = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.snapshot.teams.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 145,
              ),
              itemBuilder: (context, index) {
                final team = widget.snapshot.teams[index];
                final isSelected = team.id == effectiveTeam?.id;
                final isReplacing = team.id == _replacingTeamId;
                final isLockedByAnother =
                    _replacingTeamId != null && team.id != _replacingTeamId;

                return RepaintBoundary(
                  child: DraftTeamCaptainCard(
                    team: team,
                    isSelected: isSelected,
                    isReplacing: isReplacing,
                    isLockedByAnother: isLockedByAnother,
                    canManage: widget.canManage,
                    onSelectTeam: () => setState(() {
                      _selectedTeamId = team.id;
                      _replacingTeamId = null;
                    }),
                    onRemoveCaptain: () => _handleRemoveCaptainFromTeam(team),
                    onStartReplacing: () => setState(() {
                      _replacingTeamId = team.id;
                      _selectedTeamId = null;
                    }),
                    onCancelReplacing: () =>
                        setState(() => _replacingTeamId = null),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
