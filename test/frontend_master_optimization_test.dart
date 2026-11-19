import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/navigation/app_mode.dart';
import 'package:tournament_creator_front/core/network/api_endpoints.dart';
import 'package:tournament_creator_front/core/network/signalr_service.dart';
import 'package:tournament_creator_front/core/network/tournament_webhook_event_dto.dart';
import 'package:tournament_creator_front/core/shared_widgets/shared_widgets.dart';
import 'package:tournament_creator_front/core/theme/theme.dart';
import 'package:tournament_creator_front/features/admin/invitations/controllers/invitations_controller.dart';
import 'package:tournament_creator_front/features/admin/invitations/models/invitation_dto.dart';
import 'package:tournament_creator_front/features/admin/invitations/presentation/create_invitation_dialog.dart';
import 'package:tournament_creator_front/features/admin/members/controllers/admin_members_controller.dart';
import 'package:tournament_creator_front/features/draft/controllers/draft_controller.dart';
import 'package:tournament_creator_front/features/draft/models/draft_state_snapshot_dto.dart';
import 'package:tournament_creator_front/features/members/controllers/members_controller.dart';
import 'package:tournament_creator_front/features/tournaments/models/bracket_slot_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_series_dto.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/bracket_tree/bracket_tree_canvas.dart';

void main() {
  group('AppSearchBar External Clear, Real Debounce Cancellation & Controller Swap', () {
    testWidgets(
      'External controller.clear() during active 500ms debounce cancels stale timer and allows re-searching same term',
      (tester) async {
        final externalController = TextEditingController();
        final searchedTerms = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: AppSearchBar(
                controller: externalController,
                debounceDuration: const Duration(milliseconds: 500),
                labelText: 'Buscar membros',
                onSearch: searchedTerms.add,
              ),
            ),
          ),
        );

        // 1. User types "tsurus" and waits only 200ms (debounce still pending!)
        await tester.enterText(find.byType(TextFormField), 'tsurus');
        await tester.pump(const Duration(milliseconds: 200));
        expect(searchedTerms, isEmpty);
        expect(find.byTooltip('Limpar busca'), findsOneWidget);

        // 2. User clicks "Limpar Filtros" externally BEFORE 500ms expires
        externalController.clear();
        await tester.pump();
        expect(find.byTooltip('Limpar busca'), findsNothing);

        // 3. Advance past 500ms: stale "tsurus" search MUST NOT fire on empty input!
        await tester.pump(const Duration(milliseconds: 400));
        expect(searchedTerms, isEmpty);

        // 4. Now user types "tsurus" and lets debounce complete -> fires cleanly
        await tester.enterText(find.byType(TextFormField), 'tsurus');
        await tester.pump(const Duration(milliseconds: 500));
        expect(searchedTerms, ['tsurus']);

        // 5. External clear after completed search resets _lastSearchTerm so re-typing "tsurus" works
        externalController.clear();
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), 'tsurus');
        await tester.pump(const Duration(milliseconds: 500));
        expect(searchedTerms, ['tsurus', 'tsurus']);

        externalController.dispose();
      },
    );

    testWidgets(
      'Swapping external TextEditingController via didUpdateWidget rebinds cleanly without errors',
      (tester) async {
        final firstController = TextEditingController(text: 'alpha');
        final secondController = TextEditingController();
        final searchedTerms = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: AppSearchBar(
                controller: firstController,
                debounceDuration: Duration.zero,
                labelText: 'Buscar',
                onSearch: searchedTerms.add,
              ),
            ),
          ),
        );

        expect(find.byTooltip('Limpar busca'), findsOneWidget);

        // Swap controller to empty secondController
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: AppSearchBar(
                controller: secondController,
                debounceDuration: Duration.zero,
                labelText: 'Buscar',
                onSearch: searchedTerms.add,
              ),
            ),
          ),
        );

        expect(find.byTooltip('Limpar busca'), findsNothing);
        await tester.enterText(find.byType(TextFormField), 'beta');
        await tester.pump();
        expect(secondController.text, 'beta');
        expect(searchedTerms, ['beta']);

        firstController.dispose();
        secondController.dispose();
      },
    );
  });

  group('AppModeState Route Recording & Mode Isolation', () {
    setUp(AppModeState.reset);
    tearDown(AppModeState.reset);

    test('Admin tournament route (?from=admin) does not pollute lastPlayerRoute', () {
      AppModeState.recordRoute('/members');
      expect(AppModeState.lastPlayerRoute, '/members');

      AppModeState.recordRoute('/tournaments/t-99/overview?from=admin');

      expect(AppModeState.lastPlayerRoute, '/members');
      expect(AppModeState.lastAdminRoute, '/tournaments/t-99/overview?from=admin');
    });

    test('Preserves query parameters on admin routes (e.g. ?tab=requests)', () {
      AppModeState.recordRoute('/admin/members?tab=requests');
      expect(AppModeState.lastAdminRoute, '/admin/members?tab=requests');
    });
  });

  group('DraftController & SignalRService Race Protection', () {
    tearDown(() async {
      await SignalRService.instance.stop();
    });

    test('Ignores stale SignalR & stale HTTP snapshots, foreign sessions, and post-dispose events', () {
      final initial = DraftStateSnapshotDto.fromJson({
        'draftSessionId': 'session-alpha',
        'tournamentId': 't-1',
        'state': 'DraftingStarters',
        'targetTeamCount': 2,
        'currentPickIndex': 3,
        'draftVersion': 10,
        'playerPool': <Map<String, dynamic>>[],
        'teams': <Map<String, dynamic>>[],
      });

      final controller = DraftController(initialSnapshot: initial);

      // 1. Out-of-order stale SignalR version (v9 < v10) rejected
      controller.handleRealtimeSnapshotForTest({
        'draftSessionId': 'session-alpha',
        'tournamentId': 't-1',
        'state': 'DraftingStarters',
        'targetTeamCount': 2,
        'currentPickIndex': 2,
        'draftVersion': 9,
        'playerPool': <Map<String, dynamic>>[],
        'teams': <Map<String, dynamic>>[],
      });
      expect(controller.snapshot?.draftVersion, 10);

      // 2. Foreign draftSessionId rejected on realtime stream
      controller.handleRealtimeSnapshotForTest({
        'draftSessionId': 'session-foreign',
        'tournamentId': 't-999',
        'state': 'DraftingStarters',
        'targetTeamCount': 2,
        'currentPickIndex': 8,
        'draftVersion': 99,
        'playerPool': <Map<String, dynamic>>[],
        'teams': <Map<String, dynamic>>[],
      });
      expect(controller.snapshot?.draftSessionId, 'session-alpha');
      expect(controller.snapshot?.draftVersion, 10);

      // 3. Realtime SignalR advances to v12
      controller.handleRealtimeSnapshotForTest({
        'draftSessionId': 'session-alpha',
        'tournamentId': 't-1',
        'state': 'DraftingStarters',
        'targetTeamCount': 2,
        'currentPickIndex': 5,
        'draftVersion': 12,
        'playerPool': <Map<String, dynamic>>[],
        'teams': <Map<String, dynamic>>[],
      });
      expect(controller.snapshot?.draftVersion, 12);

      // 4. Slower in-flight HTTP response with v11 arrives AFTER SignalR v12 -> must NOT clobber v12!
      controller.applyHttpSnapshotForTest({
        'draftSessionId': 'session-alpha',
        'tournamentId': 't-1',
        'state': 'DraftingStarters',
        'targetTeamCount': 2,
        'currentPickIndex': 4,
        'draftVersion': 11,
        'playerPool': <Map<String, dynamic>>[],
        'teams': <Map<String, dynamic>>[],
      });
      expect(controller.snapshot?.draftVersion, 12);
      expect(controller.snapshot?.currentPickIndex, 5);

      // 5. Post-dispose events ignored safely
      controller.dispose();
      expect(
        () => controller.handleRealtimeSnapshotForTest({
          'draftSessionId': 'session-alpha',
          'tournamentId': 't-1',
          'state': 'DraftingStarters',
          'targetTeamCount': 2,
          'currentPickIndex': 6,
          'draftVersion': 13,
          'playerPool': <Map<String, dynamic>>[],
          'teams': <Map<String, dynamic>>[],
        }),
        returnsNormally,
      );
    });

    test('SignalRService tracks active draft rooms and clears them deterministically on leave/stop', () async {
      await SignalRService.instance.stop();
      expect(SignalRService.instance.joinedTournamentIdsForTest, isEmpty);

      await SignalRService.instance.joinTournamentDraft('t-draft-1');
      await SignalRService.instance.joinTournamentDraft('t-draft-2');
      expect(
        SignalRService.instance.joinedTournamentIdsForTest,
        containsAll(['t-draft-1', 't-draft-2']),
      );

      await SignalRService.instance.leaveTournamentDraft('t-draft-1');
      expect(SignalRService.instance.joinedTournamentIdsForTest, {'t-draft-2'});

      await SignalRService.instance.stop();
      expect(SignalRService.instance.joinedTournamentIdsForTest, isEmpty);
    });
  });

  group('Controllers Use-After-Dispose & Notification Target Validation', () {
    test('MembersController, AdminMembersController and InvitationsController survive immediate dispose', () async {
      final membersCtrl = MembersController();
      final adminMembersCtrl = AdminMembersController();
      final invitesCtrl = InvitationsController();

      membersCtrl.dispose();
      adminMembersCtrl.dispose();
      invitesCtrl.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 120));
    });

    test('TournamentWebhookEventDto blocks navigation to system/Guid.Empty events', () {
      final securityEvent = TournamentWebhookEventDto(
        tournamentId: '00000000-0000-0000-0000-000000000000',
        tournamentName: 'Sistema',
        eventType: 'SecuritySettingsUpdated',
        message: 'Modo manutenção ativado',
        version: 1,
        status: 'Active',
        timestampUtc: DateTime.utc(2026, 1, 1),
      );
      final tournamentEvent = TournamentWebhookEventDto(
        tournamentId: 't-valid-123',
        tournamentName: 'Copa Tsurus',
        eventType: 'PlayoffsGenerated',
        message: 'Chaves geradas!',
        version: 2,
        status: 'Playoffs',
        timestampUtc: DateTime.utc(2026, 1, 1),
      );

      expect(securityEvent.hasValidTournamentTarget, isFalse);
      expect(tournamentEvent.hasValidTournamentTarget, isTrue);
    });
  });

  group('Invitation URL Encoding & Modern Email TLD Validation', () {
    test('InvitationDto.inviteLink and ApiEndpoints.invitationValidate encode special characters', () {
      final dto = InvitationDto(
        id: 'inv-1',
        code: 'AB+CD/EF==',
        email: 'player@tsurus.gaming',
        targetRole: 'User',
        createdByUserId: 'admin-1',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        expiresAtUtc: DateTime.utc(2026, 1, 2),
        isUsed: false,
      );

      expect(dto.inviteLink, contains('AB%2BCD%2FEF%3D%3D'));
      expect(
        ApiEndpoints.invitationValidate('AB+CD/EF=='),
        endsWith('/invitations/validate/AB%2BCD%2FEF%3D%3D'),
      );
    });

    testWidgets('CreateInvitationDialog accepts modern long TLDs (.gaming, .cloud) and + aliases', (tester) async {
      final controller = InvitationsController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CreateInvitationDialog(controller: controller),
          ),
        ),
      );
      await tester.pump();

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'capitao+dota@tsurus.gaming');
      await tester.pump();

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);

      await tester.enterText(emailField, 'invalido-sem-dominio@');
      await tester.pump();
      expect(formState.validate(), isFalse);

      controller.dispose();
    });
  });

  group('BracketTreeCanvas Pan/Zoom & Stage Switch Reset', () {
    testWidgets('Zoom controls update scale label and switching stageName resets transformation matrix', (tester) async {
      final slots = [
        BracketSlotDto.fromJson({
          'slotCode': 'GF',
          'stage': 'GrandFinal',
          'round': 1,
          'position': 1,
          'teamAName': 'Team Spirit',
          'teamBName': 'Tundra Esports',
        }),
      ];

      final matchesByCode = <String, MatchSeriesDto>{
        'GF': MatchSeriesDto.fromJson({
          'id': 'm-gf',
          'tournamentId': 't-1',
          'slotCode': 'GF',
          'stage': 'GrandFinal',
          'round': 1,
          'bestOf': 5,
          'status': 1,
          'displayTeamA': 'Team Spirit',
          'displayTeamB': 'Tundra Esports',
          'scoreTeamA': 0,
          'scoreTeamB': 0,
          'games': <Map<String, dynamic>>[],
        }),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: BracketTreeCanvas(
                slots: slots,
                matchesByCode: matchesByCode,
                stageName: 'TODAS',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('100%'), findsOneWidget);

      // Click Zoom In (+) -> 115%
      await tester.tap(find.byTooltip('Aproximar (Zoom +)'));
      await tester.pump();
      expect(find.text('115%'), findsOneWidget);

      // Switch stage filter ('TODAS' -> 'GRANDE FINAL') -> must reset pan/zoom back to 100%!
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: BracketTreeCanvas(
                slots: slots,
                matchesByCode: matchesByCode,
                stageName: 'GRANDE FINAL',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('AppInfiniteScrollFooter Zero Idle Animation & Click Fallback', () {
    testWidgets('Does not spin CircularProgressIndicator when idle and triggers onLoadMore on tap', (tester) async {
      int loadMoreCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AppInfiniteScrollFooter(
                  hasMore: true,
                  isLoadingMore: false,
                  showCompletedLabel: false,
                  loadingLabel: 'Carregando...',
                  idleLoadMoreLabel: 'Carregar mais itens',
                  completedLabel: 'Concluído',
                  horizontalPadding: 16,
                  onLoadMore: () => loadMoreCalls++,
                ),
              ],
            ),
          ),
        ),
      );

      // Zero continuous animation spinner when idle!
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Carregar mais itens'), findsOneWidget);

      await tester.tap(find.text('Carregar mais itens'));
      await tester.pump();
      expect(loadMoreCalls, 1);
    });
  });

  group('Typography Identity & Lossless PNG Asset Payload Hygiene', () {
    test('Repeated accesses to AppText styles return identical cached instances', () {
      expect(identical(AppText.h1, AppText.h1), isTrue);
      expect(identical(AppText.body, AppText.body), isTrue);
      expect(identical(AppText.caption, AppText.caption), isTrue);
      expect(identical(AppText.button, AppText.button), isTrue);
      expect(identical(AppText.buttonMedium(), AppText.buttonMedium()), isTrue);
      expect(identical(AppTheme.darkTheme, AppTheme.darkTheme), isTrue);
    });

    test('Previously 2.0MB Dota item PNGs have bloated iTXt metadata stripped (< 30KB each)', () {
      const itemPaths = [
        'assets/items/disperser.png',
        'assets/items/angels_demise.png',
        'assets/items/phylactery.png',
        'assets/items/grisgris.png',
      ];
      for (final path in itemPaths) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Missing asset $path');
        expect(
          file.lengthSync(),
          lessThan(30 * 1024),
          reason: 'Asset $path still contains bloated metadata (${file.lengthSync()} bytes)',
        );
      }
    });
  });
}
