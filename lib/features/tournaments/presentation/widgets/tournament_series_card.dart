import 'package:flutter/material.dart';
import '../../../../core/models/system_security_settings.dart';
import '../../../../core/services/system_security_service.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/match_series_dto.dart';
import '../../models/tournament_team_dto.dart';
import '../../../draft/models/draft_team_dto.dart';
import 'match_card/series_game_pending_row.dart';
import 'match_card/series_game_row.dart';
import 'match_details/game_detail_dialog.dart';

/// Card oficial de uma série/confronto no Calendário de Partidas (Dumb UI).
/// Segue a identidade visual de e-sports com:
/// - Faixa superior balanceada: Tipo/Formato da rodada (MD2) no centro exato,
///   status contextual (ENCERRADO, EM ANDAMENTO, A DEFINIR) na direita e botão admin na esquerda
/// - Equipes posicionadas nos extremos com espaço amplo para nomes sem truncamento
/// - Pílula centralizada com o placar geral da série (alinhada no mesmo eixo vertical dos mapas)
/// - Linhas de mapas com G1 na extrema esquerda, Picks, 7 Bans, centro harmônico e seta > na extrema direita
class TournamentSeriesCard extends StatelessWidget {
  final MatchSeriesDto match;
  final bool isMobile;
  final void Function(MatchSeriesDto match)? onTap;
  final bool isAdmin;
  final void Function(MatchSeriesDto match, int gameIndex)? onRecordResult;
  final void Function(MatchSeriesDto match, int gameIndex)? onEditResult;
  final void Function(MatchSeriesDto match)? onAdminManage;
  final double? customCardWidth;
  final List<DraftTeamDto>? draftTeams;
  final List<TournamentTeamDto>? tournamentTeams;
  final String? stageBadgeLabel;
  final Color? stageBadgeColor;
  final IconData? stageBadgeIcon;
  final bool isResultSubmissionLocked;
  final String? resultLockReason;

  const TournamentSeriesCard({
    super.key,
    required this.match,
    required this.isMobile,
    this.onTap,
    this.isAdmin = false,
    this.onRecordResult,
    this.onEditResult,
    this.onAdminManage,
    this.customCardWidth,
    this.draftTeams,
    this.tournamentTeams,
    this.stageBadgeLabel,
    this.stageBadgeColor,
    this.stageBadgeIcon,
    this.isResultSubmissionLocked = false,
    this.resultLockReason,
  });

  /// Resolve o nome atualizado do time caso tenha sido renomeado no draft ou torneio
  String _resolveTeamName(String? teamId, String fallback) {
    if (teamId != null) {
      if (draftTeams != null) {
        for (final t in draftTeams!) {
          if (t.id == teamId && t.name.trim().isNotEmpty) return t.name;
        }
      }
      if (tournamentTeams != null) {
        for (final t in tournamentTeams!) {
          if (t.id == teamId && t.name.trim().isNotEmpty) return t.name;
        }
      }
    }
    return fallback;
  }

  String get _displayTeamA => _resolveTeamName(match.teamAId, match.displayTeamA);
  String get _displayTeamB => _resolveTeamName(match.teamBId, match.displayTeamB);

  bool get _effectiveResultSubmissionLocked =>
      isResultSubmissionLocked ||
      SystemSecurityService.instance.isResultSubmissionLocked;

  String get _effectiveResultLockReason {
    if (SystemSecurityService.instance.isResultSubmissionLocked) {
      final msg = SystemSecurityService.instance.message;
      if (msg != null && msg.trim().isNotEmpty) return msg.trim();
      return 'O envio e alteração de resultados de partidas está temporariamente bloqueado pela administração do sistema.';
    }
    return (resultLockReason != null && resultLockReason!.trim().isNotEmpty)
        ? resultLockReason!.trim()
        : 'O envio de novos resultados para este campeonato foi temporariamente suspenso pela organização.';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDone = match.isCompleted;
    final isLive = match.isOngoing;

    final int displayScoreA = match.scoreTeamA;
    final int displayScoreB = match.scoreTeamB;

    final bool isTeamAWinner = match.isTeamAWinner;
    final bool isTeamBWinner = match.isTeamBWinner;

    // Largura calculada dinamicamente ou proporcional (540px desktop) para acomodar heróis em alta resolução (25.5px/21.5px)
    final double cardWidth = customCardWidth ??
        (isMobile ? (screenWidth - 24).clamp(340.0, 560.0) : 540.0);

    // Cores de borda e sombra limpas e sóbrias (sem highlight neon em volta do card em andamento e sem borda verde conflitante)
    final Color borderColor = isDone && (isTeamAWinner || isTeamBWinner)
        ? AppColors.dotaGold.withValues(alpha: 0.38)
        : AppColors.border;

    final List<BoxShadow> cardShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.22),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];

    return ValueListenableBuilder<SystemSecuritySettings>(
      valueListenable: SystemSecurityService.instance.settingsNotifier,
      builder: (context, security, _) {
        return Material(
          color: Colors.transparent,
          child: Container(
            width: cardWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: 0.85,
          ),
          boxShadow: cardShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Faixa Superior (Top Strip): Indicador de Rodada/Fase na esquerda, Formato (MD3) no centro, Status na direita
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
              decoration: BoxDecoration(
                color: AppColors.canvasSurface.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(9)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Esquerda: Indicador da Rodada / Chave (ex: R1 UPPER • U1, PLAY-IN • PI, FINAL UPPER • UF)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildStageOrRoundBadge(),
                    ),
                  ),
                  // Centro: Tipo / Formato da Rodada (MD2, MD3, etc.)
                  Center(
                    child: _buildFormatBadge(),
                  ),

                  // Direita: Status da partida (FINALIZADO, EM ANDAMENTO, A DEFINIR)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildStatusBadge(isLive, isDone),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Linha das Equipes: Nomes nos extremos do card e Placar no Centro (com respiro visual harmônico)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Equipe A: Alinhado à direita (em direção ao centro/placar), com o Nome vindo logo colado antes do Logo
                  Expanded(
                    flex: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            _displayTeamA.toUpperCase(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isTeamAWinner
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                              color: isTeamAWinner
                                  ? AppColors.dotaGoldLight
                                  : (isDone && !isTeamAWinner
                                      ? AppColors.textSecondary
                                          .withValues(alpha: 0.5)
                                      : AppColors.textPrimary),
                              letterSpacing: 0.35,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 9),
                        AppAvatar(
                          name: _displayTeamA,
                          radius: 17,
                          backgroundColor: AppColors.canvasSurface,
                          borderColor: isTeamAWinner
                              ? AppColors.dotaGold
                              : AppColors.border.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Pílula Central do Placar da Série (Centralizada no mesmo eixo dos mapas)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: AppColors.canvasSurface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLive
                            ? AppColors.primaryNeon
                            : (isDone
                                ? AppColors.dotaGold.withValues(alpha: 0.55)
                                : AppColors.border.withValues(alpha: 0.7)),
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      '$displayScoreA  -  $displayScoreB',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isDone
                            ? AppColors.dotaGoldLight
                            : (isLive
                                ? AppColors.primaryNeon
                                : AppColors.textPrimary),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Equipe B: Alinhado à esquerda (a partir do centro/placar), com o Logo primeiro e o Nome colado logo após
                  Expanded(
                    flex: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AppAvatar(
                          name: _displayTeamB,
                          radius: 17,
                          backgroundColor: AppColors.canvasSurface,
                          borderColor: isTeamBWinner
                              ? AppColors.dotaGold
                              : AppColors.border.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            _displayTeamB.toUpperCase(),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isTeamBWinner
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                              color: isTeamBWinner
                                  ? AppColors.dotaGoldLight
                                  : (isDone && !isTeamBWinner
                                      ? AppColors.textSecondary
                                          .withValues(alpha: 0.5)
                                      : AppColors.textPrimary),
                              letterSpacing: 0.35,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Linha divisória sutil
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: AppDivider.subtle(),
            ),

            // 3. Detalhamento dos Mapas (G1 na esquerda, Picks, 7 Bans, Centro harmônico e Seta >)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildGameRows(context, isMobile),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  /// Constrói o indicador de Rodada / Etapa na esquerda da faixa superior
  Widget _buildStageOrRoundBadge() {
    final String label = stageBadgeLabel ??
        (match.round > 0 ? 'RODADA ${match.round}' : match.slotCode);
    if (label.isEmpty) return const SizedBox.shrink();

    final Color accent = stageBadgeColor ?? AppColors.textSecondary;
    final bool hasCustomStage = stageBadgeColor != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: hasCustomStage
            ? accent.withValues(alpha: 0.14)
            : AppColors.canvasSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: hasCustomStage
              ? accent.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stageBadgeIcon != null) ...[
            Icon(stageBadgeIcon, size: 11, color: accent),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: hasCustomStage ? accent : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o badge do formato da rodada (MD2, MD3, etc.) no centro exato da faixa
  Widget _buildFormatBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        match.mdBadgeLabel,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: AppColors.dotaGoldLight,
        ),
      ),
    );
  }

  /// Constrói a badge contextual de status na direita da faixa superior
  Widget _buildStatusBadge(bool isLive, bool isDone) {
    final String label = match.statusBadgeLabel;
    final Color badgeColor;
    final Color textColor;
    final IconData? icon;

    if (label == 'FINALIZADO') {
      badgeColor = AppColors.dotaGold;
      textColor = AppColors.dotaGoldLight;
      icon = Icons.check_circle_outline_rounded;
    } else if (label == 'EM ANDAMENTO') {
      badgeColor = AppColors.primaryNeon;
      textColor = AppColors.primaryNeon;
      icon = Icons.fiber_manual_record;
    } else {
      badgeColor = AppColors.border;
      textColor = AppColors.textSecondary;
      icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Gera a lista de blocos de mapa (G1, G2, G3) conforme o formato da série.
  /// Mantém sempre todos os slots (`match.maxGames`) visíveis para evitar desalinhamento de altura entre cards.
  List<Widget> _buildGameRows(BuildContext context, bool isMobile) {
    // Picks são primários (25.5px no desktop / 20.0px no mobile); Bans secundários (21.5px no desktop / 17.0px no mobile)
    final double pickSize = isMobile ? 20.0 : 25.5;
    final double banSize = isMobile ? 17.0 : 21.5;
    final int totalGames = match.maxGames;

    final List<Widget> rows = [];
    final int count = totalGames.clamp(1, 5);

    for (int i = 1; i <= count; i++) {
      final game = match.gameByNumber(i);

      if (game == null) {
        rows.add(
          RepaintBoundary(
            child: SeriesGamePendingRow(
              gameIndex: i,
              isAdmin: isAdmin,
              isSeriesCompleted: match.isCompleted,
              isLocked: _effectiveResultSubmissionLocked,
              onTap: !match.isCompleted && onRecordResult != null
                  ? (idx) {
                      if (_effectiveResultSubmissionLocked) {
                        AppFeedback.showWarning(
                          context,
                          title: 'ENVIO DE RESULTADOS BLOQUEADO',
                          message: _effectiveResultLockReason,
                        );
                        return;
                      }
                      // Regra de Chaveamento: ambas as equipes precisam estar definidas
                      if (match.teamAId == null || match.teamBId == null) {
                        AppFeedback.showWarning(
                          context,
                          message:
                              'Ambas as equipes precisam estar definidas na série antes de registrar um resultado.',
                        );
                        return;
                      }
                      // Regra de Sequência Lógica: Game N exige Game N - 1
                      if (idx > 1 && match.gameByNumber(idx - 1) == null) {
                        AppFeedback.showWarning(
                          context,
                          message:
                              'Não é possível registrar o Jogo #$idx antes de registrar o Jogo #${idx - 1}.',
                        );
                        return;
                      }
                      onRecordResult!(match, idx);
                    }
                  : null,
            ),
          ),
        );
      } else {
        rows.add(
          RepaintBoundary(
            child: SeriesGameRow(
              gameIndex: i,
              game: game,
              teamAId: match.teamAId,
              teamBId: match.teamBId,
              pickSize: pickSize,
              banSize: banSize,
              isAdmin: isAdmin,
              onEditResult: onEditResult != null
                  ? (idx) {
                      if (_effectiveResultSubmissionLocked) {
                        AppFeedback.showWarning(
                          context,
                          title: 'ENVIO DE RESULTADOS BLOQUEADO',
                          message: _effectiveResultLockReason,
                        );
                        return;
                      }
                      onEditResult!(match, idx);
                    }
                  : null,
              onTap: (gIndex) => GameDetailDialog.show(
                context,
                series: match,
                initialGameNumber: gIndex,
                draftTeams: draftTeams,
                tournamentTeams: tournamentTeams,
              ),
            ),
          ),
        );
      }
    }

    return rows;
  }
}
