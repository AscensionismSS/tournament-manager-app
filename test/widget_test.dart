import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/main.dart';

void main() {
  testWidgets('TournamentApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TournamentApp());
    expect(find.byType(TournamentApp), findsOneWidget);
  });
}
