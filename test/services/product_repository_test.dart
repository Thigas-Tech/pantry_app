import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOffAdapter extends Mock implements OffAdapter {}

class MockUsdaApiClient extends Mock implements UsdaApiClient {}

class MockFirebaseCacheService extends Mock implements FirebaseCacheService {}

class MockFirebaseCacheMetaDao extends Mock implements FirebaseCacheMetaDao {}

class FakeDatabase extends Fake implements Database {}

void main() {
  late ProductRepository repository;
  late MockDatabaseHelper mockDb;
  late MockOffAdapter mockApi;
  late MockOffAdapter fallbackApi;
  late MockUsdaApiClient mockUsda;
  late MockFirebaseCacheService mockFirebaseCache;
  late MockFirebaseCacheMetaDao mockMetaDao;
  late ProductRepository fbRepo;

  setUpAll(() {
    registerFallbackValue(FakeDatabase());
    registerFallbackValue(const Product(barcode: '', name: ''));
  });

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockOffAdapter();
    fallbackApi = MockOffAdapter();
    mockUsda = MockUsdaApiClient();
    when(() => mockUsda.enrichProductWithServingData(any())).thenAnswer(
      (_) async => null,
    );
    mockFirebaseCache = MockFirebaseCacheService();
    mockMetaDao = MockFirebaseCacheMetaDao();
    when(() => mockDb.database).thenAnswer((_) async => FakeDatabase());
    when(() => mockFirebaseCache.isAvailable).thenReturn(true);
    repository = ProductRepository(
      mockDb,
      mockApi,
      fallbackApi: fallbackApi,
      usdaClient: mockUsda,
      metaDao: mockMetaDao,
    );
    fbRepo = ProductRepository(
      mockDb,
      mockApi,
      fallbackApi: fallbackApi,
      usdaClient: mockUsda,
      firebaseCache: mockFirebaseCache,
      metaDao: mockMetaDao,
    );
    registerFallbackValue(const Product(barcode: '', name: ''));
    registerFallbackValue(const InventoryItem(barcode: ''));
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
        final repoNoFallback = ProductRepository(
          mockDb,
          mockApi,
          metaDao: mockMetaDao,
        );
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

  group('refreshProductLanguage', () {
    const frProduct = Product(
      barcode: testBarcode,
      name: 'Produit Français',
      languageCode: 'fr',
    );

    setUp(() {
      when(
        () => mockDb.getProduct(testBarcode),
      ).thenAnswer((_) async => testProduct);
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockApi.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => frProduct);
    });

    test('fetches from the API even when cached, with the requested '
        'language', () async {
      final result = await repository.refreshProductLanguage(
        testBarcode,
        languageCode: 'fr',
      );

      expect(result.languageCode, 'fr');
      verify(
        () => mockApi.getByBarcode(
          testBarcode,
          languageCode: 'fr',
        ),
      ).called(1);
    });

    test('caches the refreshed product', () async {
      await repository.refreshProductLanguage(
        testBarcode,
        languageCode: 'fr',
      );

      verify(() => mockDb.insertProduct(any())).called(1);
    });

    test('merges from API for api-source products (updates name and '
        'languageCode)', () async {
      when(
        () => mockDb.getProduct(testBarcode),
      ).thenAnswer((_) async => testProduct);

      final result = await repository.refreshProductLanguage(
        testBarcode,
        languageCode: 'fr',
      );

      expect(result.name, 'Produit Français');
      expect(result.languageCode, 'fr');
    });

    test('only updates languageCode for manual-source products', () async {
      const manualProduct = Product(
        barcode: testBarcode,
        name: 'My Manual Entry',
        ingredients: 'user entered',
        source: 'manual',
      );
      when(
        () => mockDb.getProduct(testBarcode),
      ).thenAnswer((_) async => manualProduct);

      final result = await repository.refreshProductLanguage(
        testBarcode,
        languageCode: 'fr',
      );

      expect(result.languageCode, 'fr');
      expect(result.name, 'My Manual Entry');
      expect(result.ingredients, 'user entered');
    });

    test('throws FetchFailedException when the API call fails', () {
      when(
        () => mockApi.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenThrow(Exception('network down'));

      expect(
        () => repository.refreshProductLanguage(
          testBarcode,
          languageCode: 'fr',
        ),
        throwsA(isA<FetchFailedException>()),
      );
    });
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

    test(
      'cacheProduct inserts product into DB when no existing record',
      () async {
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => null);
        when(
          () => mockDb.insertProduct(testProduct),
        ).thenAnswer((_) async => {});
        await repository.cacheProduct(testProduct);
        verify(() => mockDb.getProduct(testBarcode)).called(1);
        verify(() => mockDb.insertProduct(testProduct)).called(1);
      },
    );

    test(
      'cacheProduct merges manual entry over existing API product',
      () async {
        final existingApi = testProduct.copyWith(
          source: 'api',
          nutriscoreGrade: 'a',
          energyKcal: 200,
        );
        final manualEntry = testProduct.copyWith(
          name: 'User Entered Name',
          source: 'manual',
          energyKcal: null, // user left empty
        );
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => existingApi);
        when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});

        await repository.cacheProduct(manualEntry);

        final captured =
            verify(
                  () => mockDb.insertProduct(captureAny()),
                ).captured.single
                as Product;
        // Manual name wins
        expect(captured.name, 'User Entered Name');
        // API Nutri-Score preserved
        expect(captured.nutriscoreGrade, 'a');
        // API nutrition preserved when user left empty
        expect(captured.energyKcal, 200);
        // Source is manual
        expect(captured.source, 'manual');
      },
    );

    test('cacheProduct uses mergeFromApi for API entries', () async {
      final existingManual = testProduct.copyWith(
        source: 'manual',
        nutritionImagePath: '/path/to/photo.jpg',
      );
      final apiEntry = testProduct.copyWith(
        source: 'api',
        nutriscoreGrade: 'b',
      );
      when(
        () => mockDb.getProduct(testBarcode),
      ).thenAnswer((_) async => existingManual);
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});

      await repository.cacheProduct(apiEntry);

      final captured =
          verify(
                () => mockDb.insertProduct(captureAny()),
              ).captured.single
              as Product;
      // Local photo path preserved
      expect(captured.nutriscoreGrade, 'b');
      expect(captured.nutritionImagePath, '/path/to/photo.jpg');
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
  });

  group('refreshInventoryProducts', () {
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

    test('skips synthetic produce barcodes during refresh', () async {
      const realBarcode = '0737628064502';
      const produceBarcode = 'produce-Banana';
      const pluBarcode = 'plu-12345';
      const realProduct = Product(
        barcode: realBarcode,
        name: 'Real Product',
      );

      when(
        () => mockDb.getInventoryItems(inventoryId: 1),
      ).thenAnswer(
        (_) async => [
          const InventoryItem(barcode: realBarcode),
          const InventoryItem(barcode: produceBarcode),
          const InventoryItem(barcode: pluBarcode),
        ],
      );
      when(
        () => mockApi.getByBarcode(realBarcode),
      ).thenAnswer((_) async => realProduct);
      when(() => mockDb.getProduct(realBarcode)).thenAnswer((_) async => null);
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});

      final count = await repository.refreshInventoryProducts(1);

      // Only the real barcode should be refreshed
      expect(count, 1);
      verify(() => mockApi.getByBarcode(realBarcode)).called(1);
      // Synthetic barcodes must never reach the OFF API
      verifyNever(() => mockApi.getByBarcode(produceBarcode));
      verifyNever(() => mockApi.getByBarcode(pluBarcode));
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
    test('getLastRefreshTime returns null when never set', () async {
      when(() => mockMetaDao.getGlobalRefreshTime(any())).thenAnswer(
        (_) async => null,
      );

      final time = await repository.getLastRefreshTime();
      expect(time, isNull);
    });

    test('getLastRefreshTime returns DateTime when set', () async {
      final now = DateTime.now();
      when(() => mockMetaDao.getGlobalRefreshTime(any())).thenAnswer(
        (_) async => <String, dynamic>{
          'cache_key': '__global_refresh__',
          'cache_type': 'global_refresh',
          'last_refreshed_at': now.millisecondsSinceEpoch,
          'next_refresh_at':
              now.millisecondsSinceEpoch + 5 * 24 * 60 * 60 * 1000,
        },
      );

      final time = await repository.getLastRefreshTime();
      expect(time, isNotNull);
      expect(
        now.difference(time!).inSeconds,
        lessThan(5),
      );
    });

    test('isCacheOverdue returns true when never refreshed', () async {
      when(() => mockMetaDao.getGlobalRefreshTime(any())).thenAnswer(
        (_) async => null,
      );

      final overdue = await repository.isCacheOverdue();
      expect(overdue, isTrue);
    });

    test('isCacheOverdue returns true when past overdue days', () async {
      final staleTime = DateTime.now().subtract(const Duration(days: 6));
      when(() => mockMetaDao.getGlobalRefreshTime(any())).thenAnswer(
        (_) async => <String, dynamic>{
          'cache_key': '__global_refresh__',
          'cache_type': 'global_refresh',
          'last_refreshed_at': staleTime.millisecondsSinceEpoch,
          'next_refresh_at':
              staleTime.millisecondsSinceEpoch + 5 * 24 * 60 * 60 * 1000,
        },
      );

      final overdue = await repository.isCacheOverdue();
      expect(overdue, isTrue);
    });

    test('isCacheOverdue returns false when just refreshed', () async {
      final now = DateTime.now();
      when(() => mockMetaDao.getGlobalRefreshTime(any())).thenAnswer(
        (_) async => <String, dynamic>{
          'cache_key': '__global_refresh__',
          'cache_type': 'global_refresh',
          'last_refreshed_at': now.millisecondsSinceEpoch,
          'next_refresh_at':
              now.millisecondsSinceEpoch + 5 * 24 * 60 * 60 * 1000,
        },
      );

      final overdue = await repository.isCacheOverdue();
      expect(overdue, isFalse);
    });
  });

  group('resolveProduceProduct', () {
    const produceName = 'Apple';
    const produceBarcode = 'produce-apple';

    test('returns product with synthetic barcode and produce type', () async {
      when(() => mockDb.getProduct(produceBarcode)).thenAnswer(
        (_) async => null,
      );
      when(() => mockUsda.searchFood(produceName)).thenAnswer(
        (_) async => [],
      );

      final product = await repository.resolveProduceProduct(produceName);

      expect(product.barcode, produceBarcode);
      expect(product.productType, ProductType.produce);
      expect(product.name, produceName);
      expect(product.category, 'Fruit');
    });

    test(
      'returns product with fallback nutrition data when USDA empty',
      () async {
        when(() => mockDb.getProduct(produceBarcode)).thenAnswer(
          (_) async => null,
        );
        when(() => mockUsda.searchFood(produceName)).thenAnswer(
          (_) async => [],
        );

        final product = await repository.resolveProduceProduct(produceName);

        // Apple's fallback nutrition: ~52 kcal per 100g
        expect(product.energyKcal, closeTo(52, 1));
        expect(product.category, 'Fruit');
      },
    );

    test('returns "Vegetables" category for Broccoli', () async {
      when(() => mockDb.getProduct('produce-broccoli')).thenAnswer(
        (_) async => null,
      );
      when(() => mockUsda.searchFood('Broccoli')).thenAnswer(
        (_) async => [],
      );

      final product = await repository.resolveProduceProduct('Broccoli');

      expect(product.category, 'Vegetables');
    });

    test('throws ArgumentError for empty produce name', () {
      expect(
        () => repository.resolveProduceProduct(''),
        throwsArgumentError,
      );
    });

    test('does not write to database', () async {
      when(() => mockDb.getProduct(produceBarcode)).thenAnswer(
        (_) async => null,
      );
      when(() => mockUsda.searchFood(produceName)).thenAnswer(
        (_) async => [],
      );

      await repository.resolveProduceProduct(produceName);

      verifyNever(() => mockDb.insertProduct(any()));
      verifyNever(() => mockDb.insertInventoryItem(any()));
      verifyNever(() => mockDb.insertOrMergeInventoryItem(any()));
    });

    test('throws ArgumentError for whitespace-only name', () {
      expect(
        () => repository.resolveProduceProduct('  '),
        throwsArgumentError,
      );
    });

    test('enriches product with USDA data when available', () async {
      when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
      final usdaProduct = Product(
        barcode: '',
        name: 'Apple',
        energyKcal: 52,
        proteinG: 0.3,
        carbsG: 13.8,
        fatG: 0.2,
        fiberG: 2.4,
        source: 'manual',
        productType: ProductType.produce,
        lastSynced: DateTime.now().millisecondsSinceEpoch,
      );
      when(() => mockUsda.searchFood('Apple')).thenAnswer(
        (_) async => [usdaProduct],
      );

      final product = await repository.resolveProduceProduct('Apple');

      expect(product.barcode, 'produce-apple');
      expect(product.name, 'Apple');
      expect(product.energyKcal, 52);
      expect(product.productType, ProductType.produce);
      expect(product.source, 'manual');
      expect(product.category, 'Fruit');
    });

    test(
      'falls back to hardcoded nutrition when USDA throws',
      () async {
        when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
        when(() => mockUsda.searchFood('Apple')).thenThrow(
          Exception('USDA API unavailable'),
        );

        final product = await repository.resolveProduceProduct('Apple');

        expect(product.barcode, 'produce-apple');
        expect(product.energyKcal, closeTo(52, 1));
        expect(product.category, 'Fruit');
      },
    );

    test(
      'returns minimal product with null nutrition for unknown produce',
      () async {
        when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
        when(() => mockUsda.searchFood('Tofu')).thenAnswer(
          (_) async => [],
        );

        final product = await repository.resolveProduceProduct('Tofu');

        expect(product.barcode, 'produce-tofu');
        expect(product.name, 'Tofu');
        expect(product.energyKcal, isNull);
        expect(product.proteinG, isNull);
        expect(product.carbsG, isNull);
        expect(product.fatG, isNull);
        expect(product.fiberG, isNull);
        expect(product.category, 'Fruits and vegetables based foods');
      },
    );

    test('sets lastSynced to near-current time', () async {
      when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
      when(() => mockUsda.searchFood('Apple')).thenAnswer(
        (_) async => [],
      );
      final before = DateTime.now().millisecondsSinceEpoch;

      final product = await repository.resolveProduceProduct('Apple');

      expect(product.lastSynced, greaterThanOrEqualTo(before));
      expect(
        product.lastSynced,
        lessThanOrEqualTo(
          DateTime.now().millisecondsSinceEpoch + 5000,
        ),
      );
    });

    test('uses underscore in barcode for multi-word names', () async {
      when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
      when(() => mockUsda.searchFood('Sweet Potato')).thenAnswer(
        (_) async => [],
      );

      final product = await repository.resolveProduceProduct('Sweet Potato');

      expect(product.barcode, 'produce-sweet_potato');
      expect(product.category, 'Vegetables');
    });

    test(
      'resolves produce with no Firebase or USDA available',
      () async {
        final minimalRepo = ProductRepository(
          mockDb,
          mockApi,
          metaDao: mockMetaDao,
        );
        when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);

        final product = await minimalRepo.resolveProduceProduct('Apple');

        expect(product.barcode, 'produce-apple');
        expect(product.energyKcal, closeTo(52, 1));
        expect(product.productType, ProductType.produce);
      },
    );
  });

  group('addProduceToInventory', () {
    const produceBarcode = 'produce-apple';
    const produceName = 'Apple';

    setUp(() {
      when(() => mockDb.insertOrMergeInventoryItem(any())).thenAnswer(
        (_) async => 42,
      );
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});
    });

    test('uses existing product row when present', () async {
      when(
        () => mockDb.getProduct(produceBarcode),
      ).thenAnswer(
        (_) async => const Product(barcode: produceBarcode, name: produceName),
      );

      final id = await repository.addProduceToInventory(
        produceName,
        inventoryId: 1,
      );

      expect(id, 42);
      verify(() => mockDb.getProduct(produceBarcode)).called(1);
      verifyNever(() => mockUsda.searchFood(any()));
      verify(() => mockDb.insertOrMergeInventoryItem(any())).called(1);
    });

    test('uses USDA data when product not in DB and USDA succeeds', () async {
      when(() => mockDb.getProduct(produceBarcode)).thenAnswer(
        (_) async => null,
      );
      when(() => mockUsda.searchFood(produceName)).thenAnswer(
        (_) async => [
          const Product(
            barcode: 'plu-1234',
            name: 'Apple, raw',
            energyKcal: 52,
            productType: ProductType.produce,
          ),
        ],
      );

      final id = await repository.addProduceToInventory(
        produceName,
        inventoryId: 2,
      );

      expect(id, 42);
      verify(() => mockUsda.searchFood(produceName)).called(1);
      verify(() => mockDb.insertProduct(captureAny()));
      verify(() => mockDb.insertOrMergeInventoryItem(any())).called(1);
    });

    test(
      'falls back to ProduceNutritionFallback when USDA returns empty',
      () async {
        when(() => mockDb.getProduct(produceBarcode)).thenAnswer(
          (_) async => null,
        );
        when(() => mockUsda.searchFood(produceName)).thenAnswer(
          (_) async => [],
        );

        final id = await repository.addProduceToInventory(
          produceName,
          inventoryId: 1,
        );

        expect(id, 42);
        final captured =
            verify(
                  () => mockDb.insertProduct(captureAny()),
                ).captured.first
                as Product;
        expect(captured.barcode, produceBarcode);
        expect(captured.energyKcal, closeTo(52, 1));
        verify(() => mockDb.insertOrMergeInventoryItem(any())).called(1);
      },
    );

    test('falls back when USDA throws exception', () async {
      when(() => mockDb.getProduct(produceBarcode)).thenAnswer(
        (_) async => null,
      );
      when(() => mockUsda.searchFood(produceName)).thenThrow(
        Exception('Network error'),
      );

      final id = await repository.addProduceToInventory(
        produceName,
        inventoryId: 1,
      );

      expect(id, 42);
      final captured =
          verify(
                () => mockDb.insertProduct(captureAny()),
              ).captured.first
              as Product;
      expect(captured.energyKcal, closeTo(52, 1));
      verify(() => mockDb.insertOrMergeInventoryItem(any())).called(1);
    });

    test(
      'creates minimal product when USDA empty and no fallback data',
      () async {
        when(() => mockDb.getProduct('produce-unknownfruit')).thenAnswer(
          (_) async => null,
        );
        when(() => mockUsda.searchFood('UnknownFruit')).thenAnswer(
          (_) async => [],
        );

        final id = await repository.addProduceToInventory(
          'UnknownFruit',
          inventoryId: 1,
        );

        expect(id, 42);
        final captured =
            verify(
                  () => mockDb.insertProduct(captureAny()),
                ).captured.first
                as Product;
        expect(captured.barcode, 'produce-unknownfruit');
        expect(captured.energyKcal, isNull);
        expect(captured.productType, ProductType.produce);
        verify(() => mockDb.insertOrMergeInventoryItem(any())).called(1);
      },
    );

    test('throws ArgumentError for empty produce name', () {
      expect(
        () => repository.addProduceToInventory('', inventoryId: 1),
        throwsArgumentError,
      );
    });

    test('passes custom quantity to insertOrMergeInventoryItem', () async {
      when(() => mockDb.getProduct(produceBarcode)).thenAnswer(
        (_) async => const Product(barcode: produceBarcode, name: produceName),
      );

      await repository.addProduceToInventory(
        produceName,
        inventoryId: 1,
        quantity: 300,
      );

      // Verify quantity 300 was passed in the inventory item
      verify(
        () => mockDb.insertOrMergeInventoryItem(
          any(
            that: isA<InventoryItem>().having(
              (i) => i.quantity,
              'quantity',
              300,
            ),
          ),
        ),
      ).called(1);
    });

    test('uses insertOrMergeInventoryItem (not addInventoryItem)', () async {
      when(() => mockDb.getProduct(produceBarcode)).thenAnswer(
        (_) async => const Product(barcode: produceBarcode, name: produceName),
      );

      await repository.addProduceToInventory(produceName, inventoryId: 1);

      verify(() => mockDb.insertOrMergeInventoryItem(any())).called(1);
      verifyNever(() => mockDb.insertInventoryItem(any()));
    });
  });

  group('Firebase cache integration', () {
    group('getProduct', () {
      test(
        'calls Firebase cache after local miss and returns Firebase product',
        () async {
          when(
            () => mockDb.getProduct(testBarcode),
          ).thenAnswer((_) async => null);
          when(
            () => mockFirebaseCache.resolveBarcodedProduct(
              testBarcode,
              languageCode: any(named: 'languageCode'),
            ),
          ).thenAnswer((_) async => testProduct);

          final product = await fbRepo.getProduct(testBarcode);

          expect(product, testProduct);
          verify(
            () => mockFirebaseCache.resolveBarcodedProduct(
              testBarcode,
              languageCode: any(named: 'languageCode'),
            ),
          ).called(1);
          verifyNever(() => mockApi.getByBarcode(any()));
        },
      );

      test('does NOT call Firebase when product is in local cache', () async {
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => testProduct);

        final product = await fbRepo.getProduct(testBarcode);

        expect(product, testProduct);
        verifyNever(
          () => mockFirebaseCache.resolveBarcodedProduct(
            any(),
            languageCode: any(named: 'languageCode'),
          ),
        );
        verifyNever(() => mockApi.getByBarcode(any()));
      });

      test(
        'skips direct OFF API when Firebase returns null '
        '(service already tried OFF)',
        () async {
          when(
            () => mockDb.getProduct(testBarcode),
          ).thenAnswer((_) async => null);
          when(
            () => mockFirebaseCache.resolveBarcodedProduct(
              testBarcode,
              languageCode: any(named: 'languageCode'),
            ),
          ).thenAnswer((_) async => null);
          when(
            () => fallbackApi.getByBarcode(
              testBarcode,
              languageCode: any(named: 'languageCode'),
            ),
          ).thenThrow(ProductNotFoundException(testBarcode));

          await expectLater(
            () => fbRepo.getProduct(testBarcode),
            throwsA(isA<ProductNotFoundException>()),
          );

          verify(
            () => mockFirebaseCache.resolveBarcodedProduct(
              testBarcode,
              languageCode: any(named: 'languageCode'),
            ),
          ).called(1);
          verifyNever(() => mockApi.getByBarcode(any()));
        },
      );

      test(
        'falls through to OFF API when Firebase throws',
        () async {
          when(
            () => mockDb.getProduct(testBarcode),
          ).thenAnswer((_) async => null);
          when(
            () => mockFirebaseCache.resolveBarcodedProduct(
              testBarcode,
              languageCode: any(named: 'languageCode'),
            ),
          ).thenThrow(Exception('Firestore down'));
          when(
            () => mockApi.getByBarcode(testBarcode),
          ).thenAnswer((_) async => testProduct);
          when(
            () => mockDb.insertProduct(testProduct),
          ).thenAnswer((_) async => {});

          final product = await fbRepo.getProduct(testBarcode);

          expect(product, testProduct);
          verify(() => mockApi.getByBarcode(testBarcode)).called(1);
        },
      );
    });

    group('resolveProduceProduct', () {
      const produceName = 'Apple';
      const produceBarcode = 'produce-apple';

      test(
        'checks Firebase before USDA when resolving produce',
        () async {
          when(
            () => mockFirebaseCache.resolveProduceProduct(produceName),
          ).thenAnswer(
            (_) async => testProduct.copyWith(
              barcode: produceBarcode,
              name: produceName,
              productType: ProductType.produce,
            ),
          );

          final product = await fbRepo.resolveProduceProduct(produceName);

          expect(product, isNotNull);
          expect(product.barcode, produceBarcode);
          expect(product.productType, ProductType.produce);
          expect(product.source, 'manual');
          expect(product.category, 'Fruit');
          verify(
            () => mockFirebaseCache.resolveProduceProduct(produceName),
          ).called(1);
          verifyNever(() => mockUsda.searchFood(any()));
        },
      );

      test(
        'uses USDA when firebaseCache is null',
        () async {
          final repoNoFb = ProductRepository(
            mockDb,
            mockApi,
            usdaClient: mockUsda,
            metaDao: mockMetaDao,
          );
          when(
            () => mockUsda.searchFood(produceName),
          ).thenAnswer((_) async => []);

          final product = await repoNoFb.resolveProduceProduct(produceName);

          expect(product, isNotNull);
          expect(product.barcode, produceBarcode);
          verify(() => mockUsda.searchFood(produceName)).called(1);
        },
      );

      test(
        'falls through to USDA when Firebase produce lookup throws',
        () async {
          when(
            () => mockFirebaseCache.resolveProduceProduct(produceName),
          ).thenThrow(Exception('Firestore down'));
          when(() => mockUsda.searchFood(produceName)).thenAnswer(
            (_) async => [],
          );

          final product = await fbRepo.resolveProduceProduct(produceName);

          expect(product, isNotNull);
          expect(product.barcode, produceBarcode);
          verify(
            () => mockFirebaseCache.resolveProduceProduct(produceName),
          ).called(1);
          verify(() => mockUsda.searchFood(produceName)).called(1);
        },
      );
    });

    group('addProduceToInventory', () {
      const produceBarcode = 'produce-apple';
      const produceName = 'Apple';

      setUp(() {
        when(
          () => mockDb.insertOrMergeInventoryItem(any()),
        ).thenAnswer((_) async => 42);
        when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});
      });

      test(
        'uses Firebase when local cache misses for produce',
        () async {
          when(
            () => mockDb.getProduct(produceBarcode),
          ).thenAnswer((_) async => null);
          when(
            () => mockFirebaseCache.resolveProduceProduct(produceName),
          ).thenAnswer(
            (_) async => testProduct.copyWith(
              name: produceName,
              energyKcal: 52,
            ),
          );

          final id = await fbRepo.addProduceToInventory(
            produceName,
            inventoryId: 1,
          );

          expect(id, 42);
          verify(
            () => mockFirebaseCache.resolveProduceProduct(produceName),
          ).called(1);
          verify(() => mockDb.insertProduct(captureAny()));
          verifyNever(() => mockUsda.searchFood(any()));
        },
      );
    });
  });

  group('getProductsForBarcodes', () {
    test('batches cached lookups and fetches only the misses', () async {
      when(() => mockDb.getProductsByBarcodes(['a', 'b', 'c'])).thenAnswer(
        (_) async => [
          const Product(barcode: 'a', name: 'Alpha'),
          const Product(barcode: 'b', name: 'Bravo'),
        ],
      );
      when(() => mockDb.getProduct('c')).thenAnswer((_) async => null);
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => 1);
      when(
        () => mockApi.getByBarcode(
          'c',
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => const Product(barcode: 'c', name: 'Charlie'),
      );

      final result = await repository.getProductsForBarcodes(['a', 'b', 'c']);

      expect(result.keys.toSet(), {'a', 'b', 'c'});
      expect(result['a']!.name, 'Alpha');
      expect(result['c']!.name, 'Charlie');
      verify(() => mockDb.getProductsByBarcodes(['a', 'b', 'c'])).called(1);
      verifyNever(
        () => mockApi.getByBarcode(
          'a',
          languageCode: any(named: 'languageCode'),
        ),
      );
      verifyNever(
        () => mockApi.getByBarcode(
          'b',
          languageCode: any(named: 'languageCode'),
        ),
      );
      verify(
        () => mockApi.getByBarcode(
          'c',
          languageCode: any(named: 'languageCode'),
        ),
      ).called(1);
    });

    test('skips barcodes whose fetch fails', () async {
      when(() => mockDb.getProductsByBarcodes(['a', 'b'])).thenAnswer(
        (_) async => [const Product(barcode: 'a', name: 'Alpha')],
      );
      when(() => mockDb.getProduct('b')).thenAnswer((_) async => null);
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => 1);
      when(
        () => mockApi.getByBarcode(
          'b',
          languageCode: any(named: 'languageCode'),
        ),
      ).thenThrow(Exception('Network error'));

      final result = await repository.getProductsForBarcodes(['a', 'b']);

      expect(result.keys.toSet(), {'a'});
    });

    test('returns empty for an empty input', () async {
      when(() => mockDb.getProductsByBarcodes([])).thenAnswer((_) async => []);
      final result = await repository.getProductsForBarcodes([]);
      expect(result, isEmpty);
    });
  });

  group('getProduct single-flight', () {
    test(
      'shares one API request between concurrent lookups of the same barcode',
      () async {
        when(
          () => mockDb.getProduct(testBarcode),
        ).thenAnswer((_) async => null);
        when(() => mockDb.insertProduct(any())).thenAnswer((_) async => 1);
        when(
          () => mockApi.getByBarcode(
            testBarcode,
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer(
          (_) async => testProduct,
        );

        final first = repository.getProduct(testBarcode);
        final second = repository.getProduct(testBarcode);
        final results = await Future.wait([first, second]);

        expect(results.map((p) => p.barcode), [testBarcode, testBarcode]);
        verify(
          () => mockApi.getByBarcode(
            testBarcode,
            languageCode: any(named: 'languageCode'),
          ),
        ).called(1);
        verify(() => mockDb.insertProduct(testProduct)).called(1);
      },
    );

    test('does not deduplicate requests for different barcodes', () async {
      when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => 1);
      when(
        () => mockApi.getByBarcode(
          any(),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => const Product(barcode: 'x', name: 'X'));

      await Future.wait([
        repository.getProduct('x1'),
        repository.getProduct('x2'),
      ]);

      verify(
        () => mockApi.getByBarcode(
          any(),
          languageCode: any(named: 'languageCode'),
        ),
      ).called(2);
    });
  });
}
