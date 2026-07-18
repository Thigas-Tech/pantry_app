import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/produce_cache_entry.dart';
import 'package:pantry_app/models/product_cache_entry.dart';
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
  });
}
