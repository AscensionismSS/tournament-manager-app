import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../models/match_game_dto.dart';
import '../../../models/player_game_stats_dto.dart';
import 'series_game_row_parts.dart';

/// Orquestrador enxuto de um mapa (G1, G2, G3) no card da série (SRP & Dumb UI).
/// Delega as colunas de Picks/Bans, placar central, indicadores de vitória e W.O. para `series_game_row_parts.dart`.
class SeriesGameRow extends StatefulWidget {
  final int gameIndex;
  final MatchGameDto? game;
  final String? teamAId;
  final String? teamBId;
  final double pickSize;
  final double banSize;
  final bool isAdmin;
  final void Function(int gameIndex)? onEditResult;
  final void Function(int gameIndex)? onTap;

  const SeriesGameRow({
    super.key,
    required this.gameIndex,
    this.game,
    this.teamAId,
    this.teamBId,
    this.pickSize = 25.5,
    this.banSize = 21.5,
    this.isAdmin = false,
    this.onEditResult,
    this.onTap,
  });

  @override
  State<SeriesGameRow> createState() => _SeriesGameRowState();
}

class _SeriesGameRowState extends State<SeriesGameRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final bool hasPlayed = game != null;
    final bool isWalkover = game?.isWalkover ?? false;
    final bool isTeamAWinner = hasPlayed &&
        widget.teamAId != null &&
        game.winnerTeamId == widget.teamAId;
    final bool isTeamBWinner = hasPlayed &&
        widget.teamBId != null &&
        game.winnerTeamId == widget.teamBId;

    final bool isTeamAFp = game?.isTeamAFirstPick(widget.teamAId) ?? false;
    final bool isTeamBFp = game?.isTeamBFirstPick(widget.teamBId) ?? false;

    final List<PlayerGameStatsDto> teamAPlayers =
        hasPlayed && widget.teamAId != null
            ? game.playerStats
                .where((PlayerGameStatsDto p) => p.teamId == widget.teamAId)
                .take(5)
                .toList()
            : const <PlayerGameStatsDto>[];
    final List<PlayerGameStatsDto> teamBPlayers =
        hasPlayed && widget.teamBId != null
            ? game.playerStats
                .where((PlayerGameStatsDto p) => p.teamId == widget.teamBId)
                .take(5)
                .toList()
            : const <PlayerGameStatsDto>[];

    final List<int> teamABans = game?.teamABanHeroIds ?? const <int>[];
    final List<int> teamBBans = game?.teamBBanHeroIds ?? const <int>[];

    final bool canAdminSplit = widget.isAdmin && widget.onEditResult != null;

    final rowContent = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6.0),
      decoration: _buildRowDecoration(
        isHovered: _isHovered && !canAdminSplit,
        isTeamAWinner: isTeamAWinner,
        isTeamBWinner: isTeamBWinner,
      ),
      child: isWalkover
          ? SizedBox(
              height: 50.5,
              child: SeriesWalkoverGameContent(
                gameIndex: widget.gameIndex,
                isTeamAWinner: isTeamAWinner,
                isTeamBWinner: isTeamBWinner,
                onTap: widget.onTap != null
                    ? () => widget.onTap!(widget.gameIndex)
                    : null,
              ),
            )
          : _buildStandardGameRow(
              teamAPlayers: teamAPlayers,
              teamBPlayers: teamBPlayers,
              teamABans: teamABans,
              teamBBans: teamBBans,
              isTeamAWinner: isTeamAWinner,
              isTeamBWinner: isTeamBWinner,
              hasPlayed: hasPlayed,
              isTeamAFp: isTeamAFp,
              isTeamBFp: isTeamBFp,
              game: game,
            ),
    );

    Widget content;
    if (canAdminSplit) {
      content = Stack(
        children: [
          rowContent,
          if (_isHovered)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: AppDualActionOverlay(
                  borderRadius: BorderRadius.circular(8),
                  leftLabel: 'VER PARTIDA',
                  leftIcon: Icons.visibility_rounded,
                  leftColor: AppColors.dotaGoldLight,
                  onLeftTap: widget.onTap != null
                      ? () => widget.onTap!(widget.gameIndex)
                      : null,
                  rightLabel: 'EDITAR RESULTADO',
                  rightIcon: Icons.edit_note_rounded,
                  rightColor: AppColors.primaryNeon,
                  onRightTap: widget.onEditResult != null
                      ? () => widget.onEditResult!(widget.gameIndex)
                      : null,
                ),
              ),
            ),
        ],
      );
    } else {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap != null
            ? () => widget.onTap!(widget.gameIndex)
            : null,
        child: rowContent,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: content,
    );
  }

  BoxDecoration _buildRowDecoration({
    required bool isHovered,
    required bool isTeamAWinner,
    required bool isTeamBWinner,
  }) {
    Gradient? highlightGradient;
    if (isTeamAWinner) {
      highlightGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.center,
        colors: [
          AppColors.dotaGold.withValues(alpha: 0.28),
          AppColors.dotaGold.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      );
    } else if (isTeamBWinner) {
      highlightGradient = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.center,
        colors: [
          AppColors.dotaGold.withValues(alpha: 0.28),
          AppColors.dotaGold.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      );
    }

    return BoxDecoration(
      color: AppColors.canvasSurface.withValues(alpha: 0.85),
      gradient: highlightGradient,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isHovered
            ? AppColors.dotaGoldLight
            : AppColors.borderHighlight.withValues(alpha: 0.65),
        width: 1.5,
      ),
    );
  }

  Widget _buildStandardGameRow({
    required List<PlayerGameStatsDto> teamAPlayers,
    required List<PlayerGameStatsDto> teamBPlayers,
    required List<int> teamABans,
    required List<int> teamBBans,
    required bool isTeamAWinner,
    required bool isTeamBWinner,
    required bool hasPlayed,
    required bool isTeamAFp,
    required bool isTeamBFp,
    required MatchGameDto? game,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            'G${widget.gameIndex}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isTeamAWinner
                  ? AppColors.dotaGoldLight
                  : AppColors.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: SeriesTeamPicksBansColumn(
            players: teamAPlayers,
            banHeroIds: teamABans,
            isWinner: isTeamAWinner,
            hasPlayed: hasPlayed,
            isFp: isTeamAFp,
            isTeamA: true,
            pickSize: widget.pickSize,
            banSize: widget.banSize,
          ),
        ),
        const SizedBox(width: 5),
        SeriesGameWinnerIndicator(isWinner: isTeamAWinner, isLeft: true),
        const SizedBox(width: 5),
        SeriesGameCenterScore(
          game: game,
          hasPlayed: hasPlayed,
          isWalkover: false,
          isTeamAWinner: isTeamAWinner,
          isTeamBWinner: isTeamBWinner,
        ),
        const SizedBox(width: 5),
        SeriesGameWinnerIndicator(isWinner: isTeamBWinner, isLeft: false),
        const SizedBox(width: 5),
        Expanded(
          child: SeriesTeamPicksBansColumn(
            players: teamBPlayers,
            banHeroIds: teamBBans,
            isWinner: isTeamBWinner,
            hasPlayed: hasPlayed,
            isFp: isTeamBFp,
            isTeamA: false,
            pickSize: widget.pickSize,
            banSize: widget.banSize,
          ),
        ),
        const SizedBox(width: 3),
        SizedBox(
          width: 20,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap != null
                  ? () => widget.onTap!(widget.gameIndex)
                  : null,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isTeamBWinner
                      ? AppColors.dotaGoldLight
                      : AppColors.textSecondary.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
