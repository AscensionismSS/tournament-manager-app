import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_series_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_status.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_team_dto.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/tournament_matches_tab.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/tournament_round_section.dart';

void main() {
  group('TournamentMatchesTab & TournamentRoundSection Widget Tests', () {
    final sampleTournament = TournamentDto(
      id: 'tourney-1',
      name: 'Tsurus Cup Season 1',
      status: TournamentStatus.groupStage,
      teamCount: 4,
      groupCount: 1,
      formatType: 'GroupStageAndPlayoffs',
      playoffFormat: 'SingleElimination',
      createdAtUtc: DateTime.now(),
      teams: const [
        TournamentTeamDto(id: 't1', name: 'Team Alpha'),
        TournamentTeamDto(id: 't2', name: 'Team Beta'),
        TournamentTeamDto(id: 't3', name: 'Team Gamma'),
        TournamentTeamDto(id: 't4', name: 'Team Delta'),
      ],
    );

    testWidgets('renders empty state when no matches are scheduled',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentMatchesTab(
              tournament: sampleTournament,
              matches: const [],
            ),
          ),
        ),
      );

      expect(find.text('NENHUMA PARTIDA AGENDADA'), findsOneWidget);
    });

    testWidgets(
        'separates group stage and playoff rounds cleanly without collision',
        (tester) async {
      final matches = [
        const MatchSeriesDto(
          id: 'm1',
          tournamentId: 'tourney-1',
          slotCode: 'G_R1_M1',
          format: 'Bo1',
          status: 'Completed',
          round: 1,
          teamAId: 't1',
          teamAName: 'Team Alpha',
          scoreTeamA: 1,
          teamBId: 't2',
          teamBName: 'Team Beta',
          scoreTeamB: 0,
        ),
        const MatchSeriesDto(
          id: 'm2',
          tournamentId: 'tourney-1',
          slotCode: 'QF1',
          format: 'Bo3',
          status: 'Ongoing',
          round: 1,
          teamAId: 't3',
          teamAName: 'Team Gamma',
          scoreTeamA: 0,
          teamBId: 't4',
          teamBName: 'Team Delta',
          scoreTeamB: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentMatchesTab(
                tournament: sampleTournament,
                matches: matches,
              ),
            ),
          ),
        ),
      );

      // Verify only group stage matches are rendered in TournamentMatchesTab (playoffs are isolated in TournamentPlayoffsTab)
      expect(find.text('RODADA 1'), findsWidgets);
      expect(find.text('PLAYOFFS • RODADA 1'), findsNothing);
      expect(find.byType(TournamentRoundSection), findsOneWidget);
      // No BYE card should appear for even group of 4 teams
      expect(find.text('FOLGA NA RODADA'), findsNothing);
    });

    testWidgets(
        'renders BYE card for odd group stage tournament when team is not playing',
        (tester) async {
      final oddTournament = TournamentDto(
        id: 'tourney-odd',
        name: 'Tsurus Odd Cup',
        status: TournamentStatus.groupStage,
        teamCount: 5,
        groupCount: 1,
        formatType: 'GroupStageAndPlayoffs',
        playoffFormat: 'SingleElimination',
        createdAtUtc: DateTime.now(),
        teams: const [
          TournamentTeamDto(id: 't1', name: 'Team Alpha'),
          TournamentTeamDto(id: 't2', name: 'Team Beta'),
          TournamentTeamDto(id: 't3', name: 'Team Gamma'),
          TournamentTeamDto(id: 't4', name: 'Team Delta'),
          TournamentTeamDto(id: 't5', name: 'Team Epsilon'),
        ],
      );

      // 4 teams playing in round 1, Team Epsilon resting (BYE)
      final round1Matches = [
        const MatchSeriesDto(
          id: 'm1',
          tournamentId: 'tourney-odd',
          slotCode: 'G_R1_M1',
          format: 'Bo1',
          status: 'Pending',
          round: 1,
          teamAId: 't1',
          teamAName: 'Team Alpha',
          teamBId: 't2',
          teamBName: 'Team Beta',
        ),
        const MatchSeriesDto(
          id: 'm2',
          tournamentId: 'tourney-odd',
          slotCode: 'G_R1_M2',
          format: 'Bo1',
          status: 'Pending',
          round: 1,
          teamAId: 't3',
          teamAName: 'Team Gamma',
          teamBId: 't4',
          teamBName: 'Team Delta',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentMatchesTab(
                tournament: oddTournament,
                matches: round1Matches,
              ),
            ),
          ),
        ),
      );

      // Verify BYE card is rendered for Team Epsilon
      expect(find.text('FOLGA NA RODADA'), findsOneWidget);
      expect(find.text('Team Epsilon'), findsOneWidget);
    });

    testWidgets('renders filter bar with round, team and status selectors',
        (tester) async {
      final matches = [
        const MatchSeriesDto(
          id: 'm1',
          tournamentId: 'tourney-1',
          slotCode: 'G_R1_M1',
          format: 'Bo1',
          status: 'Pending',
          round: 1,
          teamAId: 't1',
          teamAName: 'Team Alpha',
          teamBId: 't2',
          teamBName: 'Team Beta',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentMatchesTab(
                tournament: sampleTournament,
                matches: matches,
              ),
            ),
          ),
        ),
      );

      // Verify presence of all 3 filters
      expect(find.text('Todas as Rodadas'), findsOneWidget);
      expect(find.text('Todos os Times'), findsOneWidget);
      expect(find.text('Todos os Status'), findsOneWidget);
    });

    testWidgets(
        'filtering by team in odd-team tournament suppresses false BYE cards for other teams',
        (tester) async {
      final oddTournament = TournamentDto(
        id: 'tourney-odd-7',
        name: 'Tsurus 7 Teams Cup',
        status: TournamentStatus.groupStage,
        teamCount: 7,
        groupCount: 1,
        formatType: 'GroupStageAndPlayoffs',
        playoffFormat: 'SingleElimination',
        createdAtUtc: DateTime.now(),
        teams: const [
          TournamentTeamDto(id: 't-chub', name: 'Chubreguitos'),
          TournamentTeamDto(id: 't-jum', name: 'JUMBALAIA'),
          TournamentTeamDto(id: 't3', name: 'Time 3'),
          TournamentTeamDto(id: 't4', name: 'Time 4'),
          TournamentTeamDto(id: 't5', name: 'Time 5'),
          TournamentTeamDto(id: 't6', name: 'Time 6'),
          TournamentTeamDto(id: 't-exo', name: 'Exodia'),
        ],
      );

      // Round 3 has 3 matches (6 teams playing), and Time 5 is resting (BYE)
      final round3Matches = [
        const MatchSeriesDto(
          id: 'm1',
          tournamentId: 'tourney-odd-7',
          slotCode: 'G_R3_M1',
          format: 'Bo1',
          status: 'Pending',
          round: 3,
          teamAId: 't-chub',
          teamAName: 'Time 2', // Old name in match table, updated in tournament.teams!
          teamBId: 't-jum',
          teamBName: 'JUMBALAIA',
        ),
        const MatchSeriesDto(
          id: 'm2',
          tournamentId: 'tourney-odd-7',
          slotCode: 'G_R3_M2',
          format: 'Bo1',
          status: 'Pending',
          round: 3,
          teamAId: 't-exo',
          teamAName: 'Exodia',
          teamBId: 't3',
          teamBName: 'Time 3',
        ),
        const MatchSeriesDto(
          id: 'm3',
          tournamentId: 'tourney-odd-7',
          slotCode: 'G_R3_M3',
          format: 'Bo1',
          status: 'Pending',
          round: 3,
          teamAId: 't6',
          teamAName: 'Time 6',
          teamBId: 't4',
          teamBName: 'Time 4',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentMatchesTab(
                tournament: oddTournament,
                matches: round3Matches,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Without filters: 1 BYE card for Time 5, and Chubreguitos resolved name is rendered
      expect(find.text('FOLGA NA RODADA'), findsOneWidget);
      expect(find.text('Time 5'), findsOneWidget);
      expect(find.text('CHUBREGUITOS'), findsOneWidget);

      // Filter by Chubreguitos
      await tester.tap(find.text('Todos os Times'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chubreguitos').last);
      await tester.pumpAndSettle();

      // Exactly 1 match should be visible (Chubreguitos vs Jumbalaia)
      expect(find.text('CHUBREGUITOS'), findsOneWidget);
      expect(find.text('JUMBALAIA'), findsOneWidget);
      // ZERO false BYE cards should appear!
      expect(find.text('FOLGA NA RODADA'), findsNothing);
      expect(find.text('Time 6'), findsNothing);
      expect(find.text('Time 4'), findsNothing);
    });
  });
}
