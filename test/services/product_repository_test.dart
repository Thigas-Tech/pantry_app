/// Tests for [ProductRepository] – offline‑first product retrieval and
/// inventory delegation.
///
/// Uses mocks for [DatabaseHelper] and [ProductApiService] to simulate
/// cache hits, API successes, and failures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_api_service.dart';
import 'package:pantry_app/services/product_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockProductApiService extends Mock implements ProductApiService {}

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
      /// A cached product is returned immediately without calling the API.
      when(
        () => mockDb.getProduct(testBarcode),
      ).thenAnswer((_) async => testProduct);

      final product = await repository.getProduct(testBarcode);
      expect(product, testProduct);
      verify(() => mockDb.getProduct(testBarcode)).called(1);
      verifyNever(() => mockApi.getByBarcode(any()));
    });

    test('fetches from API and caches when not in DB', () async {
      /// When there is no cache entry the API is called and the result
      /// is saved.
      when(() => mockDb.getProduct(testBarcode)).thenAnswer((_) async => null);
      when(
        () => mockApi.getByBarcode(testBarcode),
      ).thenAnswer((_) async => testProduct);
      when(
        () => mockDb.insertProduct(testProduct),
      ).thenAnswer((_) => Future.value());

      final product = await repository.getProduct(testBarcode);
      expect(product, testProduct);
      verify(() => mockDb.insertProduct(testProduct)).called(1);
    });

    test(
      'throws ProductNotFoundException when API returns not found',
      () {
        /// Without a fallback API a not‑found error is rethrown.
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

    test('throws FetchFailedException on generic API error', () {
      /// Network or other exceptions are wrapped in a
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
      'uses fallback API when primary throws ProductNotFoundException',
      () async {
        /// When the primary API cannot find the product, the fallback
        /// API is tried before giving up.
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => null);
        when(
          () => mockApi.getByBarcode(testBarcode),
        ).thenThrow(ProductNotFoundException('primary not found'));
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
        /// If neither API finds the product, a [ProductNotFoundException]
        /// is thrown.
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => null);
        when(
          () => mockApi.getByBarcode(testBarcode),
        ).thenThrow(ProductNotFoundException('primary not found'));
        when(
          () => fallbackApi.getByBarcode(testBarcode),
        ).thenThrow(ProductNotFoundException('fallback not found'));

        expect(
          () => repository.getProduct(testBarcode),
          throwsA(isA<ProductNotFoundException>()),
        );
      },
    );
  });

  group('inventory methods', () {
    test('getInventoryForBarcode delegates to DB', () async {
      /// The repository simply forwards the call to the database.
      final items = [const InventoryItem(barcode: testBarcode)];
      when(
        () => mockDb.getInventoryItemsByBarcode(testBarcode),
      ).thenAnswer((_) async => items);
      final result = await repository.getInventoryForBarcode(testBarcode);
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
      /// `cacheProduct` saves the product without going through the API.
      when(() => mockDb.insertProduct(testProduct)).thenAnswer((_) async => {});
      await repository.cacheProduct(testProduct);
      verify(() => mockDb.insertProduct(testProduct)).called(1);
    });
  });
}
