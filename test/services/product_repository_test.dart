import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOpenFoodFactsApi extends Mock implements OpenFoodFactsApi {}

void main() {
  late ProductRepository repository;
  late MockDatabaseHelper mockDb;
  late MockOpenFoodFactsApi mockApi;
  late MockOpenFoodFactsApi fallbackApi;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockOpenFoodFactsApi();
    fallbackApi = MockOpenFoodFactsApi();
    repository = ProductRepository(mockDb, mockApi, fallbackApi: fallbackApi);
    registerFallbackValue(const Product(barcode: '', name: ''));
  });

  const testBarcode = '123456789';
  final testProduct = Product(
    barcode: testBarcode,
    name: 'Test Product',
    energyKcal: 100,
    lastSynced: DateTime.now().millisecondsSinceEpoch,
  );

  group('getProduct', () {
    test('returns cached product when available', () async {
      /// If the product is in the local cache, the API is never called.
      when(
        () => mockDb.getProduct(testBarcode),
      ).thenAnswer((_) async => testProduct);

      final product = await repository.getProduct(testBarcode);
      expect(product, testProduct);
      verify(() => mockDb.getProduct(testBarcode)).called(1);
      verifyNever(() => mockApi.getByBarcode(any()));
    });

    test('fetches from API and caches when not in DB', () async {
      /// A cache miss triggers an API call, and the result is saved locally.
      when(() => mockDb.getProduct(testBarcode)).thenAnswer((_) async => null);
      when(
        () => mockApi.getByBarcode(testBarcode),
      ).thenAnswer((_) async => testProduct);
      when(() => mockDb.insertProduct(testProduct)).thenAnswer((_) async => {});

      final product = await repository.getProduct(testBarcode);
      expect(product, testProduct);
      verify(() => mockDb.insertProduct(testProduct)).called(1);
    });

    test(
      'throws ProductNotFoundException when API returns not found '
      '(no fallback)',
      () {
        /// Without a fallback API, a not‑found error is rethrown directly.
        final repoNoFallback = ProductRepository(mockDb, mockApi);
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => null);
        when(
          () => mockApi.getByBarcode(testBarcode),
        ).thenThrow(ProductNotFoundException('Not found'));

        expect(
          () => repoNoFallback.getProduct(testBarcode),
          throwsA(isA<ProductNotFoundException>()),
        );
      },
    );

    test(
      'uses fallback API when primary throws ProductNotFoundException',
      () async {
        /// When the primary API fails with a not‑found error, the fallback
        /// is tried and its result is cached.
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => null);
        when(
          () => mockApi.getByBarcode(testBarcode),
        ).thenThrow(ProductNotFoundException('primary'));
        when(
          () => fallbackApi.getByBarcode(testBarcode),
        ).thenAnswer((_) async => testProduct);
        when(
          () => mockDb.insertProduct(testProduct),
        ).thenAnswer((_) async => {});

        final product = await repository.getProduct(testBarcode);
        expect(product, testProduct);
        verify(() => fallbackApi.getByBarcode(testBarcode)).called(1);
        verify(() => mockDb.insertProduct(testProduct)).called(1);
      },
    );

    test(
      'throws ProductNotFoundException when both APIs fail with not found',
      () {
        /// When both primary and fallback return not‑found, the exception
        /// is rethrown.
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => null);
        when(
          () => mockApi.getByBarcode(testBarcode),
        ).thenThrow(ProductNotFoundException('primary'));
        when(
          () => fallbackApi.getByBarcode(testBarcode),
        ).thenThrow(ProductNotFoundException('fallback'));

        expect(
          () => repository.getProduct(testBarcode),
          throwsA(isA<ProductNotFoundException>()),
        );
      },
    );

    test('throws FetchFailedException on generic API error', () {
      /// Non‑not‑found exceptions from the primary API are wrapped in a
      /// [FetchFailedException].
      when(() => mockDb.getProduct(testBarcode)).thenAnswer((_) async => null);
      when(
        () => mockApi.getByBarcode(testBarcode),
      ).thenThrow(Exception('Network error'));

      expect(
        () => repository.getProduct(testBarcode),
        throwsA(isA<FetchFailedException>()),
      );
    });

    test(
      'throws FetchFailedException on fallback API generic error',
      () {
        /// Generic errors from the fallback API are also wrapped.
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => null);
        when(
          () => mockApi.getByBarcode(testBarcode),
        ).thenThrow(ProductNotFoundException('primary'));
        when(
          () => fallbackApi.getByBarcode(testBarcode),
        ).thenThrow(Exception('Fallback error'));

        expect(
          () => repository.getProduct(testBarcode),
          throwsA(isA<FetchFailedException>()),
        );
      },
    );
  });

  group('inventory item delegation', () {
    test('getInventoryForBarcode delegates to DB', () async {
      final items = [const InventoryItem(barcode: testBarcode)];
      when(
        () => mockDb.getInventoryItemsByBarcode(testBarcode, inventoryId: 1),
      ).thenAnswer((_) async => items);
      final result = await repository.getInventoryForBarcode(
        testBarcode,
        inventoryId: 1,
      );
      expect(result, items);
    });

    test('addInventoryItem delegates to DB', () async {
      const item = InventoryItem(barcode: testBarcode);
      when(() => mockDb.insertInventoryItem(item)).thenAnswer((_) async => 1);
      final id = await repository.addInventoryItem(item);
      expect(id, 1);
    });

    test('updateInventoryItem delegates to DB', () async {
      const item = InventoryItem(id: 1, barcode: testBarcode);
      when(() => mockDb.updateInventoryItem(item)).thenAnswer((_) async => 1);
      final rows = await repository.updateInventoryItem(item);
      expect(rows, 1);
    });

    test('deleteInventoryItem delegates to DB', () async {
      when(() => mockDb.deleteInventoryItem(1)).thenAnswer((_) async => 1);
      final rows = await repository.deleteInventoryItem(1);
      expect(rows, 1);
    });

    test('cacheProduct inserts product into DB', () async {
      when(() => mockDb.insertProduct(testProduct)).thenAnswer((_) async => {});
      await repository.cacheProduct(testProduct);
      verify(() => mockDb.insertProduct(testProduct)).called(1);
    });
  });

  group('inventory management', () {
    test('createInventory delegates to DB', () async {
      when(() => mockDb.createInventory('Work')).thenAnswer((_) async => 3);
      final id = await repository.createInventory('Work');
      expect(id, 3);
    });

    test('getInventories delegates to DB', () async {
      final list = <Map<String, dynamic>>[
        {'id': 1, 'name': 'Home'},
        {'id': 2, 'name': 'Work'},
      ];
      when(() => mockDb.getInventories()).thenAnswer((_) async => list);
      final result = await repository.getInventories();
      expect(result, list);
    });

    test('deleteInventory delegates to DB', () async {
      when(() => mockDb.deleteInventory(2)).thenAnswer((_) async => {});
      await repository.deleteInventory(2);
      verify(() => mockDb.deleteInventory(2)).called(1);
    });

    test('renameInventory delegates to DB', () async {
      when(
        () => mockDb.renameInventory(2, 'Office'),
      ).thenAnswer((_) async => {});
      await repository.renameInventory(2, 'Office');
      verify(() => mockDb.renameInventory(2, 'Office')).called(1);
    });

    test('getInventoryWithProduct delegates to DB', () async {
      final rows = <Map<String, dynamic>>[
        {'barcode': '123', 'product_name': 'Milk'},
      ];
      when(
        () => mockDb.getInventoryWithProduct(inventoryId: 1),
      ).thenAnswer((_) async => rows);
      final result = await repository.getInventoryWithProduct(inventoryId: 1);
      expect(result, rows);
    });

    test('getInventoryCount delegates to DB', () async {
      when(
        () => mockDb.getInventoryCount(inventoryId: 1),
      ).thenAnswer((_) async => 5);
      final count = await repository.getInventoryCount(inventoryId: 1);
      expect(count, 5);
    });

    test('getExportData delegates to DB', () async {
      final rows = <Map<String, dynamic>>[
        {'barcode': '123', 'product_name': 'Milk'},
      ];
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => rows);
      final result = await repository.getExportData(inventoryId: 1);
      expect(result, rows);
    });
  });

  group('refreshInventoryProducts', () {
    setUp(() {
      // Static mock values so the lonely InventoryItem gets a non-null id.
      SharedPreferences.setMockInitialValues({});
    });

    test('returns 0 when inventory has no items', () async {
      when(
        () => mockDb.getInventoryItems(inventoryId: 1),
      ).thenAnswer((_) async => []);

      final count = await repository.refreshInventoryProducts(1);
      expect(count, 0);
    });

    test('refreshes successfully and returns correct count', () async {
      const barcode1 = '111';
      const barcode2 = '222';
      const product1 = Product(barcode: barcode1, name: 'P1');
      const product2 = Product(barcode: barcode2, name: 'P2');

      when(
        () => mockDb.getInventoryItems(inventoryId: 1),
      ).thenAnswer(
        (_) async => [
          const InventoryItem(barcode: barcode1),
          const InventoryItem(barcode: barcode2),
        ],
      );
      when(
        () => mockApi.getByBarcode(barcode1),
      ).thenAnswer((_) async => product1);
      when(
        () => mockApi.getByBarcode(barcode2),
      ).thenAnswer((_) async => product2);
      when(() => mockDb.getProduct(barcode1)).thenAnswer((_) async => null);
      when(() => mockDb.getProduct(barcode2)).thenAnswer((_) async => null);
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});

      final count = await repository.refreshInventoryProducts(1);
      expect(count, 2);
    });

    test('retries failed barcodes on second pass', () async {
      const goodBarcode = 'good';
      const badBarcode = 'bad';
      const goodProduct = Product(barcode: goodBarcode, name: 'Good');

      when(
        () => mockDb.getInventoryItems(inventoryId: 1),
      ).thenAnswer(
        (_) async => [
          const InventoryItem(barcode: goodBarcode),
          const InventoryItem(barcode: badBarcode),
        ],
      );
      // First pass: good succeeds, bad throws
      when(
        () => mockApi.getByBarcode(goodBarcode),
      ).thenAnswer((_) async => goodProduct);
      when(() => mockApi.getByBarcode(badBarcode)).thenThrow(Exception('fail'));
      when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});

      final count = await repository.refreshInventoryProducts(1);
      // First pass: 1 success (good). Bad fails on first pass, retry on
      // second pass also fails (the stub still throws).
      expect(count, 1);
    });
  });

  group('refreshInventoryProductsBackground', () {
    test('returns void (does not throw)', () {
      when(
        () => mockDb.getInventoryItems(inventoryId: 1),
      ).thenAnswer((_) async => []);

      // Should not throw — the fire-and-forget wrapper is void.
      repository.refreshInventoryProductsBackground(1);
    });
  });

  group('refresh time tracking', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getLastRefreshTime returns null when never set', () async {
      final time = await repository.getLastRefreshTime();
      expect(time, isNull);
    });

    test('getLastRefreshTime / setLastRefreshTime round-trips', () async {
      await repository.setLastRefreshTime();
      final time = await repository.getLastRefreshTime();
      expect(time, isNotNull);
      // Should be within the last 5 seconds.
      expect(
        DateTime.now().difference(time!).inSeconds,
        lessThan(5),
      );
    });

    test('isCacheOverdue returns true when never refreshed', () async {
      final overdue = await repository.isCacheOverdue();
      expect(overdue, isTrue);
    });

    test('isCacheOverdue returns false when just refreshed', () async {
      await repository.setLastRefreshTime();
      final overdue = await repository.isCacheOverdue();
      expect(overdue, isFalse);
    });
  });
}
