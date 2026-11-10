import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_creator_front/core/navigation/app_router.dart';

void main() {
  test('GoRouter matches /tournaments/:id/draft-room before wildcard :tab route', () {
    final match = AppRouter.router.configuration.findMatch(
      Uri.parse('/tournaments/test-tournament-id/draft-room'),
    );

    expect(match.matches.isNotEmpty, isTrue);
    final leaf = match.matches.last;
    final route = leaf is ShellRouteMatch ? leaf.matches.last.route : leaf.route;
    expect((route as GoRoute).name, equals('tournament_draft_room'));
  });
}

