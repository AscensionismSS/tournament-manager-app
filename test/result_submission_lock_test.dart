import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/network/tournament_webhook_event_dto.dart';
import 'package:tournament_creator_front/core/shared_widgets/shared_widgets.dart';
import 'package:tournament_creator_front/features/tournaments/controllers/tournament_details_controller.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_series_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_status.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/match_card/series_game_pending_row.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/tournament_details_header.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/tournament_series_card.dart';

void main() {
  group('TournamentDto Result Submission Lock Tests', () {
    test('TournamentDto parses lock fields correctly from JSON', () {
      final json = {
        'id': 't-lock-1',
        'name': 'Lock Invitational',
        'status': 4, // GroupStage
        'teamCount': 4,
        'formatType': 'GroupStageAndPlayoffs',
        'playoffFormat': 'SingleElimination',
        'createdAtUtc': '2026-11-01T12:00:00Z',
        'isResultSubmissionLocked': true,
        'resultLockReason': 'Auditoria de integridade e contestação da Rodada 2.',
        'resultLockedAtUtc': '2026-11-07T10:30:00Z',
      };

      final dto = TournamentDto.fromJson(json);

      expect(dto.isResultSubmissionLocked, isTrue);
      expect(dto.resultLockReason, 'Auditoria de integridade e contestação da Rodada 2.');
      expect(dto.resultLockedAtUtc, isNotNull);
      expect(dto.resultLockReasonLabel, 'Auditoria de integridade e contestação da Rodada 2.');
    });

    test('TournamentDto fallback lock reason label works when reason is null or empty', () {
      final json = {
        'id': 't-lock-2',
        'name': 'Open Cup',
        'status': 4,
        'teamCount': 4,
        'formatType': 'DirectPlayoffs',
        'playoffFormat': 'SingleElimination',
        'createdAtUtc': '2026-11-01T12:00:00Z',
        'isResultSubmissionLocked': true,
        'resultLockReason': '   ',
      };

      final dto = TournamentDto.fromJson(json);

      expect(dto.isResultSubmissionLocked, isTrue);
      expect(dto.resultLockReasonLabel, contains('temporariamente suspenso pela organização'));
    });
  });

  group('TournamentWebhookEventDto Result Lock Event Tests', () {
    test('TournamentResultsLocked is recognized as warning event with lock icon', () {
      final evt = TournamentWebhookEventDto(
        tournamentId: 't-lock-1',
        tournamentName: 'Major Cup',
        eventType: 'TournamentResultsLocked',
        message: 'Envio de resultados suspenso.',
        version: 2,
        status: 'GroupStage',
        timestampUtc: DateTime.now().toUtc(),
      );

      expect(evt.isWarningEvent, isTrue);
      expect(evt.eventIcon, Icons.lock_clock_rounded);
    });

    test('TournamentResultsUnlocked has unlock icon and is not a warning', () {
      final evt = TournamentWebhookEventDto(
        tournamentId: 't-lock-1',
        tournamentName: 'Major Cup',
        eventType: 'TournamentResultsUnlocked',
        message: 'Envio de resultados liberado.',
        version: 3,
        status: 'GroupStage',
        timestampUtc: DateTime.now().toUtc(),
      );

      expect(evt.isWarningEvent, isFalse);
      expect(evt.eventIcon, Icons.lock_open_rounded);
    });
  });

  group('TournamentDetailsHeader Result Lock Display Tests', () {
    testWidgets('Renders RESULTADOS TRAVADOS badge and warning banner when locked', (tester) async {
      final tournament = TournamentDto(
        id: 't-1',
        name: 'Major Championship',
        status: TournamentStatus.groupStage,
        teamCount: 8,
        groupCount: 2,
        formatType: 'GroupStageAndPlayoffs',
        playoffFormat: 'DoubleElimination',
        createdAtUtc: DateTime.now(),
        isResultSubmissionLocked: true,
        resultLockReason: 'Pausa técnica para verificação de replay.',
      );

      final controller = TournamentDetailsController(
        tournamentId: 't-1',
        initialTournament: tournament,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentDetailsHeader(
                tournament: tournament,
                controller: controller,
                canManage: true,
                onBack: () {},
                onSelectTab: (_) {},
                onRegisterAction: () {},
                onCloseRegistrations: () {},
                onStartTournament: () {},
                onLockResults: () {},
                onUnlockResults: () {},
              ),
            ),
          ),
        ),
      );

      // Verify lock badge in header
      expect(find.text('RESULTADOS TRAVADOS'), findsOneWidget);
      // Verify warning strip
      expect(
        find.textContaining('ENVIO DE RESULTADOS SUSPENSO PELA ORGANIZAÇÃO: Pausa técnica para verificação de replay.'),
        findsOneWidget,
      );

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Header does not render lock badge when unlocked', (tester) async {
      final tournament = TournamentDto(
        id: 't-2',
        name: 'Major Championship',
        status: TournamentStatus.groupStage,
        teamCount: 8,
        groupCount: 2,
        formatType: 'GroupStageAndPlayoffs',
        playoffFormat: 'DoubleElimination',
        createdAtUtc: DateTime.now(),
        isResultSubmissionLocked: false,
      );

      final controller = TournamentDetailsController(
        tournamentId: 't-2',
        initialTournament: tournament,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentDetailsHeader(
                tournament: tournament,
                controller: controller,
                canManage: true,
                onBack: () {},
                onSelectTab: (_) {},
                onRegisterAction: () {},
                onCloseRegistrations: () {},
                onStartTournament: () {},
                onLockResults: () {},
                onUnlockResults: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('RESULTADOS TRAVADOS'), findsNothing);
      expect(find.textContaining('ENVIO DE RESULTADOS SUSPENSO'), findsNothing);

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Header popup menu shows Travar Resultados when unlocked and Destravar Resultados when locked', (tester) async {
      final unlockedTournament = TournamentDto(
        id: 't-unlocked',
        name: 'Major Championship',
        status: TournamentStatus.groupStage,
        teamCount: 8,
        groupCount: 2,
        formatType: 'GroupStageAndPlayoffs',
        playoffFormat: 'DoubleElimination',
        createdAtUtc: DateTime.now(),
        isResultSubmissionLocked: false,
      );

      final controller1 = TournamentDetailsController(
        tournamentId: 't-unlocked',
        initialTournament: unlockedTournament,
      );

      bool lockActionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentDetailsHeader(
                tournament: unlockedTournament,
                controller: controller1,
                canManage: true,
                onBack: () {},
                onSelectTab: (_) {},
                onRegisterAction: () {},
                onCloseRegistrations: () {},
                onStartTournament: () {},
                onLockResults: () {
                  lockActionTriggered = true;
                },
                onUnlockResults: () {},
              ),
            ),
          ),
        ),
      );

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Travar Resultados'), findsOneWidget);
      expect(find.text('Destravar Resultados'), findsNothing);

      // Tap 'Travar Resultados'
      await tester.tap(find.text('Travar Resultados'));
      await tester.pumpAndSettle();
      expect(lockActionTriggered, isTrue);

      controller1.dispose();

      // Now test with locked tournament
      final lockedTournament = TournamentDto(
        id: 't-locked',
        name: 'Major Championship',
        status: TournamentStatus.groupStage,
        teamCount: 8,
        groupCount: 2,
        formatType: 'GroupStageAndPlayoffs',
        playoffFormat: 'DoubleElimination',
        createdAtUtc: DateTime.now(),
        isResultSubmissionLocked: true,
        resultLockReason: 'Auditoria',
      );

      final controller2 = TournamentDetailsController(
        tournamentId: 't-locked',
        initialTournament: lockedTournament,
      );

      bool unlockActionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentDetailsHeader(
                tournament: lockedTournament,
                controller: controller2,
                canManage: true,
                onBack: () {},
                onSelectTab: (_) {},
                onRegisterAction: () {},
                onCloseRegistrations: () {},
                onStartTournament: () {},
                onLockResults: () {},
                onUnlockResults: () {
                  unlockActionTriggered = true;
                },
              ),
            ),
          ),
        ),
      );

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Destravar Resultados'), findsOneWidget);
      expect(find.text('Travar Resultados'), findsNothing);

      // Tap 'Destravar Resultados'
      await tester.tap(find.text('Destravar Resultados'));
      await tester.pumpAndSettle();
      expect(unlockActionTriggered, isTrue);

      controller2.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('TournamentSeriesCard & SeriesGamePendingRow Lock Tests', () {
    testWidgets('SeriesGamePendingRow displays RESULTADOS BLOQUEADOS when locked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeriesGamePendingRow(
              gameIndex: 1,
              isAdmin: true,
              isSeriesCompleted: false,
              isLocked: true,
            ),
          ),
        ),
      );

      expect(find.text('RESULTADOS BLOQUEADOS'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock_rounded), findsOneWidget);
    });

    testWidgets('TournamentSeriesCard prevents record and shows warning feedback when locked', (tester) async {
      const match = MatchSeriesDto(
        id: 'm-1',
        tournamentId: 't-1',
        slotCode: 'M1',
        format: 'Bo3',
        round: 1,
        teamAId: 'team-a',
        teamBId: 'team-b',
        teamAName: 'Team Secret',
        teamBName: 'Team Liquid',
        status: 'Scheduled',
        games: [],
      );

      bool recordCallbackFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentSeriesCard(
              match: match,
              isMobile: false,
              isAdmin: true,
              isResultSubmissionLocked: true,
              resultLockReason: 'Partidas congeladas para investigação.',
              onRecordResult: (_, __) {
                recordCallbackFired = true;
              },
            ),
          ),
        ),
      );

      // Verify pending row shows locked state
      expect(find.text('RESULTADOS BLOQUEADOS'), findsNWidgets(3)); // Bo3 has 3 maps

      // Tap on Game 1 pending row
      await tester.tap(find.text('RESULTADOS BLOQUEADOS').first);
      await tester.pump();

      // Callback should NOT be fired because the series is locked
      expect(recordCallbackFired, isFalse);

      AppFeedback.dismiss();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
