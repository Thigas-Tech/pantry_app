import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:pantry_app/models/produce_cache_entry.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_cache_entry.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_cache_entry.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/firebase_cache_client.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockFirebaseCacheClient extends Mock implements FirebaseCacheClient {}

class MockUsdaApiClient extends Mock implements UsdaApiClient {}

class MockOffAdapter extends Mock implements OffAdapter {}

class MockFirebaseCacheMetaDao extends Mock implements FirebaseCacheMetaDao {}

class FakeDatabase extends Fake implements Database {}

void main() {
  const testBarcode = '7622210449283';
  const produceName = 'apple';
  const produceCacheKey = 'produce:apple';

  final now = DateTime.now().millisecondsSinceEpoch;

  const barcodedProduct = Product(
    barcode: testBarcode,
    name: 'Nutella',
    brand: 'Ferrero',
    energyKcal: 539,
  );

  const produceProduct = Product(
    barcode: 'produce-Apple',
    name: 'Apple',
    productType: ProductType.produce,
    source: 'manual',
    energyKcal: 52,
  );

  const produceCacheEntry = ProduceCacheEntry(
    fdcId: 1750339,
    name: 'apple',
    nutrition: {'energyKcal': 52},
    createdAt: 1700000000000,
    lastRefreshedAt: 1700000000000,
    nextRefreshAt: 1708754400000,
  );

  const barcodedCacheEntry = ProductCacheEntry(
    barcode: testBarcode,
    name: 'Nutella',
    createdAt: 1700000000000,
    lastRefreshedAt: 1700000000000,
    nextRefreshAt: 1708754400000,
    brand: 'Ferrero',
    energyKcal: 539,
  );

  late Database db;
  late MockDatabaseHelper mockDb;
  late MockFirebaseCacheClient mockClient;
  late MockUsdaApiClient mockUsda;
  late MockOffAdapter mockOff;
  late MockFirebaseCacheMetaDao mockMetaDao;
  late FirebaseCacheService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(FakeDatabase());
    registerFallbackValue(const Product(barcode: '', name: ''));
    registerFallbackValue(
      const ProductCacheEntry(
        barcode: '',
        name: '',
        createdAt: 0,
        lastRefreshedAt: 0,
        nextRefreshAt: 0,
      ),
    );
    registerFallbackValue(
      const ProduceCacheEntry(
        fdcId: 0,
        name: '',
        nutrition: <String, double>{},
        createdAt: 0,
        lastRefreshedAt: 0,
        nextRefreshAt: 0,
      ),
    );
    registerFallbackValue(
      const RecipeCacheEntry(
        recipeId: '',
        name: '',
        instructions: '',
        servings: 0,
        ingredients: [],
        createdAt: 0,
        lastRefreshedAt: 0,
        nextRefreshAt: 0,
      ),
    );
    registerFallbackValue(<RecipeCacheEntry>[]);
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await const FirebaseCacheMetaDao().createTable(db);

    mockDb = MockDatabaseHelper();
    mockClient = MockFirebaseCacheClient();
    mockUsda = MockUsdaApiClient();
    mockOff = MockOffAdapter();
    mockMetaDao = MockFirebaseCacheMetaDao();

    when(() => mockDb.database).thenAnswer((_) async => db);
    when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});
    when(() => mockClient.isAvailable).thenReturn(true);
    when(
      () => mockMetaDao.upsert(
        any(),
        any(),
        any(),
        lastRefreshedAt: any(named: 'lastRefreshedAt'),
        nextRefreshAt: any(named: 'nextRefreshAt'),
        fdcId: any(named: 'fdcId'),
      ),
    ).thenAnswer((_) async => {});
    when(
      () => mockMetaDao.updateRefreshTimestamps(
        any(),
        any(),
        lastRefreshedAt: any(named: 'lastRefreshedAt'),
        nextRefreshAt: any(named: 'nextRefreshAt'),
      ),
    ).thenAnswer((_) async => {});
    when(() => mockClient.setProduct(any())).thenAnswer((_) async => true);
    when(() => mockClient.setProduce(any())).thenAnswer((_) async => true);
    when(
      () => mockOff.getByBarcode(
        any(),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenThrow(ProductNotFoundException(''));

    service = FirebaseCacheService(
      db: mockDb,
      firebaseClient: mockClient,
      usdaClient: mockUsda,
      offAdapter: mockOff,
      metaDao: mockMetaDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('resolveBarcodedProduct', () {
    test('returns product from firebase cache when available', () async {
      when(() => mockClient.getProduct(testBarcode)).thenAnswer(
        (_) async => barcodedCacheEntry,
      );

      final result = await service.resolveBarcodedProduct(
        testBarcode,
        languageCode: 'en',
      );

      expect(result, isNotNull);
      expect(result!.barcode, testBarcode);
      expect(result.name, 'Nutella');
      verifyNever(() => mockOff.getByBarcode(any()));
    });

    test('falls through to OFF on firebase miss and caches result', () async {
      when(() => mockClient.getProduct(testBarcode)).thenAnswer(
        (_) async => null,
      );
      when(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => barcodedProduct);
      when(() => mockClient.setProduct(any())).thenAnswer((_) async => true);

      final result = await service.resolveBarcodedProduct(
        testBarcode,
        languageCode: 'en',
      );

      expect(result, isNotNull);
      expect(result!.barcode, testBarcode);
      verify(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).called(1);
    });

    test('returns null when both firebase and OFF miss', () async {
      when(() => mockClient.getProduct(testBarcode)).thenAnswer(
        (_) async => null,
      );
      when(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenThrow(ProductNotFoundException(''));

      final result = await service.resolveBarcodedProduct(
        testBarcode,
        languageCode: 'en',
      );

      expect(result, isNull);
    });

    test('calls OFF directly when firebase is unavailable', () async {
      when(() => mockClient.isAvailable).thenReturn(false);
      when(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => barcodedProduct);

      final result = await service.resolveBarcodedProduct(
        testBarcode,
        languageCode: 'en',
      );

      expect(result, isNotNull);
      verifyNever(() => mockClient.getProduct(any()));
      verify(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).called(1);
    });

    test('falls through to OFF when firebase get throws', () async {
      when(() => mockClient.getProduct(testBarcode)).thenThrow(
        Exception('Firestore error'),
      );
      when(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => barcodedProduct);

      final result = await service.resolveBarcodedProduct(
        testBarcode,
        languageCode: 'en',
      );

      expect(result, isNotNull);
      expect(result!.name, 'Nutella');
    });

    test(
      'returns product even when firebase set fails after OFF success',
      () async {
        when(() => mockClient.getProduct(testBarcode)).thenAnswer(
          (_) async => null,
        );
        when(
          () => mockOff.getByBarcode(
            testBarcode,
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async => barcodedProduct);
        when(() => mockClient.setProduct(any())).thenThrow(
          Exception('Firestore write error'),
        );

        final result = await service.resolveBarcodedProduct(
          testBarcode,
          languageCode: 'en',
        );

        expect(result, isNotNull);
        expect(result!.name, 'Nutella');
      },
    );
  });

  group('resolveProduceProduct', () {
    test('returns product from firebase when available', () async {
      when(() => mockClient.getProduce(produceName)).thenAnswer(
        (_) async => produceCacheEntry,
      );

      final result = await service.resolveProduceProduct(produceName);

      expect(result, isNotNull);
      expect(result!.productType, ProductType.produce);
      verifyNever(() => mockUsda.searchFood(any()));
    });

    test('falls through to USDA on firebase miss and caches result', () async {
      when(() => mockClient.getProduce(produceName)).thenAnswer(
        (_) async => null,
      );
      when(() => mockUsda.searchFood(produceName)).thenAnswer(
        (_) async => [produceProduct],
      );
      when(() => mockClient.setProduce(any())).thenAnswer((_) async => true);

      final result = await service.resolveProduceProduct(produceName);

      expect(result, isNotNull);
      expect(result!.name, 'Apple');
      verify(() => mockUsda.searchFood(produceName)).called(1);
    });

    test('returns null when both firebase and USDA miss', () async {
      when(() => mockClient.getProduce(produceName)).thenAnswer(
        (_) async => null,
      );
      when(() => mockUsda.searchFood(produceName)).thenAnswer(
        (_) async => <Product>[],
      );

      final result = await service.resolveProduceProduct(produceName);

      expect(result, isNull);
    });

    test('returns null for empty produce name', () async {
      final result = await service.resolveProduceProduct('');
      expect(result, isNull);

      final result2 = await service.resolveProduceProduct('   ');
      expect(result2, isNull);
    });

    test('calls USDA directly when firebase is unavailable', () async {
      when(() => mockClient.isAvailable).thenReturn(false);
      when(() => mockUsda.searchFood(produceName)).thenAnswer(
        (_) async => [produceProduct],
      );

      final result = await service.resolveProduceProduct(produceName);

      expect(result, isNotNull);
      verifyNever(() => mockClient.getProduce(any()));
      verify(() => mockUsda.searchFood(produceName)).called(1);
    });
  });

  group('cacheBarcodedProduct', () {
    test('writes to firestore and upserts metadata', () async {
      when(() => mockClient.setProduct(any())).thenAnswer((_) async => true);

      await service.cacheBarcodedProduct(barcodedProduct);

      verify(() => mockClient.setProduct(any())).called(1);
      verify(
        () => mockMetaDao.upsert(
          any(),
          testBarcode,
          'barcoded',
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
          fdcId: any(named: 'fdcId'),
        ),
      ).called(1);
    });

    test('no-op when firebase client is unavailable', () async {
      when(() => mockClient.isAvailable).thenReturn(false);

      await service.cacheBarcodedProduct(barcodedProduct);

      verifyNever(() => mockClient.setProduct(any()));
      verifyNever(
        () => mockMetaDao.upsert(
          any(),
          any(),
          any(),
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
        ),
      );
    });
  });

  group('cacheProduceProduct', () {
    test('writes to firestore and upserts metadata', () async {
      when(() => mockClient.setProduce(any())).thenAnswer((_) async => true);

      await service.cacheProduceProduct(
        produceProduct,
        produceName,
        fdcId: 1750339,
      );

      verify(() => mockClient.setProduce(any())).called(1);
      verify(
        () => mockMetaDao.upsert(
          any(),
          produceCacheKey,
          'produce',
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
          fdcId: 1750339,
        ),
      ).called(1);
    });

    test('no-op when firebase client is unavailable', () async {
      when(() => mockClient.isAvailable).thenReturn(false);

      await service.cacheProduceProduct(produceProduct, produceName);

      verifyNever(() => mockClient.setProduce(any()));
      verifyNever(
        () => mockMetaDao.upsert(
          any(),
          any(),
          any(),
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
        ),
      );
    });
  });

  group('refreshStaleEntries', () {
    test('returns 0 when no stale entries', () async {
      when(
        () => mockMetaDao.getStaleEntries(
          any(),
          nowInMs: any(named: 'nowInMs'),
        ),
      ).thenAnswer((_) async => []);

      final count = await service.refreshStaleEntries();

      expect(count, 0);
    });

    test('refreshes one stale barcoded entry', () async {
      final staleRow = <String, dynamic>{
        'cache_key': testBarcode,
        'cache_type': 'barcoded',
        'fdc_id': null,
        'last_refreshed_at': now - 200 * 24 * 60 * 60 * 1000,
        'next_refresh_at': now - 1000,
      };
      when(
        () => mockMetaDao.getStaleEntries(
          any(),
          nowInMs: any(named: 'nowInMs'),
        ),
      ).thenAnswer((_) async => [staleRow]);
      when(() => mockClient.getProduct(testBarcode)).thenAnswer(
        (_) async => barcodedCacheEntry,
      );
      when(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => barcodedProduct);
      when(() => mockClient.setProduct(any())).thenAnswer((_) async => true);

      final count = await service.refreshStaleEntries();

      expect(count, 1);
      verify(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).called(1);
      verify(() => mockClient.setProduct(any())).called(1);
      verify(
        () => mockMetaDao.updateRefreshTimestamps(
          any(),
          testBarcode,
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
        ),
      ).called(1);
    });

    test('refreshes one stale produce entry', () async {
      final staleRow = <String, dynamic>{
        'cache_key': produceCacheKey,
        'cache_type': 'produce',
        'fdc_id': 1750339,
        'last_refreshed_at': now - 200 * 24 * 60 * 60 * 1000,
        'next_refresh_at': now - 1000,
      };
      when(
        () => mockMetaDao.getStaleEntries(
          any(),
          nowInMs: any(named: 'nowInMs'),
        ),
      ).thenAnswer((_) async => [staleRow]);
      when(() => mockClient.getProduce('apple')).thenAnswer(
        (_) async => produceCacheEntry,
      );
      when(() => mockUsda.searchFood('apple')).thenAnswer(
        (_) async => [produceProduct],
      );
      when(() => mockClient.setProduce(any())).thenAnswer((_) async => true);

      final count = await service.refreshStaleEntries();

      expect(count, 1);
      verify(() => mockUsda.searchFood('apple')).called(1);
      verify(
        () => mockMetaDao.updateRefreshTimestamps(
          any(),
          produceCacheKey,
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
        ),
      ).called(1);
    });

    test('skips entry when API fails and continues processing', () async {
      final goodStale = <String, dynamic>{
        'cache_key': testBarcode,
        'cache_type': 'barcoded',
        'fdc_id': null,
        'last_refreshed_at': now - 200 * 24 * 60 * 60 * 1000,
        'next_refresh_at': now - 1000,
      };
      final badStale = <String, dynamic>{
        'cache_key': produceCacheKey,
        'cache_type': 'produce',
        'fdc_id': 1750339,
        'last_refreshed_at': now - 200 * 24 * 60 * 60 * 1000,
        'next_refresh_at': now - 1000,
      };
      when(
        () => mockMetaDao.getStaleEntries(
          any(),
          nowInMs: any(named: 'nowInMs'),
        ),
      ).thenAnswer((_) async => [badStale, goodStale]);
      when(() => mockUsda.searchFood('apple')).thenThrow(
        Exception('USDA error'),
      );
      when(() => mockClient.getProduct(testBarcode)).thenAnswer(
        (_) async => barcodedCacheEntry,
      );
      when(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => barcodedProduct);
      when(() => mockClient.setProduct(any())).thenAnswer((_) async => true);

      final count = await service.refreshStaleEntries();

      expect(count, 1);
      verify(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).called(1);
    });

    test('preserves createdAt during refresh', () async {
      final staleRow = <String, dynamic>{
        'cache_key': testBarcode,
        'cache_type': 'barcoded',
        'fdc_id': null,
        'last_refreshed_at': now - 200 * 24 * 60 * 60 * 1000,
        'next_refresh_at': now - 1000,
      };
      const oldEntry = ProductCacheEntry(
        barcode: testBarcode,
        name: 'Nutella',
        createdAt: 1000000000000,
        lastRefreshedAt: 1000000000000,
        nextRefreshAt: 1008754400000,
        brand: 'Ferrero',
        energyKcal: 539,
      );
      when(
        () => mockMetaDao.getStaleEntries(
          any(),
          nowInMs: any(named: 'nowInMs'),
        ),
      ).thenAnswer((_) async => [staleRow]);
      when(() => mockClient.getProduct(testBarcode)).thenAnswer(
        (_) async => oldEntry,
      );
      when(
        () => mockOff.getByBarcode(
          testBarcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => barcodedProduct);
      when(() => mockClient.setProduct(any())).thenAnswer((_) async => true);

      await service.refreshStaleEntries();

      final captured =
          verify(
                () => mockClient.setProduct(captureAny()),
              ).captured.first
              as ProductCacheEntry;
      expect(captured.createdAt, 1000000000000);
    });

    test('respects maxBatchSize', () async {
      final staleRows = List<Map<String, dynamic>>.generate(30, (i) {
        return <String, dynamic>{
          'cache_key': i < 15 ? 'barcode-$i' : 'produce:item-$i',
          'cache_type': i < 15 ? 'barcoded' : 'produce',
          'fdc_id': null,
          'last_refreshed_at': now - 200 * 24 * 60 * 60 * 1000,
          'next_refresh_at': now - 1000,
        };
      });
      when(
        () => mockMetaDao.getStaleEntries(
          any(),
          nowInMs: any(named: 'nowInMs'),
        ),
      ).thenAnswer((_) async => staleRows);
      when(() => mockClient.getProduct(any())).thenAnswer(
        (_) async => null,
      );
      when(() => mockClient.getProduce(any())).thenAnswer(
        (_) async => null,
      );

      final count = await service.refreshStaleEntries(maxBatchSize: 10);

      expect(count, 0);
      verify(() => mockClient.getProduct(any())).called(10);
    });
  });

  group('isAvailable', () {
    test('delegates to firebase client', () {
      when(() => mockClient.isAvailable).thenReturn(true);
      expect(service.isAvailable, true);

      when(() => mockClient.isAvailable).thenReturn(false);
      expect(service.isAvailable, false);
    });
  });

  group('cacheRecipe', () {
    const recipe = Recipe(
      name: 'Test Recipe',
      instructions: 'Mix.',
      servings: 2,
      createdAt: 5000,
    );
    const ingredients = [
      RecipeIngredient(
        recipeId: 0,
        name: 'Sugar',
        barcode: '123',
        quantity: 100,
        unit: 'g',
      ),
    ];

    test('writes to firestore and upserts metadata', () async {
      when(() => mockClient.setRecipe(any())).thenAnswer((_) async => true);

      await service.cacheRecipe(recipe, ingredients);

      verify(() => mockClient.setRecipe(any())).called(1);
      verify(
        () => mockMetaDao.upsert(
          any(),
          any(),
          'recipe',
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
          fdcId: any(named: 'fdcId'),
        ),
      ).called(1);
    });

    test('no-op when firebase client is unavailable', () async {
      when(() => mockClient.isAvailable).thenReturn(false);

      await service.cacheRecipe(recipe, ingredients);

      verifyNever(() => mockClient.setRecipe(any()));
      verifyNever(
        () => mockMetaDao.upsert(
          any(),
          any(),
          any(),
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
        ),
      );
    });

    test('succeeds even when metadata upsert fails', () async {
      when(() => mockClient.setRecipe(any())).thenAnswer((_) async => true);
      when(
        () => mockMetaDao.upsert(
          any(),
          any(),
          any(),
          lastRefreshedAt: any(named: 'lastRefreshedAt'),
          nextRefreshAt: any(named: 'nextRefreshAt'),
          fdcId: any(named: 'fdcId'),
        ),
      ).thenThrow(Exception('DB error'));

      await service.cacheRecipe(recipe, ingredients);

      verify(() => mockClient.setRecipe(any())).called(1);
    });

    test('cacheRecipe uses imageUrl when provided', () async {
      when(() => mockClient.setRecipe(any())).thenAnswer((_) async => true);

      await service.cacheRecipe(
        recipe,
        ingredients,
        imageUrl: 'https://example.com/photo.jpg',
      );

      final captured =
          verify(() => mockClient.setRecipe(captureAny())).captured.first
              as RecipeCacheEntry;
      expect(captured.imageUrl, 'https://example.com/photo.jpg');
    });
  });

  group('deleteSharedRecipe', () {
    const recipeId = 'recipe:abc123';

    test('deletes from firestore and removes metadata', () async {
      when(() => mockClient.deleteRecipe(recipeId)).thenAnswer((_) async {});
      when(() => mockMetaDao.remove(any(), recipeId)).thenAnswer((_) async {});

      await service.deleteSharedRecipe(recipeId);

      verify(() => mockClient.deleteRecipe(recipeId)).called(1);
      verify(() => mockMetaDao.remove(any(), recipeId)).called(1);
    });

    test('no-op when firebase client is unavailable', () async {
      when(() => mockClient.isAvailable).thenReturn(false);

      await service.deleteSharedRecipe(recipeId);

      verifyNever(() => mockClient.deleteRecipe(any()));
      verifyNever(() => mockMetaDao.remove(any(), any()));
    });
  });

  group('getSharedRecipes', () {
    test('returns recipes from firebase client', () async {
      final expected = [
        const RecipeCacheEntry(
          recipeId: 'r1',
          name: 'Recipe 1',
          instructions: '',
          servings: 1,
          ingredients: [],
          createdAt: 100,
          lastRefreshedAt: 100,
          nextRefreshAt: 1000,
        ),
      ];
      when(
        () => mockClient.listRecipes(
          startAfter: any(named: 'startAfter'),
        ),
      ).thenAnswer((_) async => expected);

      final results = await service.getSharedRecipes();

      expect(results, hasLength(1));
      expect(results.first.recipeId, 'r1');
    });

    test('returns empty list when firebase unavailable', () async {
      when(() => mockClient.isAvailable).thenReturn(false);

      final results = await service.getSharedRecipes();
      expect(results, isEmpty);
    });
  });
}
