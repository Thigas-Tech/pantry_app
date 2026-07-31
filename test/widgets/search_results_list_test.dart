/// Widget tests for [SearchResultsList].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/search_result.dart';
import 'package:pantry_app/widgets/search_results_list.dart';

void main() {
  const localMilk = Product(
    barcode: '001',
    name: 'Local Milk',
    brand: 'Brand A',
  );
  const apiBread = Product(
    barcode: '002',
    name: 'API Bread',
    brand: 'Brand B',
  );
  const produceTomato = Product(
    barcode: '003',
    name: 'Tomato',
    productType: ProductType.produce,
  );

  final results = <SearchResult>[
    const SearchResult(product: localMilk, source: ResultSource.local),
    const SearchResult(product: apiBread, source: ResultSource.api),
    const SearchResult(
      product: produceTomato,
      source: ResultSource.local,
      isInPantry: true,
    ),
  ];

  Future<void> pumpList(
    WidgetTester tester, {
    List<SearchResult>? list,
    ValueChanged<SearchResult>? onDismissed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultsList(
            results: list ?? results,
            inPantrySwipeLabel: 'Already in pantry',
            addToInventoryLabel: 'Add to inventory',
            inPantryIndicatorLabel: 'In pantry',
            onResultTapped: (_) {},
            onResultLongPressed: (_) {},
            onResultDismissed: onDismissed ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('SearchResultsList', () {
    testWidgets('renders one tile per result', (tester) async {
      await pumpList(tester);
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('shows the product name and brand plus barcode subtitle', (
      tester,
    ) async {
      await pumpList(tester);
      expect(find.text('Local Milk'), findsOneWidget);
      expect(find.text('Brand A \u2014 001'), findsOneWidget);
    });

    testWidgets('falls back to the barcode for products named Unknown', (
      tester,
    ) async {
      const unknown = Product(barcode: '12345', name: 'Unknown', brand: 'X');
      await pumpList(
        tester,
        list: [
          const SearchResult(product: unknown, source: ResultSource.local),
        ],
      );
      expect(find.text('12345'), findsOneWidget);
    });

    testWidgets('shows the in-pantry icon only for pantry members', (
      tester,
    ) async {
      await pumpList(tester);
      expect(find.byIcon(Icons.kitchen), findsOneWidget);
    });

    testWidgets('shows a cloud icon for API results', (tester) async {
      await pumpList(tester);
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });

    testWidgets('shows an eco icon for produce', (tester) async {
      await pumpList(tester);
      expect(find.byIcon(Icons.eco_outlined), findsNWidgets(2));
    });

    testWidgets('tapping a result calls onResultTapped', (tester) async {
      Product? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsList(
              results: results,
              inPantrySwipeLabel: 'Already in pantry',
              addToInventoryLabel: 'Add to inventory',
              inPantryIndicatorLabel: 'In pantry',
              onResultTapped: (p) => tapped = p,
              onResultLongPressed: (_) {},
              onResultDismissed: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Local Milk'));
      expect(tapped?.barcode, '001');
    });

    testWidgets('long-pressing a result calls onResultLongPressed', (
      tester,
    ) async {
      Product? longPressed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsList(
              results: results,
              inPantrySwipeLabel: 'Already in pantry',
              addToInventoryLabel: 'Add to inventory',
              inPantryIndicatorLabel: 'In pantry',
              onResultTapped: (_) {},
              onResultLongPressed: (p) => longPressed = p,
              onResultDismissed: (_) {},
            ),
          ),
        ),
      );
      await tester.longPress(find.text('Local Milk'));
      expect(longPressed?.barcode, '001');
    });

    testWidgets('swiping a result calls onResultDismissed', (tester) async {
      SearchResult? dismissed;
      await pumpList(tester, onDismissed: (r) => dismissed = r);
      await tester.drag(find.text('Local Milk'), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(dismissed?.product.barcode, '001');
    });
  });
}
