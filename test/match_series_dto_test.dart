import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/features/tournaments/models/match_series_dto.dart';

void main() {
  group('MatchSeriesDto', () {
    test('identifies group stage slot codes correctly and prevents GF false positive', () {
      final matchSingleGroup = MatchSeriesDto.fromJson({
        'id': 'm1',
        'slotCode': 'G_R1_M1',
        'round': 1,
      });
      final matchGroupA = MatchSeriesDto.fromJson({
        'id': 'm2',
        'slotCode': 'GA_R2_M1',
        'round': 2,
      });
      final matchGroupB = MatchSeriesDto.fromJson({
        'id': 'm3',
        'slotCode': 'GB_R3_M2',
        'round': 3,
      });
      final matchGrandFinal = MatchSeriesDto.fromJson({
        'id': 'm4',
        'slotCode': 'GF',
        'round': 3,
      });
      final matchGrandFinalWithSuffix = MatchSeriesDto.fromJson({
        'id': 'm5',
        'slotCode': 'GF_M1',
        'round': 3,
      });
      final matchUpperPlayoff = MatchSeriesDto.fromJson({
        'id': 'm6',
        'slotCode': 'QF1',
        'round': 1,
      });

      // Group stage matches
      expect(matchSingleGroup.isGroupStageMatch, isTrue);
      expect(matchGroupA.isGroupStageMatch, isTrue);
      expect(matchGroupB.isGroupStageMatch, isTrue);
      expect(matchSingleGroup.isPlayoffMatch, isFalse);

      // Playoff matches (critical: GF must NOT be considered group stage!)
      expect(matchGrandFinal.isGroupStageMatch, isFalse);
      expect(matchGrandFinal.isPlayoffMatch, isTrue);
      expect(matchGrandFinalWithSuffix.isGroupStageMatch, isFalse);
      expect(matchGrandFinalWithSuffix.isPlayoffMatch, isTrue);
      expect(matchUpperPlayoff.isGroupStageMatch, isFalse);
      expect(matchUpperPlayoff.isPlayoffMatch, isTrue);

      // Group A / B distinction
      expect(matchGroupA.isGroupAMatch, isTrue);
      expect(matchGroupA.isGroupBMatch, isFalse);
      expect(matchGroupB.isGroupBMatch, isTrue);
      expect(matchGroupB.isGroupAMatch, isFalse);
    });

    test('parses round from slotCode when round is 1 or omitted', () {
      final match = MatchSeriesDto.fromJson({
        'id': 'm1',
        'slotCode': 'GA_R4_M2',
      });
      expect(match.round, 4);
      expect(match.matchNumber, 2);
    });

    test('evaluates winsNeeded and isSeriesDecided accurately', () {
      final bo3Ongoing = MatchSeriesDto.fromJson({
        'id': 'm1',
        'slotCode': 'G_R1_M1',
        'format': 'Bo3',
        'scoreTeamA': 1,
        'scoreTeamB': 1,
        'status': 'Ongoing',
      });
      expect(bo3Ongoing.maxGames, 3);
      expect(bo3Ongoing.winsNeeded, 2);
      expect(bo3Ongoing.isSeriesDecided, isFalse);

      final bo3Decided = MatchSeriesDto.fromJson({
        'id': 'm2',
        'slotCode': 'G_R1_M1',
        'format': 'Bo3',
        'scoreTeamA': 2,
        'scoreTeamB': 0,
        'status': 'Ongoing',
      });
      expect(bo3Decided.isSeriesDecided, isTrue);
    });
  });
}
