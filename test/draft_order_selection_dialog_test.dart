import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/features/draft/models/draft_player_dto.dart';
import 'package:tournament_creator_front/features/draft/models/draft_state_snapshot_dto.dart';
import 'package:tournament_creator_front/features/draft/models/draft_team_dto.dart';
import 'package:tournament_creator_front/features/draft/presentation/widgets/draft_order_selection_dialog.dart';

void main() {
  DraftStateSnapshotDto createMockSnapshot() {
    return const DraftStateSnapshotDto(
      draftSessionId: 'sess-1',
      tournamentId: 'tour-1',
      state: 'SelectingCaptains',
      draftVersion: 1,
      targetTeamCount: 3,
      teams: [
        DraftTeamDto(
          id: 'team-1',
          name: 'Time 1',
          captainId: 'cap-1',
          pickOrder: 1,
          starters: [
            DraftPlayerDto(
              id: 'cap-1',
              name: 'Puppey',
              roles: ['Hard Support'],
              preferredRole: 'Hard Support',
              rankTier: 80,
            ),
          ],
        ),
        DraftTeamDto(
          id: 'team-2',
          name: 'Time 2',
          captainId: 'cap-2',
          pickOrder: 2,
          starters: [
            DraftPlayerDto(
              id: 'cap-2',
              name: 'KuroKy',
              roles: ['Support'],
              preferredRole: 'Support',
              rankTier: 80,
            ),
          ],
        ),
        DraftTeamDto(
          id: 'team-3',
          name: 'Time 3',
          captainId: 'cap-3',
          pickOrder: 3,
          starters: [
            DraftPlayerDto(
              id: 'cap-3',
              name: 'Notail',
              roles: ['Safe Lane'],
              preferredRole: 'Safe Lane',
              rankTier: 80,
            ),
          ],
        ),
      ],
      playerPool: [],
    );
  }

  testWidgets('DraftOrderSelectionDialog renders options and team list correctly',
      (tester) async {
    final snapshot = createMockSnapshot();
    int? confirmedOrderType;
    List<String>? confirmedManualOrderIds;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraftOrderSelectionDialog(
            snapshot: snapshot,
            onConfirm: ({
              required int orderType,
              List<String>? manualOrderIds,
            }) async {
              confirmedOrderType = orderType;
              confirmedManualOrderIds = manualOrderIds;
              return null;
            },
          ),
        ),
      ),
    );

    // Verifica que as opções aparecem na tela
    expect(find.text('COMO FOI NO PICK'), findsOneWidget);
    expect(find.text('SORTEIO ALEATÓRIO'), findsOneWidget);

    // Verifica que os nomes das equipes e capitães estão listados
    expect(find.text('Time 1'), findsOneWidget);
    expect(find.text('Puppey'), findsOneWidget);
    expect(find.text('Time 2'), findsOneWidget);
    expect(find.text('KuroKy'), findsOneWidget);
    expect(find.text('Time 3'), findsOneWidget);
    expect(find.text('Notail'), findsOneWidget);

    // Posições 1º, 2º e 3º presentes
    expect(find.text('1º'), findsOneWidget);
    expect(find.text('2º'), findsOneWidget);
    expect(find.text('3º'), findsOneWidget);

    // Clica em CONFIRMAR ORDEM E INICIAR DRAFT mantendo modo padrão (Como foi no pick)
    await tester.tap(find.text('CONFIRMAR ORDEM E INICIAR DRAFT'));
    await tester.pump();

    expect(confirmedOrderType, equals(1));
    expect(confirmedManualOrderIds, equals(['team-1', 'team-2', 'team-3']));
  });

  testWidgets('DraftOrderSelectionDialog switches to randomized mode with re-draw button',
      (tester) async {
    final snapshot = createMockSnapshot();
    int? confirmedOrderType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraftOrderSelectionDialog(
            snapshot: snapshot,
            onConfirm: ({
              required int orderType,
              List<String>? manualOrderIds,
            }) async {
              confirmedOrderType = orderType;
              return null;
            },
          ),
        ),
      ),
    );

    // Clica em SORTEIO ALEATÓRIO
    await tester.tap(find.text('SORTEIO ALEATÓRIO'));
    await tester.pump();

    // Botão NOVO SORTEIO deve aparecer
    expect(find.text('NOVO SORTEIO'), findsOneWidget);

    // Confirma
    await tester.tap(find.text('CONFIRMAR ORDEM E INICIAR DRAFT'));
    await tester.pump();

    expect(confirmedOrderType, equals(2));
  });
}
