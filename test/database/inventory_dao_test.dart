import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late InventoryDao dao;
  late ProductDao productDao;

  setUp(() async {
    dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
    await dbHelper.database;
    dao = const InventoryDao();
    productDao = const ProductDao();
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.close();
  });

  group('InventoryDao basic CRUD', () {
    const product = Product(barcode: '123', name: 'Test Product');

    setUp(() async {
      final db = await dbHelper.database;
      await productDao.insert(db, product);
    });

    test('insert and list', () async {
      final db = await dbHelper.database;
      const item = InventoryItem(barcode: '123', quantity: 2, unit: 'kg');
      final id = await dao.insert(db, item);
      expect(id, greaterThan(0));

      final items = await dao.list(db, inventoryId: 1);
      expect(items.length, 1);
      expect(items.first.barcode, '123');
      expect(items.first.quantity, 2);
    });

    test('list by barcode', () async {
      final db = await dbHelper.database;
      final workId = await dbHelper.createInventory('Work');
      await dao.insert(db, const InventoryItem(barcode: '123'));

      // Need product for barcode 456
      await productDao.insert(db, const Product(barcode: '456', name: 'P2'));
      await dao.insert(db, const InventoryItem(barcode: '456'));
      await dao.insert(
        db,
        InventoryItem(barcode: '456', inventoryId: workId),
      );

      final homeItems = await dao.listByBarcode(db, '456', inventoryId: 1);
      expect(homeItems, hasLength(1));
      expect(homeItems.first.inventoryId, 1);

      final workItems = await dao.listByBarcode(db, '456', inventoryId: workId);
      expect(workItems, hasLength(1));
      expect(workItems.first.inventoryId, workId);
    });

    test('update item', () async {
      final db = await dbHelper.database;
      final id = await dao.insert(db, const InventoryItem(barcode: '123'));
      final updated = InventoryItem(
        id: id,
        barcode: '123',
        quantity: 5,
      );
      await dao.update(db, updated);
      final items = await dao.list(db, inventoryId: 1);
      expect(items.first.quantity, 5);
      expect(items.first.unit, 'pieces');
    });

    test('delete item', () async {
      final db = await dbHelper.database;
      final id = await dao.insert(db, const InventoryItem(barcode: '123'));
      await dao.delete(db, id);
      final items = await dao.list(db, inventoryId: 1);
      expect(items, isEmpty);
    });
  });

  group('InventoryDao complex operations', () {
    test('moveItemsToInventory reassigns items', () async {
      final db = await dbHelper.database;
      final inv2 = await dbHelper.createInventory('Work');

      await productDao.insert(db, const Product(barcode: '123', name: 'P1'));
      await productDao.insert(db, const Product(barcode: '456', name: 'P2'));

      final id1 = await dao.insert(db, const InventoryItem(barcode: '123'));
      final id2 = await dao.insert(db, const InventoryItem(barcode: '456'));

      await dao.moveItemsToInventory(db, [id1, id2], inv2);

      final homeItems = await dao.list(db, inventoryId: 1);
      final workItems = await dao.list(db, inventoryId: inv2);
      expect(homeItems, isEmpty);
      expect(workItems.length, 2);
    });

    test('listWithProduct joins correctly', () async {
      final db = await dbHelper.database;
      await productDao.insert(
        db,
        const Product(barcode: '123', name: 'Apple', imageUrl: 'img'),
      );
      await dao.insert(db, const InventoryItem(barcode: '123'));

      final rows = await dao.listWithProduct(db, inventoryId: 1);
      expect(rows.length, 1);
      expect(rows.first['product_name'], 'Apple');
      expect(rows.first['product_image_url'], 'img');
      expect(rows.first['inventory_name'], 'Home');
    });

    test('listWithProduct handles missing product', () async {
      final db = await dbHelper.database;
      // To test missing product, disable FKs or use a product then delete it.
      await productDao.insert(
        db,
        const Product(barcode: 'missing', name: 'Temp'),
      );
      await dao.insert(db, const InventoryItem(barcode: 'missing'));

      await db.execute('PRAGMA foreign_keys = OFF');
      await productDao.clear(db); // Deletes all products
      await db.execute('PRAGMA foreign_keys = ON');

      final rows = await dao.listWithProduct(db, inventoryId: 1);
      expect(rows.length, 1);
      expect(rows.first['product_name'], isNull);
      expect(rows.first['inventory_name'], 'Home');
    });

    test('expiryDistribution counts correctly', () async {
      final db = await dbHelper.database;
      final now = DateTime.now();

      await productDao.insert(db, const Product(barcode: 'expired', name: 'E'));
      await dao.insert(
        db,
        InventoryItem(
          barcode: 'expired',
          expiryDate: now.subtract(const Duration(days: 1)).toIso8601String(),
        ),
      );

      await productDao.insert(
        db,
        const Product(barcode: 'expiring', name: 'Ex'),
      );
      await dao.insert(
        db,
        InventoryItem(
          barcode: 'expiring',
          expiryDate: now.add(const Duration(days: 2)).toIso8601String(),
        ),
      );

      await productDao.insert(db, const Product(barcode: 'good', name: 'G'));
      await dao.insert(
        db,
        InventoryItem(
          barcode: 'good',
          expiryDate: now.add(const Duration(days: 10)).toIso8601String(),
        ),
      );

      await productDao.insert(db, const Product(barcode: 'no_date', name: 'N'));
      await dao.insert(
        db,
        const InventoryItem(barcode: 'no_date'),
      );

      final dist = await dao.expiryDistribution(
        db,
        inventoryId: 1,
        expiringSoonDays: 5,
      );
      expect(dist['expired'], 1);
      expect(dist['expiring'], 1);
      expect(dist['good'], 2);
    });

    test('locationDistribution counts correctly', () async {
      final db = await dbHelper.database;
      await productDao.insert(db, const Product(barcode: '1', name: 'P1'));
      await dao.insert(
        db,
        const InventoryItem(barcode: '1', location: 'fridge'),
      );

      await productDao.insert(db, const Product(barcode: '2', name: 'P2'));
      await dao.insert(
        db,
        const InventoryItem(barcode: '2', location: 'fridge'),
      );

      await productDao.insert(db, const Product(barcode: '3', name: 'P3'));
      await dao.insert(
        db,
        const InventoryItem(barcode: '3', location: 'freezer'),
      );

      final dist = await dao.locationDistribution(db, inventoryId: 1);
      expect(dist['fridge'], 2);
      expect(dist['freezer'], 1);
    });
  });
}
