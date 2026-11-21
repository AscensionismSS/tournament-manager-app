import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/theme/theme.dart';
import 'package:tournament_creator_front/features/pro_matches/models/pro_matches_dto.dart';

void main() {
  group('ProMatchesDto parsing & Tier S/A presentation getters', () {
    test('parses Tier S (MAJOR) and Tier A (PRO TIER A) contract accurately', () {
      final json = <String, dynamic>{
        'isConfigured': true,
        'fetchedAtUtc': '2026-11-19T06:50:00Z',
        'liveMatches': [
          {
            'matchId': 1001,
            'tournamentId': 500,
            'tournamentName': 'DreamLeague — Season 25 — Playoffs',
            'leagueName': 'DreamLeague',
            'leagueLogoUrl': 'https://cdn.example.com/dl.png',
            'tier': 'S',
            'tierLabel': 'MAJOR',
            'status': 'Live',
            'format': 'BO3',
            'scheduledAtUtc': '2026-11-19T06:00:00Z',
            'teamA': {
              'teamId': 10,
              'name': 'Team Liquid',
              'acronym': 'TL',
              'logoUrl': 'https://cdn.example.com/tl.png',
            },
            'teamB': {
              'teamId': 20,
              'name': 'Team Spirit',
              'acronym': 'TS',
              'logoUrl': 'https://cdn.example.com/ts.png',
            },
            'scoreTeamA': 1,
            'scoreTeamB': 0,
            'streams': [
              {
                'platform': 'Twitch',
                'language': 'pt',
                'languageLabel': 'PT-BR',
                'isOfficial': true,
                'isMain': false,
                'url': 'https://www.twitch.tv/esl_dota2',
              },
              {
                'platform': 'YouTube',
                'language': 'en',
                'languageLabel': 'EN',
                'isOfficial': true,
                'isMain': true,
                'url': 'https://www.youtube.com/watch?v=abc123',
              },
            ],
          },
        ],
        'tournaments': [
          {
            'tournamentId': 500,
            'name': 'DreamLeague — Season 25 — Playoffs',
            'leagueName': 'DreamLeague',
            'leagueLogoUrl': 'https://cdn.example.com/dl.png',
            'tier': 'S',
            'tierLabel': 'MAJOR',
            'prizePool': '\$1,000,000',
            'beginAtUtc': '2026-11-17T00:00:00Z',
            'endAtUtc': '2026-11-22T00:00:00Z',
            'hasLiveMatches': true,
            'liveMatches': [
              {
                'matchId': 1001,
                'tournamentId': 500,
                'tournamentName': 'DreamLeague — Season 25 — Playoffs',
                'leagueName': 'DreamLeague',
                'tier': 'S',
                'tierLabel': 'MAJOR',
                'status': 'Live',
                'format': 'BO3',
                'scheduledAtUtc': '2026-11-19T06:00:00Z',
                'teamA': {'teamId': 10, 'name': 'Team Liquid', 'acronym': 'TL'},
                'teamB': {'teamId': 20, 'name': 'Team Spirit', 'acronym': 'TS'},
                'scoreTeamA': 1,
                'scoreTeamB': 0,
                'streams': [
                  {
                    'platform': 'Twitch',
                    'language': 'pt',
                    'languageLabel': 'PT-BR',
                    'isOfficial': true,
                    'isMain': false,
                    'url': 'https://www.twitch.tv/esl_dota2',
                  },
                ],
              },
            ],
            'upcomingMatches': <Map<String, dynamic>>[],
          },
          {
            'tournamentId': 600,
            'name': 'FISSURE Universe — Episode 5',
            'leagueName': 'FISSURE',
            'tier': 'A',
            'tierLabel': 'PRO TIER A',
            'prizePool': '\$250,000',
            'hasLiveMatches': false,
            'liveMatches': <Map<String, dynamic>>[],
            'upcomingMatches': [
              {
                'matchId': 1002,
                'tournamentId': 600,
                'tournamentName': 'FISSURE Universe — Episode 5',
                'leagueName': 'FISSURE',
                'tier': 'A',
                'tierLabel': 'PRO TIER A',
                'status': 'Upcoming',
                'format': 'BO5',
                'scheduledAtUtc': '2026-11-19T14:00:00Z',
                'teamA': {'teamId': 30, 'name': 'Gaimin Gladiators', 'acronym': 'GG'},
                'teamB': {'teamId': 40, 'name': 'BetBoom Team', 'acronym': ''},
                'scoreTeamA': 0,
                'scoreTeamB': 0,
                'streams': <Map<String, dynamic>>[],
              },
            ],
          },
        ],
      };

      final overview = ProMatchesOverviewDto.fromJson(json);

      expect(overview.isConfigured, isTrue);
      expect(overview.totalLiveCount, 1);
      expect(overview.totalUpcomingCount, 1);
      expect(overview.totalMajorCount, 1);
      expect(overview.totalTierACount, 1);
      expect(overview.tournaments, hasLength(2));

      // Tier S (MAJOR)
      final major = overview.tournaments[0];
      expect(major.tier, 'S');
      expect(major.tierLabel, 'MAJOR');
      expect(major.isMajor, isTrue);
      expect(major.tierBadgeText, 'MAJOR • S');
      expect(major.tierColor, AppColors.proTierMajor);
      expect(major.tierIcon, Icons.workspace_premium_rounded);

      final majorMatch = major.liveMatches.first;
      expect(majorMatch.tier, 'S');
      expect(majorMatch.tierLabel, 'MAJOR');
      expect(majorMatch.tierBadgeText, 'MAJOR • S');
      expect(majorMatch.scoreLabel, '1 : 0');

      final streams = overview.liveMatches.first.streams;
      expect(streams[0].displayLabel, 'Twitch • PT-BR');
      expect(streams[0].accentColor, AppColors.streamTwitch);
      expect(streams[1].displayLabel, 'YouTube • EN');
      expect(streams[1].accentColor, AppColors.streamYoutube);

      // Tier A (PRO TIER A)
      final tierA = overview.tournaments[1];
      expect(tierA.tier, 'A');
      expect(tierA.tierLabel, 'PRO TIER A');
      expect(tierA.isMajor, isFalse);
      expect(tierA.tierBadgeText, 'PRO TIER A');
      expect(tierA.tierColor, AppColors.proTierA);
      expect(tierA.tierIcon, Icons.emoji_events_outlined);

      final tierAMatch = tierA.upcomingMatches.first;
      expect(tierAMatch.tier, 'A');
      expect(tierAMatch.tierLabel, 'PRO TIER A');
      expect(tierAMatch.tierBadgeText, 'PRO TIER A');
      expect(tierAMatch.teamB.displayAcronym, 'BT');
    });

    test('applies defensive tierLabel fallback when null in JSON', () {
      final overview = ProMatchesOverviewDto.fromJson({
        'isConfigured': false,
        'tournaments': [
          {
            'tournamentId': 1,
            'name': 'ESL One',
            'tier': 's',
            'tierLabel': null,
            'liveMatches': [
              {
                'matchId': 10,
                'tier': 'S',
                'tierLabel': null,
                'status': 'Live',
              },
            ],
          },
          {
            'tournamentId': 2,
            'name': 'Regional Pro League',
            'tier': 'a',
            'tierLabel': null,
            'upcomingMatches': [
              {
                'matchId': 20,
                'tier': 'A',
                'tierLabel': null,
                'status': 'Upcoming',
              },
            ],
          },
        ],
      });

      expect(overview.isConfigured, isFalse);

      final sGroup = overview.tournaments[0];
      expect(sGroup.tier, 'S');
      expect(sGroup.tierLabel, 'MAJOR');
      expect(sGroup.liveMatches.first.tierLabel, 'MAJOR');

      final aGroup = overview.tournaments[1];
      expect(aGroup.tier, 'A');
      expect(aGroup.tierLabel, 'PRO TIER A');
      expect(aGroup.upcomingMatches.first.tierLabel, 'PRO TIER A');
    });
  });
}
