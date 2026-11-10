import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/features/tournaments/controllers/tournament_details_controller.dart';
import 'package:tournament_creator_front/features/tournaments/models/bracket_slot_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_status.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/playoff_matches_list_view.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/tournament_playoffs_tab.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/tournament_series_card.dart';

void main() {
  group('TournamentPlayoffsTab & PlayoffMatchesListView Tests', () {
    const mockSlots = [
      BracketSlotDto(
        code: 'UPPER_R1_M1',
        stage: 'Upper',
        round: 1,
        teamASource: 'G_SEED_1',
        teamBSource: 'G_SEED_4',
        seriesFormat: 'Bo3',
      ),
      BracketSlotDto(
        code: 'LOWER_R1_M1',
        stage: 'Lower',
        round: 1,
        teamASource: 'G_SEED_5',
        teamBSource: 'G_SEED_6',
        seriesFormat: 'Bo3',
      ),
      BracketSlotDto(
        code: 'GF',
        stage: 'GrandFinal',
        round: 3,
        teamASource: 'WINNER_UF',
        teamBSource: 'WINNER_LF',
        seriesFormat: 'Bo5',
      ),
    ];

    final mockTournament = TournamentDto(
      id: 't-1',
      name: 'The International',
      status: TournamentStatus.playoffs,
      teamCount: 6,
      formatType: 'DoubleElimination',
      playoffFormat: 'DoubleElimination',
      createdAtUtc: DateTime.now(),
      bracketSlots: mockSlots,
    );

    testWidgets('alterna entre modo Chaveamento Visual e Lista de Partidas com filtros', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TournamentDetailsController(tournamentId: 't-1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentPlayoffsTab(
                tournament: mockTournament,
                controller: controller,
                canManage: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Inicia por padrão no modo Chaveamento Visual (Árvore)
      expect(find.text('CHAVEAMENTO DOS PLAYOFFS'), findsOneWidget);
      expect(find.text('CHAVEAMENTO (ÁRVORE)'), findsOneWidget);
      expect(find.text('LISTA DE PARTIDAS'), findsOneWidget);
      expect(find.text('TODAS AS CHAVES'), findsOneWidget);

      // 2. Clica no botão de alternador para LISTA DE PARTIDAS
      await tester.tap(find.text('LISTA DE PARTIDAS'));
      await tester.pumpAndSettle();

      // 3. Verifica que a visualização de lista com filtros oficiais foi ativada
      expect(find.byType(PlayoffMatchesListView), findsOneWidget);
      expect(find.text('Buscar equipe nos playoffs'), findsOneWidget);
      expect(find.text('Todas as Fases'), findsOneWidget);
      expect(find.text('Todas as Rodadas'), findsOneWidget);
      expect(find.text('Todos os Status'), findsOneWidget);

      // Verifica cabeçalhos de seções das fases
      expect(find.text('CHAVE SUPERIOR (UPPER BRACKET)'), findsOneWidget);
      expect(find.text('CHAVE INFERIOR & REPESCAGEM (LOWER BRACKET)'), findsOneWidget);
      expect(find.text('GRANDE FINAL (DECISÃO DO TÍTULO)'), findsOneWidget);

      // Verifica que os cards de séries de playoffs estão renderizados
      expect(find.byType(TournamentSeriesCard), findsNWidgets(3));

      // 4. Alterna de volta para o Chaveamento Visual
      await tester.tap(find.text('CHAVEAMENTO (ÁRVORE)'));
      await tester.pumpAndSettle();

      // Verifica que a visualização de lista sumiu e voltou a árvore
      expect(find.byType(PlayoffMatchesListView), findsNothing);
      expect(find.text('TODAS AS CHAVES'), findsOneWidget);

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
