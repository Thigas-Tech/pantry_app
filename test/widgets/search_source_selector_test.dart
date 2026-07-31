/// Widget tests for [SearchSourceSelector].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/search_filter.dart';
import 'package:pantry_app/widgets/search_source_selector.dart';

void main() {
  Future<void> pumpSelector(
    WidgetTester tester, {
    SearchSource value = SearchSource.off,
    ValueChanged<SearchSource>? onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchSourceSelector(
            label: 'Source: ',
            value: value,
            onChanged: onChanged ?? (_) {},
            offLabel: 'Open Food Facts',
            usdaLabel: 'USDA',
            inventoryLabel: 'My Pantry',
          ),
        ),
      ),
    );
  }

  group('SearchSourceSelector', () {
    testWidgets('renders the label and current value', (tester) async {
      await pumpSelector(tester);
      expect(find.text('Source: '), findsOneWidget);
      expect(find.text('Open Food Facts'), findsOneWidget);
    });

    testWidgets('shows a dropdown with all three sources', (tester) async {
      await pumpSelector(tester);
      await tester.tap(find.byType(DropdownButton<SearchSource>));
      await tester.pumpAndSettle();
      expect(find.text('Open Food Facts'), findsWidgets);
      expect(find.text('USDA'), findsWidgets);
      expect(find.text('My Pantry'), findsWidgets);
    });

    testWidgets('selecting a source calls onChanged', (tester) async {
      SearchSource? selected;
      await pumpSelector(tester, onChanged: (v) => selected = v);
      await tester.tap(find.byType(DropdownButton<SearchSource>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USDA').last);
      await tester.pumpAndSettle();
      expect(selected, SearchSource.usda);
    });
  });
}
