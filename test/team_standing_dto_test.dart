import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/features/tournaments/models/tournament_standings_dto.dart';

void main() {
  group('TeamStandingDto', () {
    test('parses groupCode from json when present', () {
      final jsonWithGroupCode = {
        'rank': 1,
        'teamId': 'team-1',
        'teamName': 'Tsurus E-Sports',
        'groupCode': 'A',
        'points': 6,
      };

      final dto = TeamStandingDto.fromJson(jsonWithGroupCode);
      expect(dto.groupCode, 'A');
      expect(dto.teamName, 'Tsurus E-Sports');
      expect(dto.points, 6);
    });

    test('parses fallback group property when groupCode is omitted', () {
      final jsonWithGroup = {
        'rank': 2,
        'teamId': 'team-2',
        'teamName': 'Aegis Gaming',
        'group': 'B',
        'points': 4,
      };

      final dto = TeamStandingDto.fromJson(jsonWithGroup);
      expect(dto.groupCode, 'B');
    });

    test('parses PascalCase GroupCode from json when sent by backend', () {
      final jsonWithPascal = {
        'rank': 1,
        'teamId': 'team-1',
        'teamName': 'Tsurus E-Sports',
        'GroupCode': 'A',
        'points': 6,
      };

      final dto = TeamStandingDto.fromJson(jsonWithPascal);
      expect(dto.groupCode, 'A');
    });

    test('groupCode is null when not provided in json', () {
      final jsonNoGroup = {
        'rank': 1,
        'teamId': 'team-1',
        'teamName': 'Team Solo',
        'points': 3,
      };

      final dto = TeamStandingDto.fromJson(jsonNoGroup);
      expect(dto.groupCode, isNull);
    });
  });
}
