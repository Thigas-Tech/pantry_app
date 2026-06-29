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
      when(
        () => mockDb.getProduct(testBarcode),
      ).thenAnswer((_) async => testProduct);

      final product = await repository.getProduct(testBarcode);

      expect(product, testProduct);
      verify(() => mockDb.getProduct(testBarcode)).called(1);
      verifyNever(() => mockApi.getByBarcode(any()));
    });

    test('fetches from API and caches when not in DB', () async {
      when(() => mockDb.getProduct(testBarcode)).thenAnswer((_) async => null);
      when(
        () => mockApi.getByBarcode(testBarcode),
      ).thenAnswer((_) async => testProduct);
      when(
        () => mockDb.insertProduct(testProduct),
      ).thenAnswer((_) async => Future.value());

      final product = await repository.getProduct(testBarcode);

      expect(product, testProduct);
      verify(() => mockDb.insertProduct(testProduct)).called(1);
    });

    test(
      'throws ProductNotFoundException when API returns not found',
      () async {
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
    test('throws FetchFailedException on generic API error', () async {
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
      () async {
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
      when(() => mockDb.insertProduct(testProduct)).thenAnswer((_) async => {});
      await repository.cacheProduct(testProduct);
      verify(() => mockDb.insertProduct(testProduct)).called(1);
    });
  });
}
