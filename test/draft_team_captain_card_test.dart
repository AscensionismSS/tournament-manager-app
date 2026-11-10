import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/shared_widgets/app_dual_action_overlay.dart';
import 'package:tournament_creator_front/core/shared_widgets/dota_role_icons.dart';
import 'package:tournament_creator_front/features/draft/models/draft_player_dto.dart';
import 'package:tournament_creator_front/features/draft/models/draft_team_dto.dart';
import 'package:tournament_creator_front/features/draft/presentation/widgets/draft_team_captain_card.dart';

void main() {
  const testCaptain = DraftPlayerDto(
    id: 'p1',
    name: 'Topson',
    avatarUrl: null,
    rankTier: 81,
    leaderboardRank: 120,
    preferredRole: 'mid',
  );

  const testTeam = DraftTeamDto(
    id: 'team1',
    name: 'Time 1',
    captainId: 'p1',
    pickOrder: 1,
    starters: [testCaptain],
  );

  Widget buildSubject({
    required DraftTeamDto team,
    bool isSelected = false,
    bool isReplacing = false,
    bool isLockedByAnother = false,
    bool canManage = true,
    VoidCallback? onSelectTeam,
    VoidCallback? onRemoveCaptain,
    VoidCallback? onStartReplacing,
    VoidCallback? onCancelReplacing,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 145,
          child: DraftTeamCaptainCard(
            team: team,
            isSelected: isSelected,
            isReplacing: isReplacing,
            isLockedByAnother: isLockedByAnother,
            canManage: canManage,
            onSelectTeam: onSelectTeam ?? () {},
            onRemoveCaptain: onRemoveCaptain ?? () {},
            onStartReplacing: onStartReplacing ?? () {},
            onCancelReplacing: onCancelReplacing ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('DraftTeamCaptainCard renders captain profile and team header strip', (tester) async {
    await tester.pumpWidget(buildSubject(team: testTeam));
    await tester.pumpAndSettle();

    expect(find.text('TIME 1'), findsOneWidget);
    expect(find.text('Topson'), findsOneWidget);
    expect(find.text('CAPITÃO'), findsOneWidget);
    expect(find.byType(DotaRolesDisplay), findsOneWidget);
  });

  testWidgets('DraftTeamCaptainCard shows replacing banner when isReplacing is true', (tester) async {
    bool cancelCalled = false;
    await tester.pumpWidget(
      buildSubject(
        team: testTeam,
        isReplacing: true,
        onCancelReplacing: () => cancelCalled = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SELECIONE O NOVO NO BUCKET [+]...'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);

    await tester.tap(find.text('CANCELAR'));
    expect(cancelCalled, isTrue);
  });

  testWidgets('DraftTeamCaptainCard dims opacity when isLockedByAnother is true', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        team: testTeam,
        isLockedByAnother: true,
      ),
    );
    await tester.pumpAndSettle();

    final animatedOpacityFinder = find.byType(AnimatedOpacity);
    expect(animatedOpacityFinder, findsOneWidget);

    final animatedOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
    expect(animatedOpacity.opacity, 0.35);
  });

  testWidgets('DraftTeamCaptainCard shows AppDualActionOverlay on hover with SUBSTITUIR and REMOVER', (tester) async {
    bool replacingCalled = false;
    bool removeCalled = false;

    await tester.pumpWidget(
      buildSubject(
        team: testTeam,
        onStartReplacing: () => replacingCalled = true,
        onRemoveCaptain: () => removeCalled = true,
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(DraftTeamCaptainCard)));
    await tester.pumpAndSettle();

    expect(find.byType(AppDualActionOverlay), findsOneWidget);
    expect(find.text('SUBSTITUIR'), findsOneWidget);
    expect(find.text('REMOVER'), findsOneWidget);

    await tester.tap(find.text('SUBSTITUIR'));
    await tester.pumpAndSettle();
    expect(replacingCalled, isTrue);
    expect(removeCalled, isFalse);
  });
}
