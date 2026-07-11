import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/price_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late PriceDao dao;
  late InventoryDao inventoryDao;

  setUp(() async {
    dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
    await dbHelper.database;
    dao = const PriceDao();
    inventoryDao = const InventoryDao();
    const productDao = ProductDao();
    final db = await dbHelper.database;
    await productDao.insert(
      db,
      const Product(barcode: '123', name: 'Test Product'),
    );
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.close();
  });

  group('PriceDao basic CRUD', () {
    const price = Price(
      barcode: '123',
      price: 10.5,
      store: 'Store A',
      datePurchased: 123456789,
    );

    test('insert and getById', () async {
      final db = await dbHelper.database;
      final id = await dao.insert(db, price);
      final fetched = await dao.getById(db, id);
      expect(fetched, isNotNull);
      expect(fetched!.price, 10.5);
      expect(fetched.barcode, '123');
    });

    test('listByBarcode and getLatest', () async {
      final db = await dbHelper.database;
      await dao.insert(db, price);
      await dao.insert(
        db,
        price.copyWith(price: 12, datePurchased: 999999999),
      );

      final list = await dao.listByBarcode(db, '123');
      expect(list.length, 2);
      expect(list.first.price, 12.0); // Latest first

      final latest = await dao.getLatest(db, '123');
      expect(latest!.price, 12.0);
    });

    test('update and delete', () async {
      final db = await dbHelper.database;
      final id = await dao.insert(db, price);
      final updated = price.copyWith(id: id, price: 15);
      await dao.update(db, updated);
      expect((await dao.getById(db, id))!.price, 15);

      await dao.delete(db, id);
      expect(await dao.getById(db, id), isNull);
    });
  });

  group('PriceDao statistics', () {
    setUp(() async {
      final db = await dbHelper.database;
      const productDao = ProductDao();

      await productDao.insert(
        db,
        const Product(barcode: 'p1', name: 'Product 1'),
      );
      await productDao.insert(
        db,
        const Product(barcode: 'p2', name: 'Product 2'),
      );

      // Inventory Home (1)
      await inventoryDao.insert(db, const InventoryItem(barcode: 'p1'));
      await inventoryDao.insert(db, const InventoryItem(barcode: 'p2'));

      // Prices for p1 (Latest: 10.0)
      await dao.insert(
        db,
        const Price(barcode: 'p1', price: 8, datePurchased: 100),
      );
      await dao.insert(
        db,
        const Price(barcode: 'p1', price: 10, datePurchased: 200),
      );

      // Prices for p2 (Latest: 20.0)
      await dao.insert(
        db,
        const Price(barcode: 'p2', price: 15, datePurchased: 100),
      );
      await dao.insert(
        db,
        const Price(barcode: 'p2', price: 20, datePurchased: 200),
      );
    });

    test('totalInventoryValue computes sum of latest prices', () async {
      final db = await dbHelper.database;
      final total = await dao.totalInventoryValue(db, 1);
      expect(total, 30.0); // 10.0 + 20.0
    });

    test('averageItemPrice computes average of latest prices', () async {
      final db = await dbHelper.database;
      final avg = await dao.averageItemPrice(db, 1);
      expect(avg, 15.0); // (10 + 20) / 2
    });

    test('pricedItemCount counts distinct priced products', () async {
      final db = await dbHelper.database;
      expect(await dao.pricedItemCount(db, 1), 2);
    });
  });

  group('PriceDao sync and retention', () {
    test('getBySyncStatus filters correctly', () async {
      final db = await dbHelper.database;
      const productDao = ProductDao();
      await productDao.insert(db, const Product(barcode: '1', name: 'P1'));
      await productDao.insert(db, const Product(barcode: '2', name: 'P2'));

      await dao.insert(
        db,
        const Price(barcode: '1', price: 10, syncStatus: priceSyncPending),
      );
      await dao.insert(
        db,
        const Price(barcode: '2', price: 10),
      );

      final pending = await dao.getBySyncStatus(db, priceSyncPending);
      expect(pending.length, 1);
      expect(pending.first.barcode, '1');
    });

    test('deleteStale removes old prices', () async {
      final db = await dbHelper.database;
      const productDao = ProductDao();
      await productDao.insert(db, const Product(barcode: '1', name: 'P1'));
      await productDao.insert(db, const Product(barcode: '2', name: 'P2'));

      final oldDate = DateTime.now()
          .subtract(const Duration(days: 40))
          .millisecondsSinceEpoch;
      final newDate = DateTime.now()
          .subtract(const Duration(days: 10))
          .millisecondsSinceEpoch;

      await dao.insert(
        db,
        Price(barcode: '1', price: 10, datePurchased: oldDate),
      );
      await dao.insert(
        db,
        Price(barcode: '2', price: 10, datePurchased: newDate),
      );

      final deleted = await dao.deleteStale(db, 30);
      expect(deleted, 1);
      expect(await dao.count(db), 1);
      expect(await dao.getLatest(db, '2'), isNotNull);
      expect(await dao.getLatest(db, '1'), isNull);
    });
  });
}
