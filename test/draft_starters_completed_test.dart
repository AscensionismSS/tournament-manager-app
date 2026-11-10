import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/features/draft/controllers/draft_controller.dart';
import 'package:tournament_creator_front/features/draft/models/draft_player_dto.dart';
import 'package:tournament_creator_front/features/draft/models/draft_state_snapshot_dto.dart';
import 'package:tournament_creator_front/features/draft/models/draft_team_dto.dart';
import 'package:tournament_creator_front/features/draft/presentation/draft_starters_completed_dialog.dart';
import 'package:tournament_creator_front/features/draft/presentation/widgets/draft_starters_completed_banner.dart';

void main() {
  group('Draft Post-Starters Decision Tests', () {
    const sampleCompletedStartersSnapshot = DraftStateSnapshotDto(
      draftSessionId: 'draft-session-123',
      tournamentId: 'tourney-456',
      state: 'DraftingStarters',
      targetTeamCount: 7,
      currentPickIndex: 28,
      draftVersion: 35,
      allStartersPicked: true,
      totalStarterPicks: 28,
      teams: [
        DraftTeamDto(
          id: 'team-1',
          name: 'Team Alpha',
          pickOrder: 1,
          captainId: 'p-cap-1',
          starters: [
            DraftPlayerDto(id: 'p1', name: 'Player 1'),
            DraftPlayerDto(id: 'p2', name: 'Player 2'),
            DraftPlayerDto(id: 'p3', name: 'Player 3'),
            DraftPlayerDto(id: 'p4', name: 'Player 4'),
          ],
        ),
      ],
    );

    test('DraftStateSnapshotDto evaluates canDecidePostStarters correctly', () {
      expect(sampleCompletedStartersSnapshot.allStartersPicked, isTrue);
      expect(sampleCompletedStartersSnapshot.isDraftingStarters, isTrue);
      expect(sampleCompletedStartersSnapshot.canDecidePostStarters, isTrue);

      const ongoingSnapshot = DraftStateSnapshotDto(
        draftSessionId: 'draft-2',
        tournamentId: 't-2',
        state: 'DraftingStarters',
        targetTeamCount: 7,
        currentPickIndex: 20,
        allStartersPicked: false,
        totalStarterPicks: 28,
      );
      expect(ongoingSnapshot.canDecidePostStarters, isFalse);

      const substitutesSnapshot = DraftStateSnapshotDto(
        draftSessionId: 'draft-3',
        tournamentId: 't-3',
        state: 'DraftingSubstitutes',
        targetTeamCount: 7,
        currentPickIndex: 28,
        allStartersPicked: true,
        totalStarterPicks: 28,
      );
      expect(substitutesSnapshot.canDecidePostStarters, isFalse);
    });

    testWidgets('DraftStartersCompletedDialog renders choices and buttons accurately',
        (tester) async {
      final controller = DraftController(
        initialSnapshot: sampleCompletedStartersSnapshot,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraftStartersCompletedDialog(
              controller: controller,
              snapshot: sampleCompletedStartersSnapshot,
            ),
          ),
        ),
      );

      // Verify title and prompt
      expect(find.text('TODOS OS TITULARES FORAM ESCOLHIDOS!'), findsOneWidget);
      expect(
        find.textContaining('completaram sua escalação titular de 5 jogadores'),
        findsOneWidget,
      );

      // Verify buttons
      expect(find.text('ALOCAR RESERVAS'), findsOneWidget);
      expect(find.text('CONCLUIR DRAFT AGORA'), findsOneWidget);
      expect(find.text('REVISAR ESCALAÇÕES NA TELA'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('DraftStartersCompletedBanner renders on top and shows action buttons',
        (tester) async {
      final controller = DraftController(
        initialSnapshot: sampleCompletedStartersSnapshot,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraftStartersCompletedBanner(
              controller: controller,
              snapshot: sampleCompletedStartersSnapshot,
            ),
          ),
        ),
      );

      // Verify banner components
      expect(find.text('TITULARES COMPLETOS'), findsOneWidget);
      expect(find.text('SNAKE DRAFT FINALIZADO'), findsOneWidget);
      expect(find.text('ALOCAR RESERVAS'), findsOneWidget);
      expect(find.text('CONCLUIR DRAFT'), findsOneWidget);

      controller.dispose();
    });
  });
}

