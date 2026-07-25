import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/produce_cache_entry.dart';
import 'package:pantry_app/models/product_cache_entry.dart';
import 'package:pantry_app/models/recipe_cache_entry.dart';
import 'package:pantry_app/services/firebase_cache_client.dart';

// ====================================================================
//  Mock Firestore hierarchy
//
//  Each mock implements the corresponding abstract interface so that
//  mocktail can intercept unstubbed method calls via `noSuchMethod`.
// ====================================================================

class MockDocumentSnapshot extends Mock implements FirestoreSnapshot {}

class MockDocumentReference extends Mock implements FirestoreDocument {}

class MockFirestore extends Mock implements FirestoreClient {}

class MockCollection extends Mock implements FirestoreCollection {}

/// Convenience: create a client with a mock firestore and enabled flag.
FirebaseCacheClient _client(FirestoreClient firestore) =>
    FirebaseCacheClient(firestore: firestore, enabled: true);

FirebaseCacheClient _disabled() => FirebaseCacheClient();

// ====================================================================
//  Sample data for tests
// ====================================================================

Map<String, dynamic> produceJson() => const {
  'fdcId': 1750339,
  'name': 'apple',
  'nutrition': {'energyKcal': 52.0, 'proteinG': 0.26},
  'createdAt': 1000000,
  'lastRefreshedAt': 1000000,
  'nextRefreshAt': 1000000,
  'schemaVersion': 1,
};

Map<String, dynamic> productJson() => const {
  'barcode': '7622210449283',
  'name': 'Nutella',
  'brand': 'Ferrero',
  'createdAt': 2000000,
  'lastRefreshedAt': 2000000,
  'nextRefreshAt': 2000000,
  'languageCode': 'en',
  'schemaVersion': 1,
};

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ProduceCacheEntry(
        fdcId: 0,
        name: '',
        nutrition: {},
        createdAt: 0,
        lastRefreshedAt: 0,
        nextRefreshAt: 0,
      ),
    );
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
    registerFallbackValue(MockCollection());
  });

  group('Produce cache', () {
    late MockDocumentSnapshot mockSnapshot;
    late MockDocumentReference mockDoc;
    late MockFirestore mockFirestore;

    setUp(() {
      mockSnapshot = MockDocumentSnapshot();
      mockDoc = MockDocumentReference();
      mockFirestore = MockFirestore();
    });

    group('getProduce', () {
      test('returns entry when doc exists', () async {
        when(
          () => mockFirestore.doc('produce_cache', 'apple'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn(produceJson());

        final result = await _client(mockFirestore).getProduce('apple');

        expect(result, isNotNull);
        expect(result!.name, 'apple');
        expect(result.fdcId, 1750339);
        expect(result.nutrition['energyKcal'], 52.0);
      });

      test('returns null when doc missing', () async {
        when(
          () => mockFirestore.doc('produce_cache', 'apple'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        final result = await _client(mockFirestore).getProduce('apple');
        expect(result, isNull);
      });

      test('returns null when not available', () async {
        final result = await _disabled().getProduce('apple');
        expect(result, isNull);
        verifyNever(() => mockFirestore.doc(any(), any()));
      });

      test('returns null on Firestore error', () async {
        when(
          () => mockFirestore.doc('produce_cache', 'apple'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenThrow(Exception('Network error'));

        final result = await _client(mockFirestore).getProduce('apple');
        expect(result, isNull);
      });
    });

    group('setProduce', () {
      setUp(() {
        when(
          () => mockFirestore.doc('produce_cache', 'apple'),
        ).thenReturn(mockDoc);
      });

      test('writes to Firestore and returns true', () async {
        when(() => mockDoc.set(any())).thenAnswer((_) async {});

        const entry = ProduceCacheEntry(
          fdcId: 1750339,
          name: 'apple',
          nutrition: {'energyKcal': 52.0},
          createdAt: 1000,
          lastRefreshedAt: 1000,
          nextRefreshAt: 1000,
        );
        final result = await _client(mockFirestore).setProduce(entry);

        expect(result, isTrue);
        verify(() => mockDoc.set(entry.toJson())).called(1);
      });

      test('returns false when not available', () async {
        const entry = ProduceCacheEntry(
          fdcId: 0,
          name: 'apple',
          nutrition: {},
          createdAt: 0,
          lastRefreshedAt: 0,
          nextRefreshAt: 0,
        );
        final result = await _disabled().setProduce(entry);
        expect(result, isFalse);
      });

      test('returns false on Firestore error', () async {
        when(() => mockDoc.set(any())).thenThrow(Exception('Write error'));

        const entry = ProduceCacheEntry(
          fdcId: 0,
          name: 'apple',
          nutrition: {},
          createdAt: 0,
          lastRefreshedAt: 0,
          nextRefreshAt: 0,
        );
        final result = await _client(mockFirestore).setProduce(entry);
        expect(result, isFalse);
      });
    });

    group('deleteProduce', () {
      test('calls delete on correct doc', () async {
        when(
          () => mockFirestore.doc('produce_cache', 'apple'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.delete()).thenAnswer((_) async {});

        await _client(mockFirestore).deleteProduce('apple');

        verify(() => mockDoc.delete()).called(1);
      });
    });
  });

  group('Product cache', () {
    late MockDocumentSnapshot mockSnapshot;
    late MockDocumentReference mockDoc;
    late MockFirestore mockFirestore;

    setUp(() {
      mockSnapshot = MockDocumentSnapshot();
      mockDoc = MockDocumentReference();
      mockFirestore = MockFirestore();
    });

    group('getProduct', () {
      test('returns entry when doc exists', () async {
        when(
          () => mockFirestore.doc('product_cache', '7622210449283'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn(productJson());

        final result = await _client(mockFirestore).getProduct(
          '7622210449283',
        );

        expect(result, isNotNull);
        expect(result!.barcode, '7622210449283');
        expect(result.name, 'Nutella');
        expect(result.brand, 'Ferrero');
      });

      test('returns null when doc missing', () async {
        when(
          () => mockFirestore.doc('product_cache', 'barcode1'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        final result = await _client(mockFirestore).getProduct('barcode1');
        expect(result, isNull);
      });

      test('returns null when not available', () async {
        final result = await _disabled().getProduct('barcode1');
        expect(result, isNull);
      });

      test('returns null on Firestore error', () async {
        when(
          () => mockFirestore.doc('product_cache', 'barcode1'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenThrow(Exception('Timeout'));

        final result = await _client(mockFirestore).getProduct('barcode1');
        expect(result, isNull);
      });
    });

    group('setProduct', () {
      setUp(() {
        when(
          () => mockFirestore.doc('product_cache', '7622210449283'),
        ).thenReturn(mockDoc);
      });

      test('writes to Firestore and returns true', () async {
        when(() => mockDoc.set(any())).thenAnswer((_) async {});

        const entry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1000,
          lastRefreshedAt: 1000,
          nextRefreshAt: 1000,
        );
        final result = await _client(mockFirestore).setProduct(entry);

        expect(result, isTrue);
        verify(() => mockDoc.set(entry.toJson())).called(1);
      });

      test('returns false when not available', () async {
        const entry = ProductCacheEntry(
          barcode: '',
          name: '',
          createdAt: 0,
          lastRefreshedAt: 0,
          nextRefreshAt: 0,
        );
        final result = await _disabled().setProduct(entry);
        expect(result, isFalse);
      });

      test('returns false on Firestore error', () async {
        when(() => mockDoc.set(any())).thenThrow(Exception('Write error'));

        const entry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1000,
          lastRefreshedAt: 1000,
          nextRefreshAt: 1000,
        );
        final result = await _client(mockFirestore).setProduct(entry);
        expect(result, isFalse);
      });
    });

    group('deleteProduct', () {
      test('calls delete on correct doc', () async {
        when(
          () => mockFirestore.doc('product_cache', '7622210449283'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.delete()).thenAnswer((_) async {});

        await _client(mockFirestore).deleteProduct('7622210449283');

        verify(() => mockDoc.delete()).called(1);
      });
    });
  });

  group('isAvailable', () {
    test('true when firestore injected and enabled', () {
      final client = FirebaseCacheClient(
        firestore: MockFirestore(),
        enabled: true,
      );
      expect(client.isAvailable, isTrue);
    });

    test('false when enabled is false', () {
      final client = FirebaseCacheClient(
        firestore: MockFirestore(),
      );
      expect(client.isAvailable, isFalse);
    });

    test('false when firestore is null', () {
      final client = FirebaseCacheClient(
        enabled: true,
      );
      expect(client.isAvailable, isFalse);
    });
  });

  group('Collection names', () {
    test('produce collection is produce_cache', () {
      expect(FirebaseCacheClient.produceCollection, 'produce_cache');
    });

    test('product collection is product_cache', () {
      expect(FirebaseCacheClient.productCollection, 'product_cache');
    });

    test('recipe collection is recipe_cache', () {
      expect(FirebaseCacheClient.recipeCollection, 'recipe_cache');
    });
  });

  group('Recipe cache', () {
    late MockDocumentSnapshot mockSnapshot;
    late MockDocumentReference mockDoc;
    late MockFirestore mockFirestore;
    late MockCollection mockCollection;

    setUp(() {
      mockSnapshot = MockDocumentSnapshot();
      mockDoc = MockDocumentReference();
      mockFirestore = MockFirestore();
      mockCollection = MockCollection();
      when(() => mockFirestore.collection('recipe_cache')).thenReturn(
        mockCollection,
      );
    });

    group('getRecipe', () {
      test('returns entry when doc exists', () async {
        when(
          () => mockFirestore.doc('recipe_cache', 'recipe123'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn({
          'recipeId': 'recipe123',
          'name': 'Test Recipe',
          'instructions': 'Mix.',
          'servings': 2,
          'ingredients': <Map<String, dynamic>>[],
          'createdAt': 1000,
          'lastRefreshedAt': 1000,
          'nextRefreshAt': 1000 + 180 * 24 * 60 * 60 * 1000,
        });

        final result = await _client(mockFirestore).getRecipe('recipe123');

        expect(result, isNotNull);
        expect(result!.recipeId, 'recipe123');
        expect(result.name, 'Test Recipe');
      });

      test('returns null when doc missing', () async {
        when(
          () => mockFirestore.doc('recipe_cache', 'recipe123'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        final result = await _client(mockFirestore).getRecipe('recipe123');
        expect(result, isNull);
      });

      test('returns null when not available', () async {
        final result = await _disabled().getRecipe('recipe123');
        expect(result, isNull);
      });

      test('returns null on Firestore error', () async {
        when(
          () => mockFirestore.doc('recipe_cache', 'recipe123'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenThrow(Exception('Timeout'));

        final result = await _client(mockFirestore).getRecipe('recipe123');
        expect(result, isNull);
      });
    });

    group('setRecipe', () {
      setUp(() {
        when(
          () => mockFirestore.doc('recipe_cache', 'recipe456'),
        ).thenReturn(mockDoc);
      });

      test('writes to Firestore and returns true', () async {
        when(() => mockDoc.set(any())).thenAnswer((_) async {});

        const entry = RecipeCacheEntry(
          recipeId: 'recipe456',
          name: 'Pancakes',
          instructions: 'Cook.',
          servings: 4,
          ingredients: [],
          createdAt: 1000,
          lastRefreshedAt: 1000,
          nextRefreshAt: 1000,
        );
        final result = await _client(mockFirestore).setRecipe(entry);

        expect(result, isTrue);
        verify(() => mockDoc.set(entry.toJson())).called(1);
      });

      test('returns false when not available', () async {
        const entry = RecipeCacheEntry(
          recipeId: '',
          name: '',
          instructions: '',
          servings: 0,
          ingredients: [],
          createdAt: 0,
          lastRefreshedAt: 0,
          nextRefreshAt: 0,
        );
        final result = await _disabled().setRecipe(entry);
        expect(result, isFalse);
      });

      test('returns false on Firestore error', () async {
        when(() => mockDoc.set(any())).thenThrow(Exception('Write error'));

        const entry = RecipeCacheEntry(
          recipeId: 'recipe456',
          name: 'Pancakes',
          instructions: 'Cook.',
          servings: 4,
          ingredients: [],
          createdAt: 1000,
          lastRefreshedAt: 1000,
          nextRefreshAt: 1000,
        );
        final result = await _client(mockFirestore).setRecipe(entry);
        expect(result, isFalse);
      });
    });

    group('deleteRecipe', () {
      test('calls delete on correct doc', () async {
        when(
          () => mockFirestore.doc('recipe_cache', 'recipe789'),
        ).thenReturn(mockDoc);
        when(() => mockDoc.delete()).thenAnswer((_) async {});

        await _client(mockFirestore).deleteRecipe('recipe789');

        verify(() => mockDoc.delete()).called(1);
      });
    });

    group('listRecipes', () {
      test('returns recipes when collection has docs', () async {
        when(
          () => mockCollection.orderBy('createdAt', descending: true),
        ).thenReturn(mockCollection);
        when(() => mockCollection.limit(20)).thenReturn(mockCollection);
        when(() => mockCollection.get()).thenAnswer(
          (_) async => [
            _snapshotWith({
              'recipeId': 'r1',
              'name': 'R1',
              'instructions': '',
              'servings': 1,
              'ingredients': <Map<String, dynamic>>[],
              'createdAt': 100,
              'lastRefreshedAt': 100,
              'nextRefreshAt': 1000,
            }),
            _snapshotWith({
              'recipeId': 'r2',
              'name': 'R2',
              'instructions': '',
              'servings': 2,
              'ingredients': <Map<String, dynamic>>[],
              'createdAt': 200,
              'lastRefreshedAt': 200,
              'nextRefreshAt': 2000,
            }),
          ],
        );

        final results = await _client(mockFirestore).listRecipes();

        expect(results, hasLength(2));
        expect(results[0].name, 'R1');
        expect(results[1].name, 'R2');
        verify(
          () => mockCollection.orderBy('createdAt', descending: true),
        ).called(1);
        verify(() => mockCollection.limit(20)).called(1);
      });

      test('supports pagination with startAfter', () async {
        when(
          () => mockCollection.orderBy('createdAt', descending: true),
        ).thenReturn(mockCollection);
        when(() => mockCollection.limit(10)).thenReturn(mockCollection);
        when(() => mockCollection.startAfter('r1')).thenReturn(mockCollection);
        when(() => mockCollection.get()).thenAnswer((_) async => []);

        await _client(mockFirestore).listRecipes(
          limit: 10,
          startAfter: 'r1',
        );

        verify(() => mockCollection.startAfter('r1')).called(1);
        verify(() => mockCollection.limit(10)).called(1);
      });

      test('returns empty list when not available', () async {
        final results = await _disabled().listRecipes();
        expect(results, isEmpty);
      });

      test('returns empty list on Firestore error', () async {
        when(
          () => mockCollection.orderBy('createdAt', descending: true),
        ).thenReturn(mockCollection);
        when(() => mockCollection.limit(20)).thenReturn(mockCollection);
        when(() => mockCollection.get()).thenThrow(Exception('Error'));

        final results = await _client(mockFirestore).listRecipes();
        expect(results, isEmpty);
      });
    });
  });
}

FirestoreSnapshot _snapshotWith(Map<String, dynamic> data) {
  final snapshot = MockDocumentSnapshot();
  when(() => snapshot.exists).thenReturn(true);
  when(snapshot.data).thenReturn(data);
  return snapshot;
}
