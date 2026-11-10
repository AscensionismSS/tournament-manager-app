import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_game_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_series_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/player_game_stats_dto.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/match_card/series_game_row.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/match_details/game_detail_dialog.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/tournament_series_card.dart';

void main() {
  group('TournamentSeriesCard Widget Tests', () {
    testWidgets('renders teams, score pill, G1 placeholder slots and direct game row actions',
        (tester) async {
      const match = MatchSeriesDto(
        id: 'series-1',
        tournamentId: 't-1',
        slotCode: 'G_R1_M1',
        format: 'Bo3',
        status: 'Pending',
        teamAId: 'team-a',
        teamAName: 'Gaming Legion',
        scoreTeamA: 0,
        teamBId: 'team-b',
        teamBName: 'Alpha Wolves',
        scoreTeamB: 0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TournamentSeriesCard(
              match: match,
              isMobile: false,
            ),
          ),
        ),
      );

      // Verify teams are rendered
      expect(find.text('GAMING LEGION'), findsOneWidget);
      expect(find.text('ALPHA WOLVES'), findsOneWidget);

      // Verify series score pill
      expect(find.text('0  -  0'), findsOneWidget);

      // Verify game row identifiers for Bo3 (G1, G2, G3)
      expect(find.text('G1'), findsOneWidget);
      expect(find.text('G2'), findsOneWidget);
      expect(find.text('G3'), findsOneWidget);

      // Verify unplayed games show clean pending status text without placeholder clutter
      expect(find.text('PARTIDA AINDA NÃO INICIADA'), findsNWidgets(3));

      // Verify status label is A DEFINIR when unplayed
      expect(find.text('A DEFINIR'), findsOneWidget);
    });

    testWidgets('tapping game row opens GameDetailDialog with map navigation when played',
        (tester) async {
      const match = MatchSeriesDto(
        id: 'series-dialog-test',
        tournamentId: 't-1',
        slotCode: 'G_R1_M1',
        format: 'Bo3',
        status: 'Ongoing',
        teamAId: 'team-a',
        teamAName: 'Team Radiance',
        scoreTeamA: 1,
        teamBId: 'team-b',
        teamBName: 'Team Dire',
        scoreTeamB: 0,
        games: [
          MatchGameDto(
            id: 'g-1',
            gameNumber: 1,
            resultSource: 'ReplayParser',
            winnerTeamId: 'team-a',
            durationSeconds: 1800,
            teamAKills: 20,
            teamBKills: 15,
          ),
          MatchGameDto(
            id: 'g-2',
            gameNumber: 2,
            resultSource: 'ReplayParser',
            winnerTeamId: 'team-b',
            durationSeconds: 2100,
            teamAKills: 18,
            teamBKills: 25,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TournamentSeriesCard(
              match: match,
              isMobile: false,
            ),
          ),
        ),
      );

      // Tap the second game row (G2)
      await tester.tap(find.text('G2'));
      await tester.pumpAndSettle();

      // Verify GameDetailDialog opened
      expect(find.byType(GameDetailDialog), findsOneWidget);
      expect(find.text('G2'), findsWidgets);

      // Tap previous map button (<) to go to Map 1
      final prevMapFinder = find.byTooltip('Jogo Anterior');
      expect(prevMapFinder, findsOneWidget);
      await tester.tap(prevMapFinder);
      await tester.pumpAndSettle();

      // Verify navigated to Map 1
      expect(find.text('G1'), findsWidgets);
    });

    testWidgets('renders played game with hero stats and win indicators',
        (tester) async {
      const playedMatch = MatchSeriesDto(
        id: 'series-2',
        tournamentId: 't-1',
        slotCode: 'G_R1_M2',
        format: 'Bo1',
        status: 'Completed',
        teamAId: 'team-a',
        teamAName: 'Team Radiance',
        scoreTeamA: 1,
        teamBId: 'team-b',
        teamBName: 'Team Dire',
        scoreTeamB: 0,
        winnerTeamId: 'team-a',
        games: [
          MatchGameDto(
            id: 'g-1',
            gameNumber: 1,
            resultSource: 'ReplayParser',
            winnerTeamId: 'team-a',
            durationSeconds: 2543, // 42:23
            teamAKills: 27,
            teamBKills: 21,
            firstPickTeamId: 'team-a',
            playerStats: [
              PlayerGameStatsDto(playerId: 'p1', teamId: 'team-a', heroId: 1, heroName: 'antimage'),
              PlayerGameStatsDto(playerId: 'p2', teamId: 'team-a', heroId: 2, heroName: 'axe'),
              PlayerGameStatsDto(playerId: 'p3', teamId: 'team-b', heroId: 3, heroName: 'bane'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TournamentSeriesCard(
              match: playedMatch,
              isMobile: false,
            ),
          ),
        ),
      );

      // Verify game score in row
      expect(find.text('27'), findsOneWidget);
      expect(find.text('21'), findsOneWidget);
      // Verify duration
      expect(find.text('42:23'), findsOneWidget);
      // Verify SeriesGameRow is rendered
      expect(find.byType(SeriesGameRow), findsOneWidget);
      // Verify FP is rendered for Team A
      expect(
          find.byTooltip('First Pick (Primeira Escolha no Draft)'), findsOneWidget);
      // Verify status label is FINALIZADO
      expect(find.text('FINALIZADO'), findsOneWidget);
    });

    testWidgets('renders format and status badges cleanly in top strip without gear icon',
        (tester) async {
      const match = MatchSeriesDto(
        id: 'series-admin',
        tournamentId: 't-1',
        slotCode: 'G_R1_M1',
        format: 'Bo3',
        status: 'Ongoing',
        teamAId: 'team-a',
        teamAName: 'Team A',
        teamBId: 'team-b',
        teamBName: 'BetBoom Team',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TournamentSeriesCard(
              match: match,
              isMobile: false,
              isAdmin: true,
            ),
          ),
        ),
      );

      // Verify gear icon is not present
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      // Verify format and status badges are present
      expect(find.text('MD3'), findsOneWidget);
      expect(find.text('EM ANDAMENTO'), findsOneWidget);
    });
  });
}
