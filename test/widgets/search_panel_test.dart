import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/search_filter.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/usda_provider.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:pantry_app/widgets/not_found_flow.dart';
import 'package:pantry_app/widgets/search_panel.dart';
import '../helpers/pump_app.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {
  _MockDatabaseHelper() {
    when(
      () =>
          getBarcodesInInventory(any(), inventoryId: any(named: 'inventoryId')),
    ).thenAnswer((_) async => <String>{});
  }
}

class _MockOffAdapter extends Mock implements OffAdapter {}

class _MockUsdaApiClient extends Mock implements UsdaApiClient {}

void main() {
  late _MockDatabaseHelper mockDb;
  late _MockOffAdapter mockApi;
  late _MockUsdaApiClient mockUsda;

  const localProduct = Product(
    barcode: '001',
    name: 'Local Milk',
    brand: 'Brand A',
  );

  setUpAll(() {
    registerFallbackValue(const InventoryItem(barcode: 'fallback'));
    registerFallbackValue(
      const Product(barcode: 'fallback', name: 'Fallback'),
    );
  });

  setUp(() {
    mockDb = _MockDatabaseHelper();
    mockApi = _MockOffAdapter();
    mockUsda = _MockUsdaApiClient();

    when(() => mockDb.searchProducts(any())).thenAnswer((_) async => []);
    when(
      () => mockApi.searchProducts(
        any(),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => []);
    when(() => mockUsda.searchFood(any())).thenAnswer((_) async => []);
  });

  Future<void> pumpPanel(
    WidgetTester tester, {
    Duration debounceDuration = const Duration(milliseconds: 2000),
    List<Override> extraOverrides = const [],
    void Function(Product)? onProductSelected,
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: SearchPanel(
          searchDebounceDuration: debounceDuration,
          onProductSelected: onProductSelected,
        ),
      ),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        apiServiceProvider.overrideWithValue(mockApi),
        usdaApiClientProvider.overrideWithValue(mockUsda),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        ...extraOverrides,
      ],
      settle: false,
    );
    await tester.pump();
  }

  group('smoke tests', () {
    testWidgets('renders search bar and source dropdown', (tester) async {
      await pumpPanel(tester);

      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.byType(DropdownButton<SearchSource>), findsOneWidget);
    });

    testWidgets('shows search results on query', (tester) async {
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpPanel(tester);

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);
    });
  });

  group('onProductSelected callback', () {
    testWidgets('calls onProductSelected instead of navigating', (
      tester,
    ) async {
      Product? captured;
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpPanel(
        tester,
        onProductSelected: (p) => captured = p,
      );

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      await tester.tap(find.text('Local Milk'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.barcode, '001');
    });
  });

  group('selectMode', () {
    testWidgets('pops with product when result is tapped', (tester) async {
      Product? result;
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Product>(
                context,
                MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: SearchPanel(selectMode: true),
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          apiServiceProvider.overrideWithValue(mockApi),
          usdaApiClientProvider.overrideWithValue(mockUsda),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        ],
        settle: false,
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);

      await tester.tap(find.text('Local Milk'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.barcode, '001');
    });
  });

  group('not found flow integration', () {
    testWidgets('OFF empty results show NotFoundFlow', (tester) async {
      await pumpPanel(tester);

      await tester.enterText(find.byType(SearchBar), 'unknownproduct');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();

      expect(find.byType(NotFoundFlow), findsOneWidget);
      expect(
        find.text('No products found in Packaged Products.'),
        findsOneWidget,
      );
    });

    testWidgets('USDA empty results do NOT show NotFoundFlow', (
      tester,
    ) async {
      await pumpPanel(tester);

      // Switch to USDA source via the dropdown
      await tester.tap(find.byType(DropdownButton<SearchSource>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fresh Produce').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'unknownproduce');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();

      expect(find.byType(NotFoundFlow), findsNothing);
      expect(
        find.text('No products found matching your search'),
        findsOneWidget,
      );
    });
  });

  group('inPantry enrichment', () {
    testWidgets('marks result as inPantry when barcode exists in inventory', (
      tester,
    ) async {
      when(() => mockDb.searchProducts('milk')).thenAnswer(
        (_) async => [localProduct],
      );
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockDb.getBarcodesInInventory(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => {'001'});

      await pumpPanel(tester);

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);
      expect(find.byIcon(Icons.kitchen), findsOneWidget);
    });

    testWidgets('does NOT show pantry icon when barcode not in inventory', (
      tester,
    ) async {
      when(() => mockDb.searchProducts('milk')).thenAnswer(
        (_) async => [localProduct],
      );
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockDb.getBarcodesInInventory(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => <String>{});

      await pumpPanel(tester);

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);
      expect(find.byIcon(Icons.kitchen), findsNothing);
    });
  });

  group('search debounce and Enter key', () {
    testWidgets('triggers search immediately on Enter key press', (
      tester,
    ) async {
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpPanel(tester);

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);
    });

    testWidgets('debounce fires after configured duration', (tester) async {
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpPanel(
        tester,
        debounceDuration: const Duration(milliseconds: 50),
      );

      await tester.enterText(find.byType(SearchBar), 'milk');
      // Not yet past debounce
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('Local Milk'), findsNothing);
      // Just past debounce
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();
      expect(find.text('Local Milk'), findsOneWidget);
    });
  });
}
