import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/photo_service.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/services/shopping_list_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Re-usable mocks
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockShoppingListDao extends Mock implements ShoppingListDao {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockPhotoService extends Mock implements PhotoService {}

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
  late MockPhotoService mockPhotoService;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    registerFallbackValue(db);

    mockDb = MockDatabaseHelper();
    mockDao = MockShoppingListDao();
    mockRepo = MockProductRepository();
    mockPhotoService = MockPhotoService();

    when(() => mockDb.database).thenAnswer((_) async => db);
    when(() => mockDb.shoppingListDao).thenReturn(mockDao);
    when(() => mockDb.getProduct(any())).thenAnswer((_) async => null);
    when(
      () => mockDao.insertOrMergeByBarcode(any(), any()),
    ).thenAnswer((_) async => 1);
    when(
      () => mockRepo.getProduct(any()),
    ).thenThrow(ProductNotFoundException('999'));
    when(() => mockRepo.cacheProduct(any())).thenAnswer((_) async => {});
  });

  tearDown(() async {
    await db.close();
  });

  ShoppingListService service() => ShoppingListService(
    mockDb,
    mockRepo,
    mockPhotoService,
  );

  group('addShoppingItem product existence guard', () {
    test('when product is in cache, inserts without fetching', () async {
      when(
        () => mockDb.getProduct('001'),
      ).thenAnswer((_) async => const Product(barcode: '001', name: 'Milk'));

      await service().addShoppingItem(
        const ShoppingItem(name: 'Milk', barcode: '001'),
        activeInventoryId: 1,
      );

      verify(() => mockDb.getProduct('001')).called(1);
      verifyNever(() => mockRepo.getProduct(any()));
      verify(
        () => mockDao.insertOrMergeByBarcode(
          any(),
          any(
            that: isA<ShoppingItem>().having(
              (i) => i.barcode,
              'barcode',
              '001',
            ),
          ),
        ),
      ).called(1);
    });

    test('when product missing, fetches from repo and caches it', () async {
      when(() => mockDb.getProduct('002')).thenAnswer((_) async => null);
      when(() => mockRepo.getProduct('002')).thenAnswer(
        (_) async => const Product(barcode: '002', name: 'Fetched Milk'),
      );

      await service().addShoppingItem(
        const ShoppingItem(name: 'Fetched Milk', barcode: '002'),
        activeInventoryId: 1,
      );

      verify(() => mockRepo.getProduct('002')).called(1);
      verify(() => mockRepo.cacheProduct(any())).called(1);
      verify(
        () => mockDao.insertOrMergeByBarcode(
          any(),
          any(
            that: isA<ShoppingItem>().having(
              (i) => i.barcode,
              'barcode',
              '002',
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'when product missing and fetch fails, insert with null barcode',
      () async {
        await service().addShoppingItem(
          const ShoppingItem(name: 'Unknown', barcode: '999'),
          activeInventoryId: 1,
        );

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

    test(
      'when fetch fails with FetchFailedException, insert without barcode',
      () async {
        when(
          () => mockRepo.getProduct(any()),
        ).thenThrow(FetchFailedException('offline'));

        await service().addShoppingItem(
          const ShoppingItem(name: 'Offline', barcode: '555'),
          activeInventoryId: 1,
        );

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

    test('when barcode is null, skips product check entirely', () async {
      await service().addShoppingItem(
        const ShoppingItem(name: 'Custom'),
        activeInventoryId: 1,
      );

      verifyNever(() => mockDb.getProduct(any()));
      verifyNever(() => mockRepo.getProduct(any()));
      verify(() => mockDao.insertOrMergeByBarcode(any(), any())).called(1);
    });

    test('when barcode is empty string, skips product check', () async {
      await service().addShoppingItem(
        const ShoppingItem(name: 'Empty', barcode: ''),
        activeInventoryId: 1,
      );

      verifyNever(() => mockDb.getProduct(any()));
      verifyNever(() => mockRepo.getProduct(any()));
      verify(() => mockDao.insertOrMergeByBarcode(any(), any())).called(1);
    });

    test('scopes items without an inventory to the active inventory', () async {
      await service().addShoppingItem(
        const ShoppingItem(name: 'Scoped', barcode: '001'),
        activeInventoryId: 7,
      );

      verify(
        () => mockDao.insertOrMergeByBarcode(
          any(),
          any(
            that: isA<ShoppingItem>().having(
              (i) => i.inventoryId,
              'inventoryId',
              7,
            ),
          ),
        ),
      ).called(1);
    });
  });

  group('deleteShoppingItem', () {
    test('deletes the photo and the item', () async {
      when(() => mockPhotoService.deletePhotoForItem(3)).thenAnswer(
        (_) async {},
      );
      when(() => mockDb.deleteShoppingItem(3)).thenAnswer((_) async => 1);

      await service().deleteShoppingItem(3);

      verify(() => mockPhotoService.deletePhotoForItem(3)).called(1);
      verify(() => mockDb.deleteShoppingItem(3)).called(1);
    });
  });

  group('toggleShoppingItem', () {
    test('toggles the purchased state via the database', () async {
      when(() => mockDb.toggleShoppingItemPurchased(5)).thenAnswer(
        (_) async => 1,
      );

      await service().toggleShoppingItem(5);

      verify(() => mockDb.toggleShoppingItemPurchased(5)).called(1);
    });
  });

  group('updateShoppingItemPrice', () {
    test('forwards the price fields', () async {
      when(
        () => mockDb.updateShoppingItemPriceFields(
          any(),
          priceAmount: any(named: 'priceAmount'),
          priceCurrency: any(named: 'priceCurrency'),
          priceStore: any(named: 'priceStore'),
          pricePhotoPath: any(named: 'pricePhotoPath'),
        ),
      ).thenAnswer((_) async => 1);

      await service().updateShoppingItemPrice(
        4,
        priceAmount: 2.5,
        priceCurrency: 'EUR',
        priceStore: 'Lidl',
      );

      verify(
        () => mockDb.updateShoppingItemPriceFields(
          4,
          priceAmount: 2.5,
          priceCurrency: 'EUR',
          priceStore: 'Lidl',
        ),
      ).called(1);
    });
  });
}
