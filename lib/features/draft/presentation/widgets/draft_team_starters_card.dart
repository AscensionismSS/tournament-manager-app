import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/draft_player_dto.dart';
import '../../models/draft_team_dto.dart';
import 'draft_team_slot_rows.dart';

/// Card orquestrador individual de uma equipe na Fase 3 do Snake Draft (SRP & Dumb UI).
/// Delega cada linha de vaga (Capitão, Titular, Reserva e Placeholder) para `draft_team_slot_rows.dart`.
class DraftTeamStartersCard extends StatelessWidget {
  final DraftTeamDto team;
  final bool isCurrentTurn;
  final int? currentTurnPickNumber;
  final bool isSubstituting;
  final String? substitutingPlayerId;
  final bool isDraftingSubstitutes;
  final bool isSelectedForReserve;
  final VoidCallback? onSelectForReserve;
  final bool canManage;
  final ValueChanged<DraftPlayerDto>? onStartSubstitution;
  final VoidCallback? onCancelSubstitution;
  final ValueChanged<DraftPlayerDto>? onRemoveReserve;
  final Future<String?> Function(String teamId, String newName)? onRenameTeam;
  final bool isLockedByPlayoffs;

  const DraftTeamStartersCard({
    super.key,
    required this.team,
    required this.isCurrentTurn,
    this.currentTurnPickNumber,
    this.isSubstituting = false,
    this.substitutingPlayerId,
    this.isDraftingSubstitutes = false,
    this.isSelectedForReserve = false,
    this.onSelectForReserve,
    required this.canManage,
    this.onStartSubstitution,
    this.onCancelSubstitution,
    this.onRemoveReserve,
    this.onRenameTeam,
    this.isLockedByPlayoffs = false,
  });

  @override
  Widget build(BuildContext context) {
    final DraftPlayerDto? captain = team.captainPlayer;
    final List<DraftPlayerDto> otherStarters =
        team.starters.where((p) => p.id != team.captainId).toList();

    final bool isHighlighted =
        (isCurrentTurn || isSelectedForReserve) && substitutingPlayerId == null;

    final Color borderColor = isSubstituting
        ? AppColors.primaryNeon
        : (isSelectedForReserve && substitutingPlayerId == null)
            ? AppColors.dotaGoldLight
            : (isCurrentTurn && substitutingPlayerId == null)
                ? AppColors.dotaGold
                : AppColors.border;

    final double borderWidth = isHighlighted || isSubstituting ? 1.6 : 1.0;

    final List<BoxShadow>? shadows = isSubstituting
        ? [
            BoxShadow(
              color: AppColors.primaryNeon.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ]
        : (isHighlighted && substitutingPlayerId == null)
            ? [
                BoxShadow(
                  color: AppColors.dotaGold.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null;

    final bool isLockedByAnother =
        substitutingPlayerId != null && !isSubstituting;

    final Widget cardContent = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),

          // Slot 1: Capitão
          DraftCaptainSlotRow(
            captain: captain,
            substitutingPlayerId: substitutingPlayerId,
            canManage: canManage,
            onStartSubstitution: onStartSubstitution,
            onCancelSubstitution: onCancelSubstitution,
          ),

          const SizedBox(height: 6),

          // Slots 2 a 5: Titulares
          for (int i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            if (i < otherStarters.length)
              DraftFilledPlayerSlotRow(
                player: otherStarters[i],
                slotIndex: i + 2,
                substitutingPlayerId: substitutingPlayerId,
                canManage: canManage,
                onStartSubstitution: onStartSubstitution,
                onCancelSubstitution: onCancelSubstitution,
              )
            else
              DraftPlaceholderSlotRow(
                slotIndex: i + 2,
                isHighlightedNext: isCurrentTurn &&
                    i == otherStarters.length &&
                    substitutingPlayerId == null,
              ),
          ],

          // Slots 6 e 7: Reservas
          for (int r = 0; r < 2; r++) ...[
            const SizedBox(height: 6),
            if (r < team.reserves.length)
              DraftFilledPlayerSlotRow(
                player: team.reserves[r],
                slotIndex: 6 + r,
                isReserve: true,
                substitutingPlayerId: substitutingPlayerId,
                canManage: canManage,
                onStartSubstitution: onStartSubstitution,
                onCancelSubstitution: onCancelSubstitution,
                onRemoveReserve: onRemoveReserve,
              )
            else
              DraftPlaceholderSlotRow(
                slotIndex: 6 + r,
                reserveIndex: r + 1,
                isReserve: true,
                isHighlightedNext: isSelectedForReserve &&
                    r == team.reserves.length &&
                    substitutingPlayerId == null,
              ),
          ],
        ],
      ),
    );

    Widget interactiveCard = cardContent;
    if (isDraftingSubstitutes && onSelectForReserve != null) {
      interactiveCard = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelectForReserve,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.dotaGold.withValues(alpha: 0.05),
          child: cardContent,
        ),
      );
    }

    if (isLockedByAnother) {
      return Opacity(
        opacity: 0.50,
        child: interactiveCard,
      );
    }
    return interactiveCard;
  }

  Widget _buildHeader(BuildContext context) {
    final totalStarters = team.starters.length;
    final totalReserves = team.reserves.length;
    final isFull = totalStarters >= 5;

    final String countLabel = totalReserves > 0
        ? '$totalStarters/5 TIT. • $totalReserves/2 RES.'
        : '$totalStarters/5 TITULARES';

    final bool showEditTeamButton =
        canManage && !isLockedByPlayoffs && onRenameTeam != null;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: (isCurrentTurn && substitutingPlayerId == null)
                ? AppColors.dotaGold.withValues(alpha: 0.18)
                : AppColors.canvasSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (isCurrentTurn && substitutingPlayerId == null)
                  ? AppColors.dotaGold
                  : AppColors.border.withValues(alpha: 0.6),
              width: 0.8,
            ),
          ),
          child: Text(
            '${team.displayPickOrder}º PICK',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: (isCurrentTurn && substitutingPlayerId == null)
                  ? AppColors.dotaGold
                  : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            team.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
        if (showEditTeamButton) ...[
          const SizedBox(width: 4),
          AppIconButton(
            icon: Icons.edit_outlined,
            size: AppIconButtonSize.compact,
            tooltip: 'Team Management: Renomear Equipe (Admin)',
            variant: AppIconButtonVariant.ghost,
            onPressed: () => DraftTeamRenameDialog.show(
              context,
              teamId: team.id,
              initialName: team.name,
              onRenameTeam: onRenameTeam!,
            ),
          ),
        ],
        const SizedBox(width: 8),
        if (isSubstituting)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryNeon.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primaryNeon, width: 0.8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 13,
                  color: AppColors.primaryNeon,
                ),
                SizedBox(width: 5),
                Text(
                  'SUBSTITUIÇÃO',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppColors.primaryNeon,
                  ),
                ),
              ],
            ),
          )
        else if (isCurrentTurn && substitutingPlayerId == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.dotaGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.dotaGold, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  size: 13,
                  color: AppColors.dotaGold,
                ),
                const SizedBox(width: 5),
                Text(
                  currentTurnPickNumber != null
                      ? 'PICK #$currentTurnPickNumber'
                      : 'TURNO ATUAL',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppColors.dotaGold,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isFull
                  ? AppColors.dotaGold.withValues(alpha: 0.10)
                  : AppColors.canvasSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isFull
                    ? AppColors.dotaGold.withValues(alpha: 0.5)
                    : AppColors.border.withValues(alpha: 0.5),
                width: 0.7,
              ),
            ),
            child: Text(
              countLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isFull ? AppColors.dotaGold : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
