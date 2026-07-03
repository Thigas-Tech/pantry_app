// tests tend to get to long
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_api_service.dart';
import 'package:pantry_app/services/product_repository.dart';

/// Mocks for [DatabaseHelper] and [ProductApiService].
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockProductApiService extends Mock implements ProductApiService {}

/// Tests for [ProductRepository] – offline‑first product retrieval,
/// inventory item delegation, and inventory (pantry) management.
void main() {
  late ProductRepository repository;
  late MockDatabaseHelper mockDb;
  late MockProductApiService mockApi;
  late MockProductApiService fallbackApi;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockProductApiService();
    fallbackApi = MockProductApiService();
    repository = ProductRepository(mockDb, mockApi, fallbackApi: fallbackApi);
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
      'throws ProductNotFoundException when API returns not found (no fallback)',
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
}
