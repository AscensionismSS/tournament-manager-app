import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/match_series_dto.dart';
import '../../models/tournament_dto.dart';
import '../../models/tournament_team_dto.dart';
import '../../../draft/models/draft_team_dto.dart';
import 'tournament_bye_card.dart';
import 'tournament_series_card.dart';

/// Seção de uma Rodada com indicador visual de energia gamer, Wrap responsivo de partidas
/// e proteção semântica para cálculo de folga (BYE) restrita à Fase de Grupos.
/// No desktop amplo, alinha exatamente 3 cards preenchendo os limites de cada lado.
class TournamentRoundSection extends StatelessWidget {
  final TournamentDto tournament;
  final int round;
  final String? title;
  final List<MatchSeriesDto> roundMatches;
  final List<TournamentTeamDto>? byeTeams;
  final void Function(MatchSeriesDto match)? onMatchTap;
  final bool isAdmin;
  final void Function(MatchSeriesDto match, int gameIndex)? onRecordResult;
  final void Function(MatchSeriesDto match, int gameIndex)? onEditResult;
  final void Function(MatchSeriesDto match)? onAdminManage;
  final List<DraftTeamDto>? draftTeams;

  const TournamentRoundSection({
    super.key,
    required this.tournament,
    required this.round,
    this.title,
    required this.roundMatches,
    this.byeTeams,
    this.onMatchTap,
    this.isAdmin = false,
    this.onRecordResult,
    this.onEditResult,
    this.onAdminManage,
    this.draftTeams,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Resolução segura de Folgas (BYE):
    // Prioriza a lista calculada pelo orquestrador (com filtros conscientes de time e status).
    // Caso ausente, utiliza fallback semântico restrito à Fase de Grupos com número ímpar.
    final List<TournamentTeamDto> resolvedByeTeams;
    if (byeTeams != null) {
      resolvedByeTeams = byeTeams!;
    } else {
      final isGroupStageRound = roundMatches.any((m) => m.isGroupStageMatch);
      if (!isGroupStageRound || !tournament.teamsPerGroup.isOdd) {
        resolvedByeTeams = const [];
      } else {
        final playingTeamIds = <String>{};
        for (final m in roundMatches) {
          if (m.teamAId != null) playingTeamIds.add(m.teamAId!);
          if (m.teamBId != null) playingTeamIds.add(m.teamBId!);
        }

        resolvedByeTeams = tournament.teams
            .where(
                (team) => team.id.isNotEmpty && !playingTeamIds.contains(team.id))
            .toList();
      }
    }

    // Rótulo dinâmico e preciso para a contagem no cabeçalho
    final int matchesCount = roundMatches.length;
    final int byesCount = resolvedByeTeams.length;
    final String countLabel;
    if (matchesCount > 0 && byesCount > 0) {
      final s = matchesCount == 1 ? '1 SÉRIE' : '$matchesCount SÉRIES';
      final b = byesCount == 1 ? '1 FOLGA' : '$byesCount FOLGAS';
      countLabel = '$s • $b';
    } else if (matchesCount > 0) {
      countLabel = '$matchesCount ${matchesCount == 1 ? "SÉRIE" : "SÉRIES"}';
    } else if (byesCount > 0) {
      countLabel = '$byesCount ${byesCount == 1 ? "FOLGA" : "FOLGAS"}';
    } else {
      countLabel = '0 SÉRIES';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final bool isMobile = availableWidth < 700;

        // Distribui exatamente de ponta a ponta:
        // 3 colunas no desktop amplo (tocando com perfeição os limites esquerdo e direito),
        // 2 em telas intermediárias e 1 no mobile.
        final int columns;
        if (availableWidth >= 1500) {
          columns = 3;
        } else if (availableWidth >= 1000) {
          columns = 2;
        } else {
          columns = 1;
        }

        const double spacing = 16.0;
        final double calculatedCardWidth = columns == 1
            ? availableWidth
            : ((availableWidth - (spacing * (columns - 1))) / columns)
                .floorToDouble();

        final int formatMaxGames =
            roundMatches.isNotEmpty ? roundMatches.first.maxGames : 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho padronizado da Rodada com AppSectionHeader oficial
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSectionHeader(
                title: title ?? 'RODADA $round',
                countLabel: countLabel,
                accentColor: AppColors.dotaGoldLight,
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  size: 15,
                  color: AppColors.dotaGoldLight,
                ),
              ),
            ),

            // Grid/Wrap de Confrontos da Rodada e Card de Folga (BYE) preenchendo os limites
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...roundMatches.map(
                  (m) => TournamentSeriesCard(
                    match: m,
                    isMobile: isMobile,
                    customCardWidth: calculatedCardWidth,
                    onTap: onMatchTap,
                    isAdmin: isAdmin,
                    onRecordResult: onRecordResult,
                    onEditResult: onEditResult,
                    onAdminManage: onAdminManage,
                    draftTeams: draftTeams,
                    tournamentTeams: tournament.teams,
                    isResultSubmissionLocked: tournament.isResultSubmissionLocked,
                    resultLockReason: tournament.resultLockReason,
                  ),
                ),
                ...resolvedByeTeams.map(
                  (team) => TournamentByeCard(
                    team: team,
                    round: round,
                    isMobile: isMobile,
                    customCardWidth: calculatedCardWidth,
                    formatMaxGames: formatMaxGames,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
