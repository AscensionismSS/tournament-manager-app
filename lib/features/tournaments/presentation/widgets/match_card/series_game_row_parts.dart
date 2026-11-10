import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../../models/match_game_dto.dart';
import '../../../models/player_game_stats_dto.dart';
import 'series_hero_slot.dart';

/// Coluna de Picks (5 heróis + moeda FP) e Bans (7 heróis) de uma equipe na linha do mapa.
class SeriesTeamPicksBansColumn extends StatelessWidget {
  final List<PlayerGameStatsDto> players;
  final List<int> banHeroIds;
  final bool isWinner;
  final bool hasPlayed;
  final bool isFp;
  final bool isTeamA;
  final double pickSize;
  final double banSize;

  const SeriesTeamPicksBansColumn({
    super.key,
    required this.players,
    required this.banHeroIds,
    required this.isWinner,
    required this.hasPlayed,
    required this.isFp,
    required this.isTeamA,
    required this.pickSize,
    required this.banSize,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isTeamA ? Alignment.centerLeft : Alignment.centerRight;
    final bool hasDraftDetails = players.isNotEmpty || banHeroIds.isNotEmpty;

    if (hasPlayed && !hasDraftDetails) {
      return SizedBox(
        height: pickSize + 3.5 + banSize,
        child: Align(
          alignment: alignment,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTeamA) ...[
                  _FirstPickCoinBadge(isFp: isFp),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvasSurface.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.45),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 13.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'SEM DETALHES DE DRAFT',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isTeamA) ...[
                  const SizedBox(width: 6),
                  _FirstPickCoinBadge(isFp: isFp),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: alignment,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTeamA) ...[
                  _FirstPickCoinBadge(isFp: isFp),
                  const SizedBox(width: 3),
                ],
                ...List.generate(5, (index) {
                  final bool hasPlayer = index < players.length;
                  final PlayerGameStatsDto? player =
                      hasPlayer ? players[index] : null;

                  return Padding(
                    padding: EdgeInsets.only(right: index < 4 ? 1.5 : 0),
                    child: hasPlayer && hasPlayed
                        ? SeriesHeroSlot(
                            heroId: player?.heroId,
                            heroName: player?.heroName,
                            isWinner: isWinner,
                            size: pickSize,
                          )
                        : SeriesHeroSlot.placeholder(size: pickSize),
                  );
                }),
                if (!isTeamA) ...[
                  const SizedBox(width: 3),
                  _FirstPickCoinBadge(isFp: isFp),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 3.5),
        Align(
          alignment: alignment,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (index) {
                final heroId =
                    index < banHeroIds.length ? banHeroIds[index] : null;
                return Padding(
                  padding: EdgeInsets.only(right: index < 6 ? 1.0 : 0),
                  child: heroId != null
                      ? SeriesHeroSlot(
                          heroId: heroId,
                          isBan: true,
                          size: banSize,
                        )
                      : SeriesHeroSlot.banPlaceholder(size: banSize),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bloco central da linha do mapa exibindo Duração (MM:SS) e Placar de Abates (Kills).
class SeriesGameCenterScore extends StatelessWidget {
  final MatchGameDto? game;
  final bool hasPlayed;
  final bool isWalkover;
  final bool isTeamAWinner;
  final bool isTeamBWinner;

  const SeriesGameCenterScore({
    super.key,
    required this.game,
    required this.hasPlayed,
    required this.isWalkover,
    required this.isTeamAWinner,
    required this.isTeamBWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            game?.formattedDuration ?? '--:--',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3.5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    !hasPlayed || isWalkover ? '-' : '${game!.teamAKills}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isTeamAWinner && !isWalkover
                          ? FontWeight.w900
                          : FontWeight.w700,
                      letterSpacing: 0.3,
                      color: isTeamAWinner && !isWalkover
                          ? AppColors.dotaGoldLight
                          : (hasPlayed
                              ? AppColors.textSecondary.withValues(alpha: 0.55)
                              : AppColors.textSecondary.withValues(alpha: 0.35)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 8,
                  child: Text(
                    '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: hasPlayed
                          ? AppColors.textSecondary.withValues(alpha: 0.6)
                          : AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                  child: Text(
                    !hasPlayed || isWalkover ? '-' : '${game!.teamBKills}',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isTeamBWinner && !isWalkover
                          ? FontWeight.w900
                          : FontWeight.w700,
                      letterSpacing: 0.3,
                      color: isTeamBWinner && !isWalkover
                          ? AppColors.dotaGoldLight
                          : (hasPlayed
                              ? AppColors.textSecondary.withValues(alpha: 0.55)
                              : AppColors.textSecondary.withValues(alpha: 0.35)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador fixo de 34px com coroa e selo 'W' ao lado do vencedor do mapa.
class SeriesGameWinnerIndicator extends StatelessWidget {
  final bool isWinner;
  final bool isLeft;

  static const double indicatorWidth = 34.0;

  const SeriesGameWinnerIndicator({
    super.key,
    required this.isWinner,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWinner) {
      return const SizedBox(width: indicatorWidth);
    }

    final wBadge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 3.0,
        vertical: 1.5,
      ),
      decoration: BoxDecoration(
        color: AppColors.dotaGold.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(
          color: AppColors.dotaGoldLight.withValues(alpha: 0.85),
          width: 0.85,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 11,
            color: AppColors.dotaGoldLight,
          ),
          SizedBox(width: 3.0),
          Text(
            'W',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              color: AppColors.dotaGoldLight,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    final verticalBar = Container(
      width: 2.0,
      height: 16.0,
      decoration: BoxDecoration(
        color: AppColors.dotaGold,
        borderRadius: BorderRadius.circular(1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.dotaGold.withValues(alpha: 0.45),
            blurRadius: 3,
          ),
        ],
      ),
    );

    return SizedBox(
      width: indicatorWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isLeft ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: isLeft
              ? [wBadge, const SizedBox(width: 3.0), verticalBar]
              : [verticalBar, const SizedBox(width: 3.0), wBadge],
        ),
      ),
    );
  }
}

/// Conteúdo especializado da linha quando o mapa foi decidido por W.O.
class SeriesWalkoverGameContent extends StatelessWidget {
  final int gameIndex;
  final bool isTeamAWinner;
  final bool isTeamBWinner;
  final VoidCallback? onTap;

  const SeriesWalkoverGameContent({
    super.key,
    required this.gameIndex,
    required this.isTeamAWinner,
    required this.isTeamBWinner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            'G$gameIndex',
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
        const SizedBox(width: 4),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: _WalkoverTeamBadge(isWinner: isTeamAWinner),
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '--:--',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3.5),
              Text(
                '-  -  -',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: _WalkoverTeamBadge(isWinner: isTeamBWinner),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
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

class _WalkoverTeamBadge extends StatelessWidget {
  final bool isWinner;

  const _WalkoverTeamBadge({required this.isWinner});

  @override
  Widget build(BuildContext context) {
    if (isWinner) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.0),
          decoration: BoxDecoration(
            color: AppColors.dotaGold.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: AppColors.dotaGoldLight.withValues(alpha: 0.85),
              width: 1.0,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 14,
                color: AppColors.dotaGoldLight,
              ),
              SizedBox(width: 6.0),
              Text(
                'VENCEDOR POR W.O.',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dotaGoldLight,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.0),
        decoration: BoxDecoration(
          color: AppColors.canvasSurface.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Text(
          'DERROTA POR W.O.',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary.withValues(alpha: 0.45),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _FirstPickCoinBadge extends StatelessWidget {
  final bool isFp;

  const _FirstPickCoinBadge({required this.isFp});

  @override
  Widget build(BuildContext context) {
    if (!isFp) {
      return const SizedBox(width: 20, height: 20);
    }

    return Tooltip(
      message: 'First Pick (Primeira Escolha no Draft)',
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.35, -0.4),
            radius: 0.95,
            colors: [
              AppColors.dotaGoldLight,
              AppColors.dotaGold,
            ],
          ),
          border: Border.all(
            color: AppColors.dotaGoldLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.dotaGold.withValues(alpha: 0.50),
              blurRadius: 5,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.background.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

