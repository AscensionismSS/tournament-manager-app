import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/shared_widgets/shared_widgets.dart';
import 'package:tournament_creator_front/features/draft/models/draft_player_dto.dart';
import 'package:tournament_creator_front/features/draft/models/draft_team_dto.dart';
import 'package:tournament_creator_front/features/draft/presentation/widgets/draft_team_starters_card.dart';

void main() {
  const testCaptain = DraftPlayerDto(
    id: 'p1',
    name: 'Topson',
    avatarUrl: null,
    rankTier: 81,
    preferredRole: 'mid',
  );

  const testStarter = DraftPlayerDto(
    id: 'p2',
    name: 'Ceb',
    avatarUrl: null,
    rankTier: 80,
    preferredRole: 'offlane',
  );

  const teamWithCaptainAndOneStarter = DraftTeamDto(
    id: 'team1',
    name: 'Time 1',
    captainId: 'p1',
    pickOrder: 0,
    starters: [testCaptain, testStarter],
  );

  Widget buildSubject({
    required DraftTeamDto team,
    bool isCurrentTurn = false,
    int? currentTurnPickNumber,
    bool isSubstituting = false,
    String? substitutingPlayerId,
    bool isDraftingSubstitutes = false,
    bool isSelectedForReserve = false,
    bool canManage = true,
    ValueChanged<DraftPlayerDto>? onStartSubstitution,
    VoidCallback? onCancelSubstitution,
    ValueChanged<DraftPlayerDto>? onRemoveReserve,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: DraftTeamStartersCard(
              team: team,
              isCurrentTurn: isCurrentTurn,
              currentTurnPickNumber: currentTurnPickNumber,
              isSubstituting: isSubstituting,
              substitutingPlayerId: substitutingPlayerId,
              isDraftingSubstitutes: isDraftingSubstitutes,
              isSelectedForReserve: isSelectedForReserve,
              canManage: canManage,
              onStartSubstitution: onStartSubstitution,
              onCancelSubstitution: onCancelSubstitution,
              onRemoveReserve: onRemoveReserve,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('DraftTeamStartersCard renders captain, starter and placeholders correctly', (tester) async {
    await tester.pumpWidget(
      buildSubject(team: teamWithCaptainAndOneStarter),
    );

    // 1. Cabeçalho da Equipe
    expect(find.text('TIME 1'), findsOneWidget);
    expect(find.text('1º PICK'), findsOneWidget);
    expect(find.text('2/5 TITULARES'), findsOneWidget);

    // 2. Capitão (Slot 1)
    expect(find.text('CAPITÃO'), findsOneWidget);
    expect(find.text('Topson'), findsOneWidget);

    // 3. Titular preenchido (Slot 2)
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('Ceb'), findsOneWidget);

    // 4. Placeholders para as vagas titulares restantes (#3, #4, #5)
    expect(find.text('#3'), findsOneWidget);
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('#5'), findsOneWidget);
    expect(find.text('Vaga Titular #3 — Aguardando Pick...'), findsOneWidget);
    expect(find.text('Vaga Titular #4 — Aguardando Pick...'), findsOneWidget);
    expect(find.text('Vaga Titular #5 — Aguardando Pick...'), findsOneWidget);

    // 5. Placeholders para as vagas de reservas (#6, #7) totalizando os 7 slots
    expect(find.text('#6'), findsOneWidget);
    expect(find.text('#7'), findsOneWidget);
    expect(find.text('Vaga Reserva #1 — (Opcional)'), findsOneWidget);
    expect(find.text('Vaga Reserva #2 — (Opcional)'), findsOneWidget);
  });

  testWidgets('DraftTeamStartersCard highlights turn and next pick placeholder when isCurrentTurn is true', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        team: teamWithCaptainAndOneStarter,
        isCurrentTurn: true,
        currentTurnPickNumber: 3,
      ),
    );

    // Turno Atual no Header
    expect(find.text('PICK #3'), findsOneWidget);

    // Próximo Pick destacado no Placeholder #3
    expect(find.text('Próximo Pick (Selecione no Bucket [+])'), findsOneWidget);
  });

  testWidgets('DraftTeamStartersCard shows CANCELAR button on substituting slot and blocks other swaps', (tester) async {
    bool cancelCalled = false;
    DraftPlayerDto? startedPlayer;

    await tester.pumpWidget(
      buildSubject(
        team: teamWithCaptainAndOneStarter,
        isSubstituting: true,
        substitutingPlayerId: 'p2',
        onStartSubstitution: (p) => startedPlayer = p,
        onCancelSubstitution: () => cancelCalled = true,
      ),
    );

    // O slot alterou totalmente exibindo a subinfo simples (evitando quebra de layout) e o botão CANCELAR compacto
    expect(find.text('Selecione no Bucket [+]'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);

    // Ao passar o mouse (hover), o nick do jogador é revelado dinamicamente
    final mouseGesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouseGesture.addPointer(location: Offset.zero);
    await mouseGesture.moveTo(tester.getCenter(find.text('Selecione no Bucket [+]')));
    await tester.pumpAndSettle();
    expect(find.text('Substituindo: Ceb'), findsOneWidget);

    // Ao mover o mouse para fora, volta ao texto padrão
    await mouseGesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('Selecione no Bucket [+]'), findsOneWidget);

    await tester.tap(find.text('CANCELAR'));
    await tester.pump();
    expect(cancelCalled, isTrue);

    // O botão interativo de iniciar substituição não deve aparecer para outros jogadores
    expect(find.byType(AppIconButton), findsNothing);
    expect(startedPlayer, isNull);
  });

  testWidgets('DraftTeamStartersCard dims card when another team is substituting', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        team: teamWithCaptainAndOneStarter,
        isSubstituting: false,
        substitutingPlayerId: 'other_player',
      ),
    );

    // Encontra o widget Opacity configurado em 0.50
    final opacityFinder = find.byType(Opacity);
    expect(opacityFinder, findsOneWidget);
    final Opacity opacityWidget = tester.widget(opacityFinder);
    expect(opacityWidget.opacity, equals(0.50));
  });

  testWidgets('DraftTeamStartersCard shows substitute and remove buttons on reserve slot and handles actions', (tester) async {
    const testReserve = DraftPlayerDto(
      id: 'res1',
      name: 'S4',
      avatarUrl: null,
      rankTier: 82,
      preferredRole: 'mid',
    );

    const teamWithReserve = DraftTeamDto(
      id: 'team1',
      name: 'Time 1',
      captainId: 'p1',
      pickOrder: 0,
      starters: [testCaptain, testStarter],
      reserves: [testReserve],
    );

    DraftPlayerDto? substituteTarget;
    DraftPlayerDto? removeTarget;

    await tester.pumpWidget(
      buildSubject(
        team: teamWithReserve,
        isSelectedForReserve: true,
        onStartSubstitution: (p) => substituteTarget = p,
        onRemoveReserve: (p) => removeTarget = p,
      ),
    );

    // 1. Contador no cabeçalho
    expect(find.text('2/5 TIT. • 1/2 RES.'), findsOneWidget);

    // 2. Slot de Reserva Preenchido #6
    expect(find.text('#6'), findsOneWidget);
    expect(find.widgetWithText(Expanded, 'S4'), findsOneWidget);

    // 3. Botão Substituir Reserva (swap) e Remover Reserva (close)
    final substituteButton = find.byTooltip('Substituir Reserva');
    final removeButton = find.byTooltip('Remover Reserva');
    expect(substituteButton, findsOneWidget);
    expect(removeButton, findsOneWidget);

    // 4. Aciona a substituição do reserva
    await tester.tap(substituteButton);
    await tester.pump();
    expect(substituteTarget?.id, equals('res1'));

    // 5. Aciona a remoção do reserva
    await tester.tap(removeButton);
    await tester.pump();
    expect(removeTarget?.id, equals('res1'));
  });

  testWidgets('DraftTeamStartersCard locks card and displays CANCELAR slot when substituting a reserve player', (tester) async {
    const testReserve = DraftPlayerDto(
      id: 'res1',
      name: 'S4',
      avatarUrl: null,
      rankTier: 82,
      preferredRole: 'mid',
    );

    const teamWithReserve = DraftTeamDto(
      id: 'team1',
      name: 'Time 1',
      captainId: 'p1',
      pickOrder: 0,
      starters: [testCaptain, testStarter],
      reserves: [testReserve],
    );

    bool cancelCalled = false;

    await tester.pumpWidget(
      buildSubject(
        team: teamWithReserve,
        isSubstituting: true,
        substitutingPlayerId: 'res1',
        onCancelSubstitution: () => cancelCalled = true,
      ),
    );

    // O slot de reserva #6 deve exibir o slot de substituição ativa com CANCELAR
    expect(find.text('#6'), findsOneWidget);
    expect(find.text('Selecione no Bucket [+]'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);

    // Hover revela dinamicamente "Substituindo: S4"
    final mouseGesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouseGesture.addPointer(location: Offset.zero);
    await mouseGesture.moveTo(tester.getCenter(find.text('Selecione no Bucket [+]')));
    await tester.pumpAndSettle();
    expect(find.text('Substituindo: S4'), findsOneWidget);

    // Clica em CANCELAR
    await tester.tap(find.text('CANCELAR'));
    await tester.pump();
    expect(cancelCalled, isTrue);

    // Os outros botões interativos devem estar desabilitados/ocultos durante a substituição
    expect(find.byType(AppIconButton), findsNothing);
  });

  testWidgets('DraftTeamStartersCard suppresses turn and next pick highlights during active substitution', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        team: teamWithCaptainAndOneStarter,
        isCurrentTurn: true,
        currentTurnPickNumber: 3,
        isSubstituting: true,
        substitutingPlayerId: 'p1', // Capitão sendo substituído
        onCancelSubstitution: () {},
      ),
    );

    // 1. Header exibe badge de SUBSTITUIÇÃO e não o PICK #3 de turno
    expect(find.text('SUBSTITUIÇÃO'), findsOneWidget);
    expect(find.text('PICK #3'), findsNothing);

    // 2. O slot do capitão é o único com ação de substituição
    expect(find.text('Selecione no Bucket [+]'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);

    // 3. O placeholder de próximo pick não deve disputar atenção nem exibir 'Próximo Pick'
    expect(find.text('Próximo Pick (Selecione no Bucket [+])'), findsNothing);
    expect(find.text('Vaga Titular #3 — Aguardando Pick...'), findsOneWidget);
  });
}

