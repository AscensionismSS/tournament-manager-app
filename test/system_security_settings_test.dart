import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/models/system_security_settings.dart';
import 'package:tournament_creator_front/core/network/tournament_webhook_event_dto.dart';
import 'package:tournament_creator_front/core/services/system_security_service.dart';
import 'package:tournament_creator_front/core/shared_widgets/shared_widgets.dart';
import 'package:tournament_creator_front/features/admin/tournaments/controllers/admin_tournaments_controller.dart';
import 'package:tournament_creator_front/features/admin/tournaments/models/create_tournament_request.dart';
import 'package:tournament_creator_front/features/admin/tournaments/presentation/widgets/admin_tournaments_filter_bar.dart';
import 'package:tournament_creator_front/features/draft/models/draft_team_dto.dart';
import 'package:tournament_creator_front/features/draft/presentation/widgets/draft_turn_hud_banners.dart';
import 'package:tournament_creator_front/features/shell/presentation/system_security_dialog.dart';
import 'package:tournament_creator_front/features/tournaments/controllers/matches_controller.dart';
import 'package:tournament_creator_front/features/tournaments/controllers/tournament_details_controller.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_series_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_dto.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/header/tournament_header_quick_actions.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/tournament_series_card.dart';

void main() {
  group('SystemSecuritySettings Model Tests', () {
    test('SystemSecuritySettings.initial creates all-unlocked state', () {
      final initial = SystemSecuritySettings.initial();

      expect(initial.maintenanceMode, isFalse);
      expect(initial.lockResultSubmission, isFalse);
      expect(initial.lockTournamentRegistration, isFalse);
      expect(initial.lockTournamentCreation, isFalse);
      expect(initial.lockDraftPicks, isFalse);
      expect(initial.isResultSubmissionLocked, isFalse);
      expect(initial.isTournamentRegistrationLocked, isFalse);
      expect(initial.isTournamentCreationLocked, isFalse);
      expect(initial.isDraftPicksLocked, isFalse);
      expect(initial.hasAnyLock, isFalse);
      expect(initial.message, isNull);
    });

    test('fromJson parses camelCase payload correctly', () {
      final json = {
        'lockResultSubmission': true,
        'lockTournamentRegistration': true,
        'lockTournamentCreation': false,
        'lockDraftPicks': true,
        'maintenanceMode': false,
        'message': 'Manutenção preventiva programada.',
        'updatedAtUtc': '2026-11-07T14:30:00Z',
        'updatedBy': 'SuperAdmin',
        'isResultSubmissionLocked': true,
        'isTournamentRegistrationLocked': true,
        'isTournamentCreationLocked': false,
        'isDraftPicksLocked': true,
      };

      final s = SystemSecuritySettings.fromJson(json);

      expect(s.lockResultSubmission, isTrue);
      expect(s.lockTournamentRegistration, isTrue);
      expect(s.lockTournamentCreation, isFalse);
      expect(s.lockDraftPicks, isTrue);
      expect(s.maintenanceMode, isFalse);
      expect(s.message, 'Manutenção preventiva programada.');
      expect(s.updatedBy, 'SuperAdmin');
      expect(s.updatedAtUtc, isNotNull);
      expect(s.hasAnyLock, isTrue);
    });

    test('maintenanceMode enables all effective locks automatically', () {
      final json = {
        'lockResultSubmission': false,
        'lockTournamentRegistration': false,
        'lockTournamentCreation': false,
        'lockDraftPicks': false,
        'maintenanceMode': true,
        'message': 'Parada emergencial de infraestrutura.',
      };

      final s = SystemSecuritySettings.fromJson(json);

      expect(s.maintenanceMode, isTrue);
      expect(s.isResultSubmissionLocked, isTrue);
      expect(s.isTournamentRegistrationLocked, isTrue);
      expect(s.isTournamentCreationLocked, isTrue);
      expect(s.isDraftPicksLocked, isTrue);
      expect(s.hasAnyLock, isTrue);
    });

    test('toJson serializes relevant state for update request', () {
      final s = SystemSecuritySettings.initial().copyWith(
        maintenanceMode: true,
        lockTournamentCreation: true,
        message: 'Aviso urgente',
      );

      final json = s.toJson();

      expect(json['maintenanceMode'], isTrue);
      expect(json['lockTournamentCreation'], isTrue);
      expect(json['lockResultSubmission'], isFalse);
      expect(json['message'], 'Aviso urgente');
    });
  });

  group('SystemSecurityService Tests', () {
    test('updateLocal updates settingsNotifier and reactive getters', () {
      final service = SystemSecurityService.instance;
      service.updateLocal(SystemSecuritySettings.initial());

      expect(service.isMaintenanceMode, isFalse);
      expect(service.isTournamentCreationLocked, isFalse);
      expect(service.isTournamentRegistrationLocked, isFalse);
      expect(service.isResultSubmissionLocked, isFalse);
      expect(service.isDraftPicksLocked, isFalse);

      service.updateLocal(
        SystemSecuritySettings.initial().copyWith(
          lockTournamentCreation: true,
          lockTournamentRegistration: true,
          message: 'Travas operacionais ativas.',
        ),
      );

      expect(service.isTournamentCreationLocked, isTrue);
      expect(service.isTournamentRegistrationLocked, isTrue);
      expect(service.message, 'Travas operacionais ativas.');

      // Reseta para inicial
      service.updateLocal(SystemSecuritySettings.initial());
    });
  });

  group('GlobalNoticeBanner Widget Tests', () {
    testWidgets('renders MANUTENÇÃO tag and custom message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalNoticeBanner(
              message: 'Servidor sob manutenção de rede das 18h às 19h.',
            ),
          ),
        ),
      );

      expect(find.text('MANUTENÇÃO'), findsOneWidget);
      expect(
        find.text('Servidor sob manutenção de rede das 18h às 19h.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders fallback text when message is null or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalNoticeBanner(message: null),
          ),
        ),
      );

      expect(find.text('MANUTENÇÃO'), findsOneWidget);
      expect(
        find.textContaining('O sistema está temporariamente operando em Modo de Manutenção'),
        findsOneWidget,
      );
    });
  });

  group('UI Enforcement Tests - System Security Locks', () {
    tearDown(() {
      SystemSecurityService.instance.updateLocal(SystemSecuritySettings.initial());
    });

    testWidgets('AdminTournamentsFilterBar disables button when tournament creation is locked', (tester) async {
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(lockTournamentCreation: true),
      );

      final controller = AdminTournamentsController();
      bool wasNewTournamentCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTournamentsFilterBar(
              controller: controller,
              onNewTournament: () => wasNewTournamentCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('CRIAÇÃO TRAVADA'), findsOneWidget);
      final button = tester.widget<AppButton>(find.widgetWithText(AppButton, 'CRIAÇÃO TRAVADA'));
      expect(button.onPressed, isNull);

      // Desbloqueia
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(lockTournamentCreation: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOVO TORNEIO'), findsOneWidget);
      await tester.tap(find.text('NOVO TORNEIO'));
      expect(wasNewTournamentCalled, isTrue);

      controller.dispose();
    });

    testWidgets('TournamentHeaderQuickActions disables registration button when registrations are locked', (tester) async {
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(lockTournamentRegistration: true),
      );

      final tournament = TournamentDto.fromJson({
        'id': 't-reg-lock',
        'name': 'Arena Season 1',
        'status': 2, // RegistrationOpen
        'teamCount': 4,
        'formatType': 'DirectPlayoffs',
        'playoffFormat': 'SingleElimination',
        'createdAtUtc': '2026-11-01T12:00:00Z',
      });

      bool wasRegisterCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentHeaderQuickActions(
              tournament: tournament,
              canManage: false,
              canAdvanceToPlayoffs: false,
              onRegisterAction: () => wasRegisterCalled = true,
              onCloseRegistrations: () {},
              onStartTournament: () {},
            ),
          ),
        ),
      );

      expect(find.text('INSCRIÇÕES TRAVADAS'), findsOneWidget);
      final button = tester.widget<AppButton>(find.widgetWithText(AppButton, 'INSCRIÇÕES TRAVADAS'));
      expect(button.onPressed, isNull);

      // Libera inscrições
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(lockTournamentRegistration: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('INSCREVER EQUIPE'), findsOneWidget);
      await tester.tap(find.text('INSCREVER EQUIPE'));
      expect(wasRegisterCalled, isTrue);
    });

    testWidgets('TournamentSeriesCard respects global result submission lock', (tester) async {
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(
          lockResultSubmission: true,
          message: 'Auditoria de partidas em andamento.',
        ),
      );

      final series = MatchSeriesDto.fromJson({
        'id': 'series-sec-1',
        'tournamentId': 't-1',
        'teamAId': 'team-a',
        'teamBId': 'team-b',
        'displayTeamA': 'LGD Gaming',
        'displayTeamB': 'Team Spirit',
        'bestOf': 3,
        'status': 2, // Ongoing
        'scoreTeamA': 0,
        'scoreTeamB': 0,
        'games': <Map<String, dynamic>>[],
      });

      bool wasRecordCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentSeriesCard(
              match: series,
              isMobile: false,
              isAdmin: true,
              onRecordResult: (_, __) => wasRecordCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('RESULTADOS BLOQUEADOS'), findsWidgets);

      // Clica para registrar resultado
      await tester.tap(find.text('RESULTADOS BLOQUEADOS').first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));

      // Não deve ter chamado o callback de registro pois a trava global bloqueou
      expect(wasRecordCalled, isFalse);
    });

    testWidgets('DraftSnakeTurnHudBanner displays lock message when draft picks are locked', (tester) async {
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(lockDraftPicks: true),
      );

      const team = DraftTeamDto(
        id: 'team-1',
        name: 'Thunder Awaken',
        captainId: 'p-1',
        pickOrder: 0,
        starters: [],
        reserves: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DraftSnakeTurnHudBanner(
              turnTeam: team,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('ESCOLHAS DE DRAFT TRAVADAS:'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('SystemSecurityDialog renders all security switches and message input', (tester) async {
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(
          maintenanceMode: true,
          lockTournamentCreation: true,
          message: 'Manutenção programada.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SystemSecurityDialog.show(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('SEGURANÇA DO SISTEMA'), findsOneWidget);
      expect(find.text('Modo Manutenção Geral'), findsOneWidget);
      expect(find.text('Travar Criação de Torneios'), findsOneWidget);
      expect(find.text('Travar Inscrições de Torneios'), findsOneWidget);
      expect(find.text('Travar Envio de Resultados'), findsOneWidget);
      expect(find.text('Travar Escolhas de Draft (Picks)'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);
      expect(find.text('SALVAR ALTERAÇÕES'), findsOneWidget);

      // Tocar em Cancelar fecha o modal
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      expect(find.text('SEGURANÇA DO SISTEMA'), findsNothing);
    });

    testWidgets('TournamentSeriesCard reactively switches to locked when settingsNotifier changes', (tester) async {
      SystemSecurityService.instance.updateLocal(SystemSecuritySettings.initial());

      final series = MatchSeriesDto.fromJson({
        'id': 'series-reactive-1',
        'tournamentId': 't-1',
        'teamAId': 'team-a',
        'teamBId': 'team-b',
        'displayTeamA': 'LGD Gaming',
        'displayTeamB': 'Team Spirit',
        'bestOf': 3,
        'status': 2,
        'scoreTeamA': 0,
        'scoreTeamB': 0,
        'games': <Map<String, dynamic>>[],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentSeriesCard(
              match: series,
              isMobile: false,
              isAdmin: true,
              onRecordResult: (_, __) {},
            ),
          ),
        ),
      );

      // Inicialmente não tem badge de travado
      expect(find.text('RESULTADOS BLOQUEADOS'), findsNothing);

      // Trava disparada em tempo real (via SignalR/SSE)
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(
          lockResultSubmission: true,
          message: 'Auditoria de partidas ativa.',
        ),
      );
      await tester.pumpAndSettle();

      // Card reage instantaneamente sem remontar a árvore inteira
      expect(find.text('RESULTADOS BLOQUEADOS'), findsWidgets);
    });

    test('Controller guards block actions when corresponding security locks are active', () async {
      // 1. Criação de torneio
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(lockTournamentCreation: true),
      );
      final adminCtrl = AdminTournamentsController();
      final created = await adminCtrl.createTournament(
        const CreateTournamentRequest(
          name: 'Campeonato Teste',
          type: 1,
          playoffFormat: 1,
          teamCount: 4,
          groupCount: 1,
          groupStageFormat: 1,
          playoffSeriesFormat: 3,
          grandFinalSeriesFormat: 3,
          enableDraftMode: true,
        ),
      );
      expect(created, isFalse);
      adminCtrl.dispose();

      // 2. Inscrição de equipe
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(
          lockTournamentRegistration: true,
          message: 'Inscrições encerradas preventivamente.',
        ),
      );
      final detailsCtrl = TournamentDetailsController(tournamentId: 't-test');
      final regError = await detailsCtrl.addTeam('Equipe Fênix');
      expect(regError, contains('Inscrições encerradas preventivamente.'));
      detailsCtrl.dispose();

      // 3. Lançamento de resultados de partida
      SystemSecurityService.instance.updateLocal(
        SystemSecuritySettings.initial().copyWith(
          lockResultSubmission: true,
          message: 'Resultados em auditoria.',
        ),
      );
      final matchesCtrl = MatchesController();
      final manualError = await matchesCtrl.recordManualResult(
        matchId: 'm-1',
        winnerTeamId: 't-1',
        durationSeconds: 1800,
        teamAKills: 20,
        teamBKills: 15,
      );
      expect(manualError, contains('Resultados em auditoria.'));

      final woError = await matchesCtrl.recordWalkover(
        matchId: 'm-1',
        winnerTeamId: 't-1',
      );
      expect(woError, contains('Resultados em auditoria.'));
      matchesCtrl.dispose();
    });

    test('TournamentWebhookEventDto recognizes SecuritySettingsUpdated as warning event', () {
      final evt = TournamentWebhookEventDto(
        tournamentId: '00000000-0000-0000-0000-000000000000',
        tournamentName: 'Sistema',
        eventType: 'SecuritySettingsUpdated',
        message: 'Modo manutenção do sistema ativado.',
        version: 1,
        status: 'Maintenance',
        timestampUtc: DateTime.now().toUtc(),
      );

      expect(evt.isWarningEvent, isTrue);
      expect(evt.eventIcon, Icons.admin_panel_settings_rounded);
    });
  });
}
