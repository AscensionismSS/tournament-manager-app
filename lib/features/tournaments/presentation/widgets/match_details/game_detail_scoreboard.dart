import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../models/match_game_dto.dart';
import '../../../models/match_series_dto.dart';

/// Barra de navegação integrada ao centro do cabeçalho do `AppDialog` para alternar entre mapas da série.
class GameHeaderNavigationBar extends StatelessWidget {
  final MatchSeriesDto series;
  final int currentGameNumber;
  final int totalGames;
  final ValueChanged<int> onSelectGame;
  final VoidCallback? onPreviousGame;
  final VoidCallback? onNextGame;

  const GameHeaderNavigationBar({
    super.key,
    required this.series,
    required this.currentGameNumber,
    required this.totalGames,
    required this.onSelectGame,
    this.onPreviousGame,
    this.onNextGame,
  });

  @override
  Widget build(BuildContext context) {
    if (totalGames <= 1) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.85),
              width: 0.85,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_esports_rounded,
                size: 13.5,
                color: AppColors.dotaGoldLight,
              ),
              SizedBox(width: 7),
              Text(
                'JOGO 1 (MD1) • PARTIDA ÚNICA',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: AppColors.dotaGoldLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton.compact(
            icon: Icons.chevron_left_rounded,
            tooltip: onPreviousGame != null ? 'Jogo Anterior' : null,
            variant: AppIconButtonVariant.warning,
            onPressed: onPreviousGame,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.85),
                width: 0.85,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 1; i <= totalGames; i++) ...[
                  if (i > 1) const SizedBox(width: 4),
                  _GamePill(
                    gameNum: i,
                    isSelected: i == currentGameNumber,
                    hasData: series.games.any((g) => g.gameNumber == i),
                    isLocked: !series.isGameNeeded(i),
                    onTap: series.isGameNeeded(i)
                        ? () => onSelectGame(i)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppIconButton.compact(
            icon: Icons.chevron_right_rounded,
            tooltip: onNextGame != null ? 'Próximo Jogo' : null,
            variant: AppIconButtonVariant.warning,
            onPressed: onNextGame,
          ),
        ],
      ),
    );
  }
}

/// Banner principal de placar do mapa disputado (Times, Avatares, Relógio, Kills e Selo de Vitória).
class GameScoreboardBanner extends StatelessWidget {
  final MatchSeriesDto series;
  final MatchGameDto game;
  final String nameTeamA;
  final String nameTeamB;

  const GameScoreboardBanner({
    super.key,
    required this.series,
    required this.game,
    required this.nameTeamA,
    required this.nameTeamB,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;
    final isTeamAWinner =
        series.teamAId != null && game.winnerTeamId == series.teamAId;
    final isTeamBWinner =
        series.teamBId != null && game.winnerTeamId == series.teamBId;

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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        gradient: highlightGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isTeamAWinner || isTeamBWinner)
              ? AppColors.dotaGold.withValues(alpha: 0.45)
              : AppColors.border.withValues(alpha: 0.8),
          width: 0.95,
        ),
      ),
      child: Row(
        children: [
          // Time A (Selo Vitória na esquerda, Nome + Logo alinhados ao centro)
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isTeamAWinner && !isMobile) ...[
                  const _VictoryPillBadge(),
                  const Spacer(),
                ] else if (isTeamAWinner && isMobile) ...[
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 13.5,
                    color: AppColors.dotaGold,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    nameTeamA,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: isMobile ? 12.5 : 14.5,
                      fontWeight:
                          isTeamAWinner ? FontWeight.w900 : FontWeight.w700,
                      color: isTeamAWinner
                          ? AppColors.dotaGoldLight
                          : (isTeamBWinner
                              ? AppColors.textSecondary.withValues(alpha: 0.65)
                              : AppColors.textPrimary),
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 9),
                AppAvatar(
                  name: nameTeamA,
                  radius: isMobile ? 16 : 19,
                  backgroundColor: AppColors.canvasSurface,
                  borderColor: isTeamAWinner
                      ? AppColors.dotaGold
                      : AppColors.border.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),

          // Bloco Central de Placar e Duração (100% no eixo central exato!)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 7 : 9,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvasSurface,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: AppColors.dotaGold.withValues(alpha: 0.45),
                      width: 0.75,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 12.5,
                        color: AppColors.dotaGoldLight,
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        game.formattedDuration,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dotaGoldLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${game.teamAKills}',
                      style: TextStyle(
                        fontSize: isMobile ? 14.5 : 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: isTeamAWinner
                            ? AppColors.dotaGoldLight
                            : (isTeamBWinner
                                ? AppColors.textSecondary
                                    .withValues(alpha: 0.55)
                                : AppColors.textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: isMobile ? 13.5 : 15,
                          fontWeight: FontWeight.w800,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    Text(
                      '${game.teamBKills}',
                      style: TextStyle(
                        fontSize: isMobile ? 14.5 : 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: isTeamBWinner
                            ? AppColors.dotaGoldLight
                            : (isTeamAWinner
                                ? AppColors.textSecondary
                                    .withValues(alpha: 0.55)
                                : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time B (Logo à esquerda + Nome alinhados ao centro, Selo Vitória na extrema direita)
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AppAvatar(
                  name: nameTeamB,
                  radius: isMobile ? 16 : 19,
                  backgroundColor: AppColors.canvasSurface,
                  borderColor: isTeamBWinner
                      ? AppColors.dotaGold
                      : AppColors.border.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    nameTeamB,
                    style: TextStyle(
                      fontSize: isMobile ? 12.5 : 14.5,
                      fontWeight:
                          isTeamBWinner ? FontWeight.w900 : FontWeight.w700,
                      color: isTeamBWinner
                          ? AppColors.dotaGoldLight
                          : (isTeamAWinner
                              ? AppColors.textSecondary.withValues(alpha: 0.65)
                              : AppColors.textPrimary),
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isTeamBWinner && !isMobile) ...[
                  const Spacer(),
                  const _VictoryPillBadge(),
                ] else if (isTeamBWinner && isMobile) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 13.5,
                    color: AppColors.dotaGold,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado declarativo para mapa ainda não disputado ou não necessário na série (mantém a mesma altura física do modal).
class GamePendingStateCard extends StatelessWidget {
  final bool isSeriesCompleted;

  const GamePendingStateCard({
    super.key,
    this.isSeriesCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon = isSeriesCompleted
        ? Icons.check_circle_outline_rounded
        : Icons.hourglass_empty_rounded;
    final String title = isSeriesCompleted
        ? 'Partida não necessária (série decidida)'
        : 'Mapa ainda não disputado';
    final String subtitle = isSeriesCompleted
        ? 'A série já foi definida nos mapas anteriores.'
        : 'Os dados, heróis e estatísticas estarão disponíveis assim que a partida for concluída.';

    return SizedBox(
      height: 506,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.canvasSurface.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.45),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.borderHighlight.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VictoryPillBadge extends StatelessWidget {
  const _VictoryPillBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.dotaGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.dotaGold,
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 12,
            color: AppColors.dotaGold,
          ),
          SizedBox(width: 3),
          Text(
            'VITÓRIA',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: AppColors.dotaGoldLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _GamePill extends StatelessWidget {
  final int gameNum;
  final bool isSelected;
  final bool hasData;
  final bool isLocked;
  final VoidCallback? onTap;

  const _GamePill({
    required this.gameNum,
    required this.isSelected,
    required this.hasData,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Opacity(
      opacity: isLocked ? 0.32 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.dotaGold.withValues(alpha: 0.18)
              : (hasData ? AppColors.surface : AppColors.canvasSurface),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected
                ? AppColors.dotaGold
                : (hasData
                    ? AppColors.border.withValues(alpha: 0.8)
                    : AppColors.border.withValues(alpha: 0.35)),
            width: isSelected ? 1.0 : 0.7,
          ),
        ),
        child: Text(
          'G$gameNum',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected
                ? AppColors.dotaGoldLight
                : (hasData
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.55)),
          ),
        ),
      ),
    );

    if (isLocked || onTap == null) {
      return IgnorePointer(child: pill);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: pill,
    );
  }
}

