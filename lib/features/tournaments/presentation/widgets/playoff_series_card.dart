import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../models/bracket_slot_dto.dart';
import '../../models/match_series_dto.dart';

/// Card esportivo de um confronto de playoff (SRP).
/// Projeta de forma passiva (Dumb UI) o [BracketSlotDto] e o [MatchSeriesDto] correspondente.
class PlayoffSeriesCard extends StatelessWidget {
  final BracketSlotDto slot;
  final MatchSeriesDto? match;
  final VoidCallback? onTap;
  final double? width;

  const PlayoffSeriesCard({
    super.key,
    required this.slot,
    this.match,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final m = match;
    final isLive = m?.isOngoing ?? false;
    final isDone = m?.isCompleted ?? false;
    final isGrandFinal = slot.stage == 'GrandFinal';
    final isPlayIn = slot.isPlayIn;

    final hasTeamA = m?.teamAId != null;
    final hasTeamB = m?.teamBId != null;

    // Determina nomes a exibir (nome do time real ou seed/origem limpo)
    final teamAName = hasTeamA
        ? m!.teamAName!
        : BracketSlotDto.formatSeedSource(slot.teamASource);

    final teamBName = hasTeamB
        ? m!.teamBName!
        : BracketSlotDto.formatSeedSource(slot.teamBSource);

    final isTeamAWinner = m?.isTeamAWinner ?? false;
    final isTeamBWinner = m?.isTeamBWinner ?? false;

    // Borda discreta e limpa (sem highlight neon em volta de partidas em andamento)
    final borderColor = isGrandFinal
        ? AppColors.dotaGold.withValues(alpha: 0.55)
        : (isPlayIn
            ? AppColors.dotaGold.withValues(alpha: 0.40)
            : AppColors.border);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width ?? 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isGrandFinal ? 1.1 : 0.85,
          ),
          boxShadow: [
            if (isGrandFinal)
              BoxShadow(
                color: AppColors.dotaGold.withValues(alpha: 0.14),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho da Série
            _buildHeader(isLive, isDone, isGrandFinal),

            // Linha da Equipe A
            _buildTeamRow(
              name: teamAName,
              score: m?.scoreTeamA,
              hasTeam: hasTeamA,
              isWinner: isTeamAWinner,
              isLoser: isDone && !isTeamAWinner && isTeamBWinner,
              isLive: isLive,
              isTop: true,
            ),

            // Divisor interno sutil
            Divider(
              height: 1,
              thickness: 0.8,
              color: AppColors.border.withValues(alpha: 0.6),
            ),

            // Linha da Equipe B
            _buildTeamRow(
              name: teamBName,
              score: m?.scoreTeamB,
              hasTeam: hasTeamB,
              isWinner: isTeamBWinner,
              isLoser: isDone && !isTeamBWinner && isTeamAWinner,
              isLive: isLive,
              isTop: false,
            ),

            // Rodapé com destino de avanço (se houver)
            if (slot.winnerTargetSlotCode != null ||
                slot.loserTargetSlotCode != null)
              _buildTargetFooter(),
          ],
        ),
      ),
    );
  }

  Color get _stageColor {
    switch (slot.stage) {
      case 'Upper':
        return AppColors.feedbackSuccess;
      case 'Lower':
        return AppColors.primaryNeon;
      case 'PlayIn':
        return AppColors.feedbackWarning; // Laranja / Âmbar para Play-In
      case 'GrandFinal':
        return AppColors.dotaGold; // Ouro Aegis para Grande Final
      default:
        return AppColors.textPrimary;
    }
  }

  IconData get _stageIcon {
    switch (slot.stage) {
      case 'Upper':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'Lower':
        return Icons.keyboard_arrow_right_rounded;
      case 'PlayIn':
        return Icons.compare_arrows_rounded;
      case 'GrandFinal':
        return Icons.emoji_events_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  Widget _buildHeader(bool isLive, bool isDone, bool isGrandFinal) {
    final Color badgeColor;
    final Color textColor;
    final String badgeText;
    final IconData? statusIcon;

    if (isDone) {
      badgeColor = AppColors.dotaGold;
      textColor = AppColors.dotaGoldLight;
      badgeText = 'FINALIZADO';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isLive) {
      badgeColor = AppColors.primaryNeon;
      textColor = AppColors.primaryNeon;
      badgeText = 'EM ANDAMENTO';
      statusIcon = Icons.fiber_manual_record;
    } else {
      badgeColor = AppColors.border;
      textColor = AppColors.textSecondary;
      badgeText = 'A DEFINIR';
      statusIcon = null;
    }

    final stageColor = _stageColor;
    final stageIcon = _stageIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.55),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            stageIcon,
            size: 13,
            color: stageColor,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    slot.friendlyTitle.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: stageColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '• ${slot.seriesBadgeLabel}',
                  style: TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4.5),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.45),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statusIcon != null) ...[
                  Icon(statusIcon, size: 8.5, color: textColor),
                  const SizedBox(width: 3.5),
                ],
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required String name,
    required int? score,
    required bool hasTeam,
    required bool isWinner,
    required bool isLoser,
    required bool isLive,
    required bool isTop,
  }) {
    Color textColor;
    FontWeight fontWeight;

    if (isWinner) {
      textColor = AppColors.dotaGoldLight;
      fontWeight = FontWeight.w800;
    } else if (isLoser) {
      textColor = AppColors.textSecondary.withValues(alpha: 0.5);
      fontWeight = FontWeight.w500;
    } else if (hasTeam) {
      textColor = AppColors.textPrimary;
      fontWeight = FontWeight.w600;
    } else {
      textColor = AppColors.textSecondary.withValues(alpha: 0.7);
      fontWeight = FontWeight.w500;
    }

    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: isWinner
          ? AppColors.dotaGold.withValues(alpha: 0.08)
          : Colors.transparent,
      child: Row(
        children: [
          // Ícone sutil para vencedor ou ponto neutro
          if (isWinner) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 13,
              color: AppColors.dotaGold,
            ),
            const SizedBox(width: 6),
          ] else ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasTeam
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Nome da Equipe ou Placeholder limpo (ex: 1º do Grupo, Venc. U1, Perd. U2)
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: fontWeight,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Caixa de Placar
          Container(
            width: 28,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWinner
                  ? AppColors.dotaGold.withValues(alpha: 0.2)
                  : AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isWinner
                    ? AppColors.dotaGold.withValues(alpha: 0.6)
                    : AppColors.border,
                width: 0.8,
              ),
            ),
            child: Text(
              score != null ? '$score' : '-',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isWinner
                    ? AppColors.dotaGoldLight
                    : (score != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetFooter() {
    final targets = <String>[];
    if (slot.winnerTargetSlotCode != null) {
      targets.add('Venc. ➔ ${slot.winnerTargetSlotCode}');
    }
    if (slot.loserTargetSlotCode != null) {
      targets.add('Perd. ➔ ${slot.loserTargetSlotCode}');
    }

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.6,
          ),
        ),
      ),
      child: Text(
        targets.join(' • '),
        style: TextStyle(
          fontSize: 8.8,
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
