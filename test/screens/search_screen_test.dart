/// SearchScreen widget tests.
///
/// Tests for the product search tab: idle state, loading indicator, results
/// from local & API sources, empty state, clear button, and navigation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOpenFoodFactsApi extends Mock implements OpenFoodFactsApi {}

void main() {
  late MockDatabaseHelper mockDb;
  late MockOpenFoodFactsApi mockApi;

  const localProduct = Product(
    barcode: '001',
    name: 'Local Milk',
    brand: 'Brand A',
  );
  const apiProduct = Product(
    barcode: '002',
    name: 'API Bread',
    brand: 'Brand B',
  );

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockOpenFoodFactsApi();

    when(() => mockDb.searchProducts(any())).thenAnswer((_) async => []);
    when(
      () => mockApi.searchProducts(any(), pageSize: any(named: 'pageSize')),
    ).thenAnswer((_) async => []);
  });

  Future<void> pumpSearchScreen(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
  }) async {
    await pumpApp(
      tester,
      const SearchScreen(),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        apiServiceProvider.overrideWithValue(mockApi),
        ...extraOverrides,
      ],
      settle: false,
    );
    // Let the first frame render.
    await tester.pump();
  }

  group('idle state', () {
    testWidgets('shows search icon and hint text when idle', (tester) async {
      await pumpSearchScreen(tester);

      expect(find.byIcon(Icons.search), findsWidgets);
      expect(
        find.text('Search for products by name or barcode'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('loading state', () {
    testWidgets('shows loading spinner while searching', (tester) async {
      // Stub searchProducts to return a future that never completes.
      when(
        () => mockDb.searchProducts(any()),
      ).thenAnswer((_) => Completer<List<Product>>().future);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('results state', () {
    testWidgets('shows local search results', (tester) async {
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts('milk', pageSize: any(named: 'pageSize')),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);
      expect(find.text('Brand A — 001'), findsOneWidget);
      // Local results have no cloud icon.
      expect(find.byIcon(Icons.cloud_outlined), findsNothing);
    });

    testWidgets('shows API search results with cloud icon', (tester) async {
      when(() => mockDb.searchProducts('bread')).thenAnswer((_) async => []);
      when(
        () => mockApi.searchProducts('bread', pageSize: any(named: 'pageSize')),
      ).thenAnswer((_) async => [apiProduct]);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'bread');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('API Bread'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });

    testWidgets('deduplicates results by barcode, local wins', (tester) async {
      // Same barcode — local should appear, API should be skipped.
      const sameProduct = Product(barcode: '999', name: 'Duplicate');
      when(
        () => mockDb.searchProducts('dup'),
      ).thenAnswer((_) async => [sameProduct]);
      when(
        () => mockApi.searchProducts('dup', pageSize: any(named: 'pageSize')),
      ).thenAnswer(
        (_) async => [
          const Product(barcode: '999', name: 'API Duplicate'),
        ],
      );

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'dup');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // Only one result (the local one), showing local name.
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('API Duplicate'), findsNothing);
    });

    testWidgets('navigates to ProductDetailScreen on tap', (tester) async {
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts('milk', pageSize: any(named: 'pageSize')),
      ).thenAnswer((_) async => []);

      final mockRepo = createMockProductRepository();
      when(
        () => mockRepo.getInventoryForBarcode(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(
        tester,
        extraOverrides: [
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      await tester.tap(find.text('Local Milk'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Local Milk'), findsOneWidget);
    });
  });

  group('empty state', () {
    testWidgets('shows search_off icon when no results found', (tester) async {
      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(
        find.text('No products found matching your search'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });

  group('clear', () {
    testWidgets('clear button resets to idle state', (tester) async {
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts('milk', pageSize: any(named: 'pageSize')),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);

      // Tap the clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Should return to idle state
      expect(
        find.text('Search for products by name or barcode'),
        findsOneWidget,
      );
      expect(find.text('Local Milk'), findsNothing);
    });
  });

  group('debounce', () {
    testWidgets('does not search before 300ms debounce', (tester) async {
      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'milk');
      // Pump only a short duration (less than debounce).
      await tester.pump(const Duration(milliseconds: 50));

      // Search should not have started — spinner should not appear.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('UI fixes', () {
    testWidgets('TextField has TextInputAction.search', (tester) async {
      await pumpSearchScreen(tester);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textInputAction, TextInputAction.search);
    });

    testWidgets('short barcode does not crash CircleAvatar', (tester) async {
      const shortBarcodeProduct = Product(barcode: '12', name: 'Short');
      when(
        () => mockDb.searchProducts('short'),
      ).thenAnswer((_) async => [shortBarcodeProduct]);
      when(
        () => mockApi.searchProducts(
          'short',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'short');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // Should render "120" (padded to 3 chars) instead of crashing.
      expect(find.text('Short'), findsOneWidget);
    });

    testWidgets('ListTile has a unique key', (tester) async {
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      final listTile = tester.widget<ListTile>(find.byType(ListTile).first);
      expect(listTile.key, isA<ValueKey<String>>());
      expect(
        (listTile.key! as ValueKey<String>).value,
        'search-result-001',
      );
    });
  });

  group('request ID stale guard', () {
    testWidgets('old search results are ignored when query changes', (
      tester,
    ) async {
      // Set up a Completer so we can control timing.
      final completer = Completer<List<Product>>();
      when(
        () => mockDb.searchProducts('old'),
      ).thenAnswer((_) => completer.future);
      when(
        () => mockDb.searchProducts('new'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(any(), pageSize: any(named: 'pageSize')),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      // Start first search (type "old").
      await tester.enterText(find.byType(TextField), 'old');
      await tester.pump(const Duration(milliseconds: 350));

      // Before the first search completes, type "new".
      await tester.enterText(find.byType(TextField), 'new');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // Now complete the old search — its results should be ignored.
      completer.complete([const Product(barcode: '000', name: 'Old Product')]);
      await tester.pump();

      // Only the new result should appear.
      expect(find.text('Local Milk'), findsOneWidget);
      expect(find.text('Old Product'), findsNothing);
    });
  });

  group('minimum query length', () {
    testWidgets('does not call API for 1-char queries', (tester) async {
      when(
        () => mockDb.searchProducts('a'),
      ).thenAnswer((_) async => [localProduct]);
      final api = mockApi;

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // Local result should appear.
      expect(find.text('Local Milk'), findsOneWidget);
      // API should NOT have been called.
      verifyNever(
        () => api.searchProducts(any(), pageSize: any(named: 'pageSize')),
      );
    });
  });
}
