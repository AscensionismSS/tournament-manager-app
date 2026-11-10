import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../draft/models/draft_team_dto.dart';
import '../../../models/match_game_dto.dart';
import '../../../models/match_series_dto.dart';
import '../../../models/tournament_team_dto.dart';
import 'game_detail_scoreboard.dart';
import 'game_player_stats_view.dart';

/// Modal orquestrador enxuto para exibição e navegação direta entre mapas de uma série (SRP & Dumb UI).
/// Delega a barra de navegação de topo, o placar do mapa e as tabelas de estatísticas para sub-widgets modulares.
class GameDetailDialog extends StatefulWidget {
  final MatchSeriesDto series;
  final int initialGameNumber;
  final List<DraftTeamDto>? draftTeams;
  final List<TournamentTeamDto>? tournamentTeams;

  const GameDetailDialog({
    super.key,
    required this.series,
    this.initialGameNumber = 1,
    this.draftTeams,
    this.tournamentTeams,
  });

  /// Abre o modal diretamente para um mapa específico
  static Future<void> show(
    BuildContext context, {
    required MatchSeriesDto series,
    int initialGameNumber = 1,
    List<DraftTeamDto>? draftTeams,
    List<TournamentTeamDto>? tournamentTeams,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => GameDetailDialog(
        series: series,
        initialGameNumber: initialGameNumber,
        draftTeams: draftTeams,
        tournamentTeams: tournamentTeams,
      ),
    );
  }

  @override
  State<GameDetailDialog> createState() => _GameDetailDialogState();
}

class _GameDetailDialogState extends State<GameDetailDialog> {
  late int _currentGameNumber;

  @override
  void initState() {
    super.initState();
    _currentGameNumber =
        widget.initialGameNumber.clamp(1, widget.series.maxUnlockedGameNumber);
  }

  void _onPreviousGame() {
    if (_currentGameNumber > 1) {
      setState(() => _currentGameNumber--);
    }
  }

  void _onNextGame() {
    if (_currentGameNumber < widget.series.maxUnlockedGameNumber) {
      setState(() => _currentGameNumber++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final totalGames = series.navigableGamesCount;
    final maxUnlocked = series.maxUnlockedGameNumber;
    final game = series.gameByNumber(_currentGameNumber);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    return AppDialog(
      maxWidth: isMobile ? (screenWidth * 0.95).clamp(340.0, 600.0) : 1060,
      contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      icon: Icons.sports_esports_rounded,
      iconColor: AppColors.dotaGold,
      title: series.seriesDialogTitle,
      centerHeader: GameHeaderNavigationBar(
        series: series,
        currentGameNumber: _currentGameNumber,
        totalGames: totalGames,
        onSelectGame: (gameNum) {
          if (gameNum <= maxUnlocked) {
            setState(() => _currentGameNumber = gameNum);
          }
        },
        onPreviousGame: _currentGameNumber > 1 ? _onPreviousGame : null,
        onNextGame: _currentGameNumber < maxUnlocked ? _onNextGame : null,
      ),
      trailingHeader: _SeriesStatusHeaderBadge(isCompleted: series.isCompleted),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (game != null)
            _buildPlayedGameContent(game, series)
          else
            GamePendingStateCard(isSeriesCompleted: series.isSeriesDecided),
        ],
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.borderHighlight,
              width: 1.1,
            ),
          ),
          child: AppButton(
            text: 'FECHAR DETALHES',
            icon: Icons.close_rounded,
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.medium,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayedGameContent(MatchGameDto game, MatchSeriesDto series) {
    final nameTeamA = series.resolveTeamDisplayName(
      series.teamAId,
      series.displayTeamA,
      draftTeams: widget.draftTeams,
      tournamentTeams: widget.tournamentTeams,
    );
    final nameTeamB = series.resolveTeamDisplayName(
      series.teamBId,
      series.displayTeamB,
      draftTeams: widget.draftTeams,
      tournamentTeams: widget.tournamentTeams,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameScoreboardBanner(
          series: series,
          game: game,
          nameTeamA: nameTeamA,
          nameTeamB: nameTeamB,
        ),
        const SizedBox(height: 8),
        GamePlayerStatsView(
          game: game,
          series: series,
          draftTeams: widget.draftTeams,
          onClose: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _SeriesStatusHeaderBadge extends StatelessWidget {
  final bool isCompleted;

  const _SeriesStatusHeaderBadge({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCompleted
              ? AppColors.dotaGold.withValues(alpha: 0.5)
              : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_outline_rounded
                : Icons.schedule_rounded,
            size: 12,
            color:
                isCompleted ? AppColors.dotaGoldLight : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isCompleted ? 'FINALIZADO' : 'PENDENTE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: isCompleted
                  ? AppColors.dotaGoldLight
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
