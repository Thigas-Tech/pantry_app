/// SearchScreen widget tests.
///
/// Tests for the product search tab: idle state, loading indicator, results
/// from local & API sources, empty state, clear button, and navigation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';

import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart'
    show inventoryWithProductProvider;
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/services/off_adapter.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOffAdapter extends Mock implements OffAdapter {}

/// A helper widget that watches [inventoryWithProductProvider] and counts
/// rebuilds so test assertions can detect when the provider is invalidated.
class _ProviderWatcher extends ConsumerWidget {
  const _ProviderWatcher({
    required this.recomputeCount,
    required this.child,
  });

  final ValueNotifier<int> recomputeCount;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(inventoryWithProductProvider);
    recomputeCount.value++;
    return child;
  }
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockOffAdapter mockApi;

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
  const produceProduct = Product(
    barcode: 'produce-Carrot',
    name: 'Carrot',
    productType: ProductType.produce,
    source: 'manual',
  );

  setUpAll(() {
    registerFallbackValue(const InventoryItem(barcode: 'fallback'));
    registerFallbackValue(const Product(barcode: 'fallback', name: 'Fallback'));
  });

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockOffAdapter();

    when(() => mockDb.searchProducts(any())).thenAnswer((_) async => []);
    when(
      () => mockApi.searchProducts(
        any(),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => []);
  });

  Future<void> pumpSearchScreen(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
    Widget Function(Widget)? wrap,
  }) async {
    await pumpApp(
      tester,
      wrap != null ? wrap(const SearchScreen()) : const SearchScreen(),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        apiServiceProvider.overrideWithValue(mockApi),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        ...extraOverrides,
      ],
      settle: false,
    );
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

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump(const Duration(milliseconds: 550));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('results state', () {
    testWidgets('shows local search results', (tester) async {
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

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);
      expect(find.text('Brand A — 001'), findsOneWidget);
      // Local results have no cloud icon.
      expect(find.byIcon(Icons.cloud_outlined), findsNothing);
    });

    testWidgets('shows API search results with cloud icon', (tester) async {
      when(() => mockDb.searchProducts('bread')).thenAnswer((_) async => []);
      when(
        () => mockApi.searchProducts(
          'bread',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => [apiProduct]);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(SearchBar), 'bread');
      await tester.pump(const Duration(milliseconds: 550));
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
        () => mockApi.searchProducts(
          'dup',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => [
          const Product(barcode: '999', name: 'API Duplicate'),
        ],
      );

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(SearchBar), 'dup');
      await tester.pump(const Duration(milliseconds: 550));
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
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
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

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump(const Duration(milliseconds: 550));
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

      await tester.enterText(find.byType(SearchBar), 'zzzzz');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump(const Duration(milliseconds: 550));
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

      await tester.enterText(find.byType(SearchBar), 'milk');
      // Pump only a short duration (less than debounce).
      await tester.pump(const Duration(milliseconds: 50));

      // Search should not have started — spinner should not appear.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('UI fixes', () {
    testWidgets('SearchBar has TextInputAction.search', (tester) async {
      await pumpSearchScreen(tester);

      final searchBar = tester.widget<SearchBar>(find.byType(SearchBar));
      expect(searchBar.textInputAction, TextInputAction.search);
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

      await tester.enterText(find.byType(SearchBar), 'short');
      await tester.pump(const Duration(milliseconds: 550));
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

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      final dismissible = tester.widget<Dismissible>(
        find.byType(Dismissible).first,
      );
      expect(dismissible.key, isA<ValueKey<String>>());
      expect(
        (dismissible.key! as ValueKey<String>).value,
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
        () => mockApi.searchProducts(
          any(),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      // Start first search (type "old").
      await tester.enterText(find.byType(SearchBar), 'old');
      await tester.pump(const Duration(milliseconds: 550));

      // Before the first search completes, type "new".
      await tester.enterText(find.byType(SearchBar), 'new');
      await tester.pump(const Duration(milliseconds: 550));
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

      await tester.enterText(find.byType(SearchBar), 'a');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      // Local result should appear.
      expect(find.text('Local Milk'), findsOneWidget);
      // API should NOT have been called.
      verifyNever(
        () => api.searchProducts(
          any(),
          pageSize: any(named: 'pageSize'),
        ),
      );
    });
  });

  group('produce icon', () {
    testWidgets('shows leaf avatar for produce item without image', (
      tester,
    ) async {
      when(
        () => mockDb.searchProducts('carrot'),
      ).thenAnswer((_) async => [produceProduct]);
      when(
        () => mockApi.searchProducts(
          'carrot',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(SearchBar), 'carrot');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      expect(find.text('Carrot'), findsOneWidget);
      // Should show leaf icon instead of barcode text "pro".
      // 2 leaf icons: one in avatar, one in trailing position.
      expect(find.byIcon(Icons.eco_outlined), findsNWidgets(2));
    });

    testWidgets('trailing: leaf over cloud for local produce item', (
      tester,
    ) async {
      when(
        () => mockDb.searchProducts('carrot'),
      ).thenAnswer((_) async => [produceProduct]);
      when(
        () => mockApi.searchProducts(
          'carrot',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(SearchBar), 'carrot');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      // Produce items show leaf (avatar + trailing), never cloud.
      expect(find.byIcon(Icons.eco_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.cloud_outlined), findsNothing);
    });

    testWidgets('trailing: leaf over cloud for API produce item', (
      tester,
    ) async {
      when(() => mockDb.searchProducts('carrot')).thenAnswer((_) async => []);
      when(
        () => mockApi.searchProducts(
          'carrot',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => [produceProduct]);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(SearchBar), 'carrot');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      // Produce items override cloud with leaf (avatar + trailing).
      expect(find.byIcon(Icons.eco_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.cloud_outlined), findsNothing);
    });

    testWidgets('non-produce API product still shows cloud icon', (
      tester,
    ) async {
      when(() => mockDb.searchProducts('bread')).thenAnswer((_) async => []);
      when(
        () => mockApi.searchProducts(
          'bread',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => [apiProduct]);

      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(SearchBar), 'bread');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      // Non-produce API items still show cloud.
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      expect(find.byIcon(Icons.eco_outlined), findsNothing);
    });
  });

  group('add to inventory', () {
    testWidgets(
      'swipe-to-add calls repo.cacheProduct and repo.addInventoryItem',
      (
        tester,
      ) async {
        final mockRepo = createMockProductRepository();
        when(() => mockRepo.cacheProduct(any())).thenAnswer((_) async {});
        when(() => mockRepo.addInventoryItem(any())).thenAnswer((_) async => 1);
        when(
          () => mockDb.searchProducts('milk'),
        ).thenAnswer((_) async => [localProduct]);
        when(
          () => mockApi.searchProducts(
            'milk',
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => []);

        await pumpSearchScreen(
          tester,
          extraOverrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        await tester.enterText(find.byType(SearchBar), 'milk');
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump();

        await tester.drag(find.text('Local Milk'), const Offset(500, 0));
        await tester.pump();
        await tester.pumpAndSettle();

        verify(() => mockRepo.cacheProduct(localProduct)).called(1);
        verify(
          () => mockRepo.addInventoryItem(
            any(
              that: isA<InventoryItem>().having(
                (i) => i.barcode,
                'barcode',
                localProduct.barcode,
              ),
            ),
          ),
        ).called(1);
        expect(find.text('Add to Pantry'), findsOneWidget);
      },
    );

    testWidgets('undo after swipe-to-add calls deleteInventoryItem', (
      tester,
    ) async {
      final mockRepo = createMockProductRepository();
      when(() => mockRepo.cacheProduct(any())).thenAnswer((_) async => {});
      when(() => mockRepo.addInventoryItem(any())).thenAnswer((_) async => 1);
      when(
        () => mockRepo.deleteInventoryItem(any()),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpSearchScreen(
        tester,
        extraOverrides: [
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      await tester.drag(find.text('Local Milk'), const Offset(500, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteInventoryItem(1)).called(1);
      expect(find.text('Removed from pantry.'), findsOneWidget);
    });
  });

  group('invalidation on navigation return', () {
    testWidgets(
      're-queries inventoryWithProductProvider after returning from '
      'ProductDetailScreen',
      (tester) async {
        final mockRepo = createMockProductRepository();
        when(
          () => mockRepo.getInventoryForBarcode(
            any(),
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryWithProduct(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer((_) async => []);

        // Stub search to return a result so we can tap one.
        when(
          () => mockDb.searchProducts('milk'),
        ).thenAnswer((_) async => [localProduct]);

        final recomputeCount = ValueNotifier<int>(0);

        await pumpSearchScreen(
          tester,
          extraOverrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
          wrap: (child) => _ProviderWatcher(
            recomputeCount: recomputeCount,
            child: child,
          ),
        );

        // Let the _ProviderWatcher settle.
        await tester.pump();

        clearInteractions(mockDb);

        await tester.enterText(find.byType(SearchBar), 'milk');
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump();

        await tester.tap(find.text('Local Milk'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        expect(find.byType(ProductDetailScreen), findsOneWidget);

        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        verify(
          () => mockDb.getInventoryWithProduct(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).called(1);
      },
    );
  });
}
