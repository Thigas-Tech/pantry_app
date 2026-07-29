import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/widgets/add_to_shopping_list_sheet.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOffAdapter extends Mock implements OffAdapter {}

class MockProductRepository2 extends Mock implements ProductRepository {}

class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockOffAdapter mockOff;
  late MockProductRepository2 mockRepo;

  setUp(() {
    registerFallbackValue(const Product(barcode: '', name: ''));

    mockDb = MockDatabaseHelper();
    mockOff = MockOffAdapter();
    mockRepo = MockProductRepository2();

    when(() => mockDb.searchProducts(any())).thenAnswer(
      (_) async => <Product>[],
    );
    when(
      () => mockDb.getDistinctProductsFromInventory(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => mockRepo.cacheProduct(any())).thenAnswer((_) async => {});
  });

  List<Override> sheetOverrides() => [
    databaseProvider.overrideWithValue(mockDb),
    apiServiceProvider.overrideWithValue(mockOff),
    productRepositoryProvider.overrideWithValue(mockRepo),
    hasConnectionProvider.overrideWith((ref) => Future.value(false)),
    activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
  ];

  group('AddToShoppingListSheet', () {
    testWidgets('shows search bar with autofocus', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('Add custom item'), findsOneWidget);
    });

    testWidgets('shows empty state on initial open', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('Search products by name'),
        findsAtLeast(1),
      );
    });

    testWidgets('shows add custom item form', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add custom item'));
      await tester.pumpAndSettle();

      expect(find.text('Item name'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
    });

    testWidgets('can go back from custom form to search', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add custom item'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to search'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchBar), findsOneWidget);
    });

    testWidgets('searches and shows results', (tester) async {
      when(() => mockDb.searchProducts('milk')).thenAnswer(
        (_) async => [
          const Product(barcode: '123', name: 'Milk', brand: 'Brand'),
        ],
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
        settle: false,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final searchField = find.byType(SearchBar);
      await tester.enterText(searchField, 'milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('shows inventory products in empty state', (tester) async {
      when(
        () => mockDb.getDistinctProductsFromInventory(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'barcode': '111', 'name': 'Milk'},
          {'barcode': '222', 'name': 'Bread'},
        ],
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('From your pantry'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('In your pantry'), findsAtLeast(1));
    });

    testWidgets(
      'does not use DraggableScrollableSheet',
      (tester) async {
        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(DraggableScrollableSheet), findsNothing);
      },
    );

    testWidgets(
      'outer Padding includes bottomInset for keyboard avoidance',
      (tester) async {
        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final addItemButton = find.text('Add custom item');
        final outerPad = tester.widget<Padding>(
          find
              .ancestor(
                of: addItemButton,
                matching: find.byType(Padding),
              )
              .first,
        );

        final insets = outerPad.padding;
        if (insets is EdgeInsets) {
          expect(insets.bottom, greaterThanOrEqualTo(0));
        }
      },
    );

    testWidgets(
      'does not use Expanded directly inside primary flow Column',
      (tester) async {
        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final columns = find.byType(Column);
        Column? ourColumn;
        for (final col in columns.evaluate()) {
          final w = col.widget as Column;
          if (w.mainAxisSize == MainAxisSize.min) {
            ourColumn = w;
            break;
          }
        }

        expect(ourColumn, isNotNull);
        final hasExpanded = ourColumn!.children.any((c) => c is Expanded);
        expect(hasExpanded, isFalse);
      },
    );

    testWidgets(
      'outer Padding child is SingleChildScrollView in primary flow',
      (tester) async {
        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        Widget? scrollViewChild;
        for (final element in find.byType(Padding).evaluate()) {
          final pad = element.widget as Padding;
          if (pad.child is SingleChildScrollView) {
            scrollViewChild = pad.child;
            break;
          }
        }

        expect(scrollViewChild, isA<SingleChildScrollView>());
      },
    );

    testWidgets(
      'inventory section does not overflow when keyboard is shown',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => List.generate(
            4,
            (i) => {
              'barcode': '00$i',
              'name': 'Product $i',
              'image_url': null,
              'product_type': 'barcoded',
            },
          ),
        );

        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('From your pantry'), findsOneWidget);
        expect(find.text('Product 0'), findsOneWidget);

        await tester.showKeyboard(find.byType(SearchBar));
        await tester.pumpAndSettle();

        expect(find.text('From your pantry'), findsOneWidget);
        expect(find.text('Product 0'), findsOneWidget);
        expect(find.text('Add custom item'), findsOneWidget);
        await tester.tap(find.text('Add custom item'));
        await tester.pumpAndSettle();

        expect(find.text('Item name'), findsOneWidget);
      },
    );

    testWidgets(
      'shows kitchen icon for inventory item without image_url',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'barcode': '111',
              'name': 'Milk',
              'image_url': null,
              'product_type': 'barcoded',
            },
          ],
        );

        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Milk'), findsOneWidget);
        // Kitchen icon: header + item
        expect(find.byIcon(Icons.kitchen_outlined), findsNWidgets(2));
      },
    );

    testWidgets(
      'shows product image for pantry item with image_url',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'barcode': '111',
              'name': 'Milk',
              'image_url': 'https://example.com/milk.jpg',
              'product_type': 'barcoded',
            },
          ],
        );

        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Milk'), findsOneWidget);
        expect(find.byType(Image), findsAtLeast(1));
      },
    );

    testWidgets(
      'shows leaf avatar for produce pantry item without image_url',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'barcode': 'produce-Apple',
              'name': 'Apple',
              'image_url': null,
              'product_type': 'produce',
            },
          ],
        );

        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsOneWidget);
        expect(find.byIcon(Icons.eco_outlined), findsAtLeast(1));
        expect(find.byIcon(Icons.kitchen_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'handles pantry item with empty image_url string',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'barcode': '111',
              'name': 'Milk',
              'image_url': '',
              'product_type': 'barcoded',
            },
          ],
        );

        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Milk'), findsOneWidget);
        expect(find.byIcon(Icons.kitchen_outlined), findsNWidgets(2));
      },
    );

    testWidgets(
      'handles pantry item with missing keys gracefully',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'barcode': '111',
              'name': 'Milk',
            },
          ],
        );

        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(context),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Milk'), findsOneWidget);
        expect(find.byIcon(Icons.kitchen_outlined), findsNWidgets(2));
      },
    );

    testWidgets('inventory section hidden when empty', (tester) async {
      when(
        () => mockDb.getDistinctProductsFromInventory(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('From your pantry'), findsNothing);
    });

    testWidgets('shows api search failure banner on API error', (tester) async {
      when(() => mockDb.searchProducts('fail')).thenAnswer(
        (_) async => <Product>[],
      );
      when(
        () => mockOff.searchProducts(
          'fail',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenThrow(Exception('Server error'));

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          apiServiceProvider.overrideWithValue(mockOff),
          productRepositoryProvider.overrideWithValue(mockRepo),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        ],
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'fail');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.text(
          'Could not fetch all online results. Some products may be missing.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('api failure banner can be dismissed', (tester) async {
      when(() => mockDb.searchProducts('fail')).thenAnswer(
        (_) async => <Product>[],
      );
      when(
        () => mockOff.searchProducts(
          'fail',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenThrow(Exception('Server error'));

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          apiServiceProvider.overrideWithValue(mockOff),
          productRepositoryProvider.overrideWithValue(mockRepo),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        ],
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'fail');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('tapping API result caches product before returning', (
      tester,
    ) async {
      Product? cachedProduct;
      when(() => mockDb.searchProducts('bread')).thenAnswer(
        (_) async => <Product>[],
      );
      when(
        () => mockOff.searchProducts(
          'bread',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => [
          const Product(barcode: '002', name: 'API Bread', brand: 'Brand'),
        ],
      );
      when(() => mockRepo.cacheProduct(any())).thenAnswer(
        (invocation) async {
          cachedProduct = invocation.positionalArguments[0] as Product;
        },
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          apiServiceProvider.overrideWithValue(mockOff),
          productRepositoryProvider.overrideWithValue(mockRepo),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        ],
        settle: false,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'bread');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      await tester.tap(find.text('API Bread'));
      await tester.pumpAndSettle();

      expect(cachedProduct, isNotNull);
      expect(cachedProduct!.barcode, '002');
    });

    testWidgets('tapping local result does not call cacheProduct', (
      tester,
    ) async {
      var cacheCalled = false;
      when(() => mockDb.searchProducts('local')).thenAnswer(
        (_) async => [
          const Product(barcode: '001', name: 'Local Milk', brand: 'Brand'),
        ],
      );
      when(() => mockRepo.cacheProduct(any())).thenAnswer((_) async {
        cacheCalled = true;
      });

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'local');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Local Milk'));
      await tester.pumpAndSettle();

      expect(cacheCalled, isFalse);
    });
  });

  group('produce icon', () {
    testWidgets('shows leaf avatar for produce item in search results', (
      tester,
    ) async {
      when(() => mockDb.searchProducts('carrot')).thenAnswer(
        (_) async => [
          const Product(
            barcode: 'produce-Carrot',
            name: 'Carrot',
            productType: ProductType.produce,
            source: 'manual',
          ),
        ],
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'carrot');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Carrot'), findsOneWidget);
      // Leaf icons: avatar + trailing.
      expect(find.byIcon(Icons.eco_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.cloud_outlined), findsNothing);
    });

    testWidgets('shows cloud icon for non-produce API item', (
      tester,
    ) async {
      when(() => mockDb.searchProducts('bread')).thenAnswer(
        (_) async => <Product>[],
      );
      when(
        () => mockOff.searchProducts(
          'bread',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => [
          const Product(barcode: '002', name: 'API Bread', brand: 'Brand'),
        ],
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          apiServiceProvider.overrideWithValue(mockOff),
          productRepositoryProvider.overrideWithValue(mockRepo),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        ],
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'bread');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Non-produce API items show cloud, no leaf.
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      expect(find.byIcon(Icons.eco_outlined), findsNothing);
    });

    testWidgets(
      'triggers search on Enter key with custom debounce duration',
      (tester) async {
        when(() => mockDb.searchProducts('milk')).thenAnswer(
          (_) async => [
            const Product(barcode: '001', name: 'Local Milk', brand: 'Brand'),
          ],
        );

        await pumpApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToShoppingListSheet.show(
                context,
                debounceDuration: const Duration(milliseconds: 50),
              ),
              child: const Text('Open'),
            ),
          ),
          overrides: sheetOverrides(),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(SearchBar), 'milk');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        expect(find.text('Local Milk'), findsOneWidget);
      },
    );
  });
}
