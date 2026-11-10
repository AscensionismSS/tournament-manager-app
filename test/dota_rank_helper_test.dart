import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/utils/dota_rank_helper.dart';

void main() {
  group('DotaRankHelper', () {
    test('parseTierNumber parses 2-digit Valve tiers correctly', () {
      expect(DotaRankHelper.parseTierNumber(11), 1);
      expect(DotaRankHelper.parseTierNumber(25), 2);
      expect(DotaRankHelper.parseTierNumber(33), 3);
      expect(DotaRankHelper.parseTierNumber(41), 4);
      expect(DotaRankHelper.parseTierNumber(55), 5);
      expect(DotaRankHelper.parseTierNumber(62), 6);
      expect(DotaRankHelper.parseTierNumber(74), 7);
      expect(DotaRankHelper.parseTierNumber(80), 8);
    });

    test('parseTierNumber parses single digit tiers correctly', () {
      expect(DotaRankHelper.parseTierNumber(1), 1);
      expect(DotaRankHelper.parseTierNumber(8), 8);
      expect(DotaRankHelper.parseTierNumber(0), 0);
      expect(DotaRankHelper.parseTierNumber(9), 0);
    });

    test('parseTierNumber parses string names correctly', () {
      expect(DotaRankHelper.parseTierNumber('Heraldo'), 1);
      expect(DotaRankHelper.parseTierNumber('guardian'), 2);
      expect(DotaRankHelper.parseTierNumber('Crusader'), 3);
      expect(DotaRankHelper.parseTierNumber('Archon'), 4);
      expect(DotaRankHelper.parseTierNumber('Legend'), 5);
      expect(DotaRankHelper.parseTierNumber('Ancient'), 6);
      expect(DotaRankHelper.parseTierNumber('Divine'), 7);
      expect(DotaRankHelper.parseTierNumber('Immortal'), 8);
      expect(DotaRankHelper.parseTierNumber('Unknown'), 0);
    });

    test('parseRankStars parses stars accurately', () {
      expect(DotaRankHelper.parseRankStars(73), 3);
      expect(DotaRankHelper.parseRankStars(55), 5);
      expect(DotaRankHelper.parseRankStars(80), 0);
      expect(DotaRankHelper.parseRankStars(1, 4), 4);
    });

    test('formatRankDetail handles normal and immortal ranks', () {
      expect(DotaRankHelper.formatRankDetail(rankTier: 73), 'Divine 3');
      expect(DotaRankHelper.formatRankDetail(rankTier: 80, leaderboardRank: 42), 'Immortal #42');
      expect(DotaRankHelper.formatRankDetail(rankTier: 80), 'Immortal');
      expect(DotaRankHelper.formatRankDetail(rankTier: null), 'Sem Rank');
    });
  });
}
