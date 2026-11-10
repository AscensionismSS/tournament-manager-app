import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/shared_widgets/shared_widgets.dart';
import 'package:tournament_creator_front/core/theme/theme.dart';

void main() {
  Widget buildTestableWidget({
    required Widget child,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }

  group('AppSelectBox Tests', () {
    testWidgets('Opens dropdown and displays all options including pinned null value', (tester) async {
      int? selectedValue = 1;

      final options = [
        const AppSelectOption<int?>(value: null, label: 'Todas as Rodadas'),
        const AppSelectOption<int?>(value: 1, label: 'Rodada 1'),
        const AppSelectOption<int?>(value: 2, label: 'Rodada 2'),
        const AppSelectOption<int?>(value: 3, label: 'Rodada 3'),
        const AppSelectOption<int?>(value: 4, label: 'Rodada 4'),
        const AppSelectOption<int?>(value: 5, label: 'Rodada 5'),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSelectBox<int?>(
            value: selectedValue,
            options: options,
            showSearch: true,
            onChanged: (val) {
              selectedValue = val;
            },
          ),
        ),
      );

      // Initially closed
      expect(find.byType(ListView), findsNothing);

      // Tap to open
      await tester.tap(find.byType(AppSelectBox<int?>));
      await tester.pumpAndSettle();

      // Dropdown is open and options are visible inside ListView
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Todas as Rodadas')), findsOneWidget);
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 1')), findsOneWidget);
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 2')), findsOneWidget);
    });

    testWidgets('Pinned option remains visible and no results message appears when search has no matches', (tester) async {
      int? selectedValue = 1;

      final options = [
        const AppSelectOption<int?>(value: null, label: 'Todas as Rodadas'),
        const AppSelectOption<int?>(value: 1, label: 'Rodada 1'),
        const AppSelectOption<int?>(value: 2, label: 'Rodada 2'),
        const AppSelectOption<int?>(value: 3, label: 'Rodada 3'),
        const AppSelectOption<int?>(value: 4, label: 'Rodada 4'),
        const AppSelectOption<int?>(value: 5, label: 'Rodada 5'),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSelectBox<int?>(
            value: selectedValue,
            options: options,
            showSearch: true,
            onChanged: (val) {
              selectedValue = val;
            },
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppSelectBox<int?>));
      await tester.pumpAndSettle();

      // Search field is present (options >= 5)
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter query "todas" - pinned option is not part of searchable matches, so matches is empty
      await tester.enterText(searchField, 'todas');
      await tester.pumpAndSettle();

      // Pinned option MUST still be present in the dropdown list
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Todas as Rodadas')), findsOneWidget);
      // "Nenhum resultado encontrado" MUST appear below it
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Nenhum resultado encontrado')), findsOneWidget);
      // Searchable options that don't match are filtered out
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 1')), findsNothing);

      // Enter arbitrary text that matches nothing
      await tester.enterText(searchField, 'inexistente');
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(ListView), matching: find.text('Todas as Rodadas')), findsOneWidget);
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Nenhum resultado encontrado')), findsOneWidget);

      // Select pinned option
      await tester.tap(find.descendant(of: find.byType(ListView), matching: find.text('Todas as Rodadas')));
      await tester.pumpAndSettle();

      // Dropdown closes and value is selected
      expect(selectedValue, isNull);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Filter matches display alongside pinned option without no results message', (tester) async {
      int? selectedValue = 2;

      final options = [
        const AppSelectOption<int?>(value: null, label: 'Todas as Rodadas'),
        const AppSelectOption<int?>(value: 1, label: 'Rodada 1'),
        const AppSelectOption<int?>(value: 2, label: 'Rodada 2'),
        const AppSelectOption<int?>(value: 3, label: 'Rodada 3'),
        const AppSelectOption<int?>(value: 4, label: 'Rodada 4'),
        const AppSelectOption<int?>(value: 5, label: 'Rodada 5'),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSelectBox<int?>(
            value: selectedValue,
            options: options,
            showSearch: true,
            onChanged: (val) {
              selectedValue = val;
            },
          ),
        ),
      );

      await tester.tap(find.byType(AppSelectBox<int?>));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '1');
      await tester.pumpAndSettle();

      // Pinned option is visible in dropdown
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Todas as Rodadas')), findsOneWidget);
      // Matched option is visible in dropdown
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 1')), findsOneWidget);
      // Non-matched option is filtered out
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 3')), findsNothing);
      // No results message is NOT visible
      expect(find.text('Nenhum resultado encontrado'), findsNothing);
    });

    testWidgets('Uses shared AppSearchBar and clear button restores all searchable options', (tester) async {
      int? selectedValue = 2;

      final options = [
        const AppSelectOption<int?>(value: null, label: 'Todas as Rodadas'),
        const AppSelectOption<int?>(value: 1, label: 'Rodada 1'),
        const AppSelectOption<int?>(value: 2, label: 'Rodada 2'),
        const AppSelectOption<int?>(value: 3, label: 'Rodada 3'),
        const AppSelectOption<int?>(value: 4, label: 'Rodada 4'),
        const AppSelectOption<int?>(value: 5, label: 'Rodada 5'),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSelectBox<int?>(
            value: selectedValue,
            options: options,
            showSearch: true,
            onChanged: (val) {
              selectedValue = val;
            },
          ),
        ),
      );

      await tester.tap(find.byType(AppSelectBox<int?>));
      await tester.pumpAndSettle();

      // AppSearchBar is rendered
      expect(find.byType(AppSearchBar), findsOneWidget);

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Rodada 4');
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 4')), findsOneWidget);
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 1')), findsNothing);

      // Find clear button
      final clearButton = find.byTooltip('Limpar busca');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // All options are restored
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Todas as Rodadas')), findsOneWidget);
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 1')), findsOneWidget);
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Rodada 4')), findsOneWidget);
    });

    testWidgets('Dropdown with only non-null options displays only no results message when query does not match', (tester) async {
      String? selectedValue = 'a';

      final options = [
        const AppSelectOption<String?>(value: 'a', label: 'Alpha'),
        const AppSelectOption<String?>(value: 'b', label: 'Beta'),
        const AppSelectOption<String?>(value: 'g', label: 'Gamma'),
        const AppSelectOption<String?>(value: 'd', label: 'Delta'),
        const AppSelectOption<String?>(value: 'e', label: 'Epsilon'),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSelectBox<String?>(
            value: selectedValue,
            options: options,
            showSearch: true,
            onChanged: (val) {
              selectedValue = val;
            },
          ),
        ),
      );

      await tester.tap(find.byType(AppSelectBox<String?>));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Zeta');
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(ListView), matching: find.text('Nenhum resultado encontrado')), findsOneWidget);
      expect(find.descendant(of: find.byType(ListView), matching: find.text('Alpha')), findsNothing);
    });
  });
}
