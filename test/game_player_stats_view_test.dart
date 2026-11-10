import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/features/draft/models/draft_player_dto.dart';
import 'package:tournament_creator_front/features/draft/models/draft_team_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_game_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_series_dto.dart';
import 'package:tournament_creator_front/features/tournaments/models/player_game_stats_dto.dart';
import 'package:tournament_creator_front/features/tournaments/presentation/widgets/match_details/game_player_stats_view.dart';

void main() {
  testWidgets('GamePlayerStatsView renders 3 tabs, objectives without KDA, items with backpack/buffs and switches names', (tester) async {
    final List<DraftTeamDto> mockDraftTeams = [
      const DraftTeamDto(
        id: 'team-1',
        name: 'Time 1',
        pickOrder: 1,
        starters: [
          DraftPlayerDto(id: 'p1', name: 'AdmiralBulldog', externalUserId: '76561198000000001'),
          DraftPlayerDto(id: 'p2', name: 'Dendi', externalUserId: '76561198000000002'),
        ],
      ),
      const DraftTeamDto(
        id: 'team-4',
        name: 'Time 4',
        pickOrder: 2,
        starters: [
          DraftPlayerDto(id: 'p3', name: 'Arteezy', externalUserId: '76561198000000003'),
        ],
      ),
    ];

    const series = MatchSeriesDto(
      id: 'series-1',
      tournamentId: 't-1',
      slotCode: 'MATCH_R1_M1',
      format: 'Bo1',
      status: 'Completed',
      teamAId: 'team-1',
      teamAName: 'Time 1',
      teamBId: 'team-4',
      teamBName: 'Time 4',
    );

    const game = MatchGameDto(
      id: 'game-1',
      gameNumber: 1,
      resultSource: 'ReplayParser',
      winnerTeamId: 'team-1',
      durationSeconds: 2576,
      teamAKills: 37,
      teamBKills: 25,
      teamARoshanKills: 2,
      teamAAegisStolen: 1,
      playerStats: [
        PlayerGameStatsDto(
          playerId: 'guid-random-1',
          teamId: 'team-1',
          heroId: 1,
          heroName: 'npc_dota_hero_antimage',
          kills: 10,
          deaths: 2,
          assists: 15,
          netWorth: 25545,
          goldPerMinute: 685,
          experiencePerMinute: 818,
          steamName: 'Bulldog_Steam',
          wardsPlaced: 4,
          wardsDestroyed: 2,
          towerDamage: 12500,
          heroDamage: 28400,
          heroHealing: 1200,
          itemNames: ['power_treads', 'bfury', 'manta'],
          backpackNames: ['tpscroll'],
          neutralItem: 'philosophers_stone',
          neutralItems: ['occult_bracelet', 'philosophers_stone'],
          jungleBuff: 'item_enhancement_alert',
          jungleBuffs: ['item_enhancement_mystical', 'item_enhancement_alert'],
          hasAghanimScepter: true,
          hasAghanimShard: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GamePlayerStatsView(
              series: series,
              game: game,
              draftTeams: mockDraftTeams,
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifica as 3 abas [ GERAL | OBJETIVOS | ITENS ]
    expect(find.text('GERAL'), findsOneWidget);
    expect(find.text('OBJETIVOS'), findsOneWidget);
    expect(find.text('ITENS'), findsOneWidget);

    // 1.1 Verifica os badges de Roshan e Aegis Stolen no cabeçalho do time
    expect(find.text('ROSHAN: x2'), findsOneWidget);
    expect(find.text('AEGIS STOLEN: x1'), findsOneWidget);
    expect(find.text('ROSHAN: x0'), findsOneWidget); // Time B com 0
    expect(find.text('AEGIS STOLEN: x0'), findsOneWidget);

    // 2. Modo TSURUS exibe o nome cadastrado
    expect(find.text('AdmiralBulldog'), findsOneWidget);
    expect(find.text('25.545'), findsOneWidget);

    // 3. Alterna o switch para STEAM: deve exibir Bulldog_Steam
    await tester.tap(find.text('STEAM'));
    await tester.pumpAndSettle();
    expect(find.text('Bulldog_Steam'), findsOneWidget);

    // 4. Alterna para a aba OBJETIVOS (SEM KDA!)
    await tester.tap(find.text('OBJETIVOS'));
    await tester.pumpAndSettle();
    expect(find.text('DANO A HERÓIS'), findsNWidgets(2));
    expect(find.text('DANO A TORRES'), findsNWidgets(2));
    expect(find.text('CURA'), findsNWidgets(2));
    expect(find.text('WARDS COLOCADAS'), findsNWidgets(2));
    expect(find.text('WARDS DESTRUÍDAS'), findsNWidgets(2));
    expect(find.text('28.400'), findsOneWidget); // Hero damage formatado
    expect(find.text('12.500'), findsOneWidget); // Tower damage formatado
    expect(find.text('1.200'), findsOneWidget);  // Cura formatada

    // 5. Alterna para a aba ITENS
    await tester.tap(find.text('ITENS'));
    await tester.pumpAndSettle();
    expect(find.text('INVENTÁRIO (6 SLOTS)'), findsNWidgets(2));
    expect(find.text('MOCHILA'), findsNWidgets(2));
    expect(find.text('NEUTRO & BUFF JUNGLE'), findsNWidgets(2));
    expect(find.text('BUFFS'), findsNWidgets(2));
    expect(find.byTooltip('Tier 1 • Buff de Jungle: Enhancement Mystical'), findsOneWidget);
    expect(find.byTooltip('Tier 2 • Buff de Jungle: Enhancement Alert'), findsOneWidget);
  });
}
