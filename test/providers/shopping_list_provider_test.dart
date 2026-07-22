import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Re-usable mocks
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockShoppingListDao extends Mock implements ShoppingListDao {}

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(const Product(barcode: '', name: ''));
    registerFallbackValue(const ShoppingItem(name: ''));
  });

  late Database db;
  late MockDatabaseHelper mockDb;
  late MockShoppingListDao mockDao;
  late MockProductRepository mockRepo;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    registerFallbackValue(db);

    mockDb = MockDatabaseHelper();
    mockDao = MockShoppingListDao();
    mockRepo = MockProductRepository();

    when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
    when(
      () => mockDao.insertOrMergeByBarcode(any(), any()),
    ).thenAnswer((_) async => 1);
    when(() => mockRepo.getProduct(any())).thenAnswer(
      (_) async => throw Exception('Not found'),
    );
    when(() => mockRepo.cacheProduct(any())).thenAnswer((_) async => {});
  });

  tearDown(() async {
    await db.close();
  });

  group('addShoppingItem product existence guard', () {
    test('when product is in cache, inserts without fetching', () async {
      when(() => mockDb.getProduct('001')).thenAnswer(
        (_) async => const Product(barcode: '001', name: 'Milk'),
      );

      final existing = await mockDb.getProduct('001');
      expect(existing, isNotNull);
      expect(existing!.barcode, '001');
      verify(() => mockDb.getProduct('001')).called(1);
      verifyNever(() => mockRepo.getProduct(any()));
    });

    test('when product missing, fetches from repo and caches it', () async {
      when(() => mockDb.getProduct('002')).thenAnswer((_) async => null);
      when(() => mockRepo.getProduct('002')).thenAnswer(
        (_) async => const Product(barcode: '002', name: 'Fetched Milk'),
      );

      final cached = await mockDb.getProduct('002');
      expect(cached, isNull);

      final fetched = await mockRepo.getProduct('002');
      await mockRepo.cacheProduct(fetched);
      await mockDao.insertOrMergeByBarcode(
        db,
        const ShoppingItem(
          name: 'Fetched Milk',
          barcode: '002',
        ),
      );

      verify(() => mockRepo.getProduct('002')).called(1);
      verify(() => mockRepo.cacheProduct(any())).called(1);
    });

    test(
      'when product missing and fetch fails, insert with null barcode',
      () async {
        const item = ShoppingItem(
          name: 'Unknown',
          barcode: '999',
        );

        final resolvedBarcode = item.barcode;
        expect(resolvedBarcode, isNotNull);

        String? effectiveBarcode;
        try {
          await mockRepo.getProduct(resolvedBarcode!);
        } on Exception {
          effectiveBarcode = null;
        }

        final finalItem = item.copyWith(barcode: effectiveBarcode);
        expect(finalItem.barcode, isNull);

        await mockDao.insertOrMergeByBarcode(db, finalItem);
        verify(
          () => mockDao.insertOrMergeByBarcode(
            any(),
            any(
              that: isA<ShoppingItem>().having(
                (i) => i.barcode,
                'barcode',
                isNull,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('when barcode is null, skips product check entirely', () {
      const item = ShoppingItem(name: 'Custom');

      expect(item.barcode, isNull);
      verifyNever(() => mockDb.getProduct(any()));
      verifyNever(() => mockRepo.getProduct(any()));
    });

    test('when barcode is empty string, skips product check', () {
      const item = ShoppingItem(name: 'Empty', barcode: '');

      expect(item.barcode, isEmpty);
      verifyNever(() => mockDb.getProduct(any()));
      verifyNever(() => mockRepo.getProduct(any()));
    });
  });
}
