/// Widget tests for [SearchQueryBar].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/search_query_bar.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    bool autoFocus = false,
    bool showBackButton = false,
    VoidCallback? onBack,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchQueryBar(
            searchHint: 'Search products',
            autoFocus: autoFocus,
            showBackButton: showBackButton,
            onBack: onBack,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onClear: onClear,
          ),
        ),
      ),
    );
  }

  group('SearchQueryBar', () {
    testWidgets('renders the hint text', (tester) async {
      await pumpBar(tester);
      expect(find.text('Search products'), findsOneWidget);
    });

    testWidgets('shows the search icon leading by default', (tester) async {
      await pumpBar(tester);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows a back arrow leading when showBackButton is true', (
      tester,
    ) async {
      await pumpBar(tester, showBackButton: true, onBack: () {});
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('tapping the back arrow calls onBack', (tester) async {
      var backTapped = false;
      await pumpBar(
        tester,
        showBackButton: true,
        onBack: () => backTapped = true,
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(backTapped, isTrue);
    });

    testWidgets('typing fires onChanged', (tester) async {
      String? lastValue;
      await pumpBar(tester, onChanged: (v) => lastValue = v);
      await tester.enterText(find.byType(SearchBar), 'milk');
      expect(lastValue, 'milk');
    });

    testWidgets('submitting fires onSubmitted', (tester) async {
      String? submitted;
      await pumpBar(
        tester,
        onChanged: (_) {},
        onSubmitted: (v) => submitted = v,
      );
      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted, 'milk');
    });

    testWidgets('clear button appears only when the query is non-empty', (
      tester,
    ) async {
      await pumpBar(tester);
      expect(find.byIcon(Icons.clear), findsNothing);
      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('tapping clear clears the text and calls onClear', (
      tester,
    ) async {
      var cleared = false;
      await pumpBar(tester, onChanged: (_) {}, onClear: () => cleared = true);
      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(cleared, isTrue);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byType(SearchBar),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('autoFocus focuses the search field', (tester) async {
      await pumpBar(tester, autoFocus: true);
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('does not focus the search field by default', (tester) async {
      await pumpBar(tester);
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isFalse);
    });
  });
}
