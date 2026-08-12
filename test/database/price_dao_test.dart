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

      final list = await dao.listByBarcode(db, '123', inventoryId: 1);
      expect(list.length, 2);
      expect(list.first.price, 12.0); // Latest first

      final latest = await dao.getLatest(db, '123', inventoryId: 1);
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

    test('package fields round-trip through toMap and fromMap', () async {
      final db = await dbHelper.database;
      const packaged = Price(
        barcode: '123',
        price: 9.99,
        packageQuantity: 12,
        packageUnit: 'pieces',
      );
      final id = await dao.insert(db, packaged);
      final fetched = await dao.getById(db, id);
      expect(fetched, isNotNull);
      expect(fetched!.packageQuantity, 12);
      expect(fetched.packageUnit, 'pieces');

      final nulled = packaged.copyWith(
        packageQuantity: null,
        packageUnit: null,
      );
      await dao.update(db, nulled.copyWith(id: id));
      final refetched = await dao.getById(db, id);
      expect(refetched!.packageQuantity, isNull);
      expect(refetched.packageUnit, isNull);
    });
  });

  group('PriceDao inventory scoping', () {
    /// Creates a second inventory (id 2) so inventory-scoped rows satisfy the
    /// runtime-enforced FK to inventories(id).
    Future<void> seedInventory2(Database db) async {
      await dbHelper.inventoriesDao.create(db, 'Work');
    }

    test('toMap and fromMap round-trip inventory_id', () async {
      final db = await dbHelper.database;
      await seedInventory2(db);
      const scoped = Price(
        barcode: '123',
        price: 10.5,
        inventoryId: 2,
      );
      final id = await dao.insert(db, scoped);
      final fetched = await dao.getById(db, id);
      expect(fetched, isNotNull);
      expect(fetched!.inventoryId, 2);
    });

    test('listByBarcode filters by inventory', () async {
      final db = await dbHelper.database;
      await seedInventory2(db);
      await dao.insert(
        db,
        const Price(barcode: '123', price: 10),
      );
      await dao.insert(
        db,
        const Price(barcode: '123', price: 20, inventoryId: 2),
      );

      final inv1 = await dao.listByBarcode(db, '123', inventoryId: 1);
      final inv2 = await dao.listByBarcode(db, '123', inventoryId: 2);
      expect(inv1, hasLength(1));
      expect(inv1.first.price, 10);
      expect(inv2, hasLength(1));
      expect(inv2.first.price, 20);
    });

    test('getLatest filters by inventory', () async {
      final db = await dbHelper.database;
      await seedInventory2(db);
      await dao.insert(
        db,
        const Price(
          barcode: '123',
          price: 10,
          datePurchased: 100,
        ),
      );
      await dao.insert(
        db,
        const Price(
          barcode: '123',
          price: 99,
          inventoryId: 2,
          datePurchased: 200,
        ),
      );

      final inv1 = await dao.getLatest(db, '123', inventoryId: 1);
      final inv2 = await dao.getLatest(db, '123', inventoryId: 2);
      expect(inv1!.price, 10);
      expect(inv2!.price, 99);
    });

    test('listByBarcode limit returns the last N by date desc', () async {
      final db = await dbHelper.database;
      for (var i = 1; i <= 7; i++) {
        await dao.insert(
          db,
          Price(
            barcode: '123',
            price: i.toDouble(),
            datePurchased: i * 1000,
          ),
        );
      }

      final recent = await dao.listByBarcode(
        db,
        '123',
        inventoryId: 1,
        limit: 5,
      );
      expect(recent, hasLength(5));
      expect(recent.first.price, 7);
      expect(recent.last.price, 3);
    });

    test('update preserves the existing inventory_id', () async {
      final db = await dbHelper.database;
      await seedInventory2(db);
      const scoped = Price(
        barcode: '123',
        price: 10,
        inventoryId: 2,
      );
      final id = await dao.insert(db, scoped);

      // Caller passes a price that forgot to set inventoryId (defaults to 1).
      final edit = Price(
        barcode: '123',
        price: 15,
        id: id,
      );
      await dao.update(db, edit);

      final fetched = await dao.getById(db, id);
      expect(fetched!.price, 15);
      expect(fetched.inventoryId, 2);
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

    test('totalInventoryValue scales by inventory quantity', () async {
      final db = await dbHelper.database;
      final p1Rows = await inventoryDao.listByBarcode(db, 'p1', inventoryId: 1);
      await inventoryDao.update(db, p1Rows.first.copyWith(quantity: 3));

      // Latest prices p1=10, p2=20; p1 held 3 units => 10*3 + 20*1.
      expect(await dao.totalInventoryValue(db, 1), 50.0);
    });

    test('averageItemPrice is weighted by inventory quantity', () async {
      final db = await dbHelper.database;
      final p1Rows = await inventoryDao.listByBarcode(db, 'p1', inventoryId: 1);
      await inventoryDao.update(db, p1Rows.first.copyWith(quantity: 3));

      // Quantity-weighted average (10*3 + 20*1) / (3 + 1).
      expect(await dao.averageItemPrice(db, 1), 12.5);
    });

    test('stats ignore prices recorded in other inventories', () async {
      final db = await dbHelper.database;
      await dbHelper.inventoriesDao.create(db, 'Work');

      // p1 already has prices in inventory 1 (latest 10 @ 200). Record a
      // higher price in inventory 2 with a LATER date — without scoping the
      // "latest per barcode" subquery would wrongly pick it up.
      await dao.insert(
        db,
        const Price(
          barcode: 'p1',
          price: 50,
          datePurchased: 300,
          inventoryId: 2,
        ),
      );

      // Inventory 1 stats must only reflect its own prices (p1: 10, p2: 20).
      expect(await dao.totalInventoryValue(db, 1), 30.0);
      expect(await dao.averageItemPrice(db, 1), 15.0);
      expect(await dao.pricedItemCount(db, 1), 2);
    });
  });

  group('PriceDao latest-price tie handling', () {
    test('same-day duplicate purchases are not double-counted', () async {
      final db = await dbHelper.database;
      const productDao = ProductDao();
      await productDao.insert(
        db,
        const Product(barcode: 'tie1', name: 'Tie Product'),
      );
      await inventoryDao.insert(
        db,
        const InventoryItem(barcode: 'tie1', quantity: 2),
      );

      // Two purchases on the same day (identical date_purchased) with
      // different prices. The latest row (highest id) must win: 20 * 2.
      await dao.insert(
        db,
        const Price(barcode: 'tie1', price: 10, datePurchased: 1000),
      );
      await dao.insert(
        db,
        const Price(barcode: 'tie1', price: 20, datePurchased: 1000),
      );

      expect(await dao.totalInventoryValue(db, 1), 40.0);
      expect(await dao.averageItemPrice(db, 1), 20.0);

      final byCurrency = await dao.totalInventoryValueByCurrency(db, 1);
      expect(byCurrency, hasLength(1));
      expect((byCurrency.first['subtotal'] as num).toDouble(), 40.0);

      final latest = await dao.latestPricesWithCurrency(db, 1);
      expect(latest, hasLength(1));
      expect((latest.first['price'] as num).toDouble(), 20.0);
    });

    test('monthlyExpenditure counts same-day duplicates once', () async {
      final db = await dbHelper.database;
      const productDao = ProductDao();
      await productDao.insert(
        db,
        const Product(barcode: 'tie2', name: 'Tie Monthly'),
      );
      await inventoryDao.insert(
        db,
        const InventoryItem(barcode: 'tie2'),
      );
      final sameDay = DateTime(2026, 6, 15).millisecondsSinceEpoch;
      await dao.insert(
        db,
        Price(barcode: 'tie2', price: 10, datePurchased: sameDay),
      );
      await dao.insert(
        db,
        Price(barcode: 'tie2', price: 30, datePurchased: sameDay),
      );

      final rows = await dao.monthlyExpenditure(db, inventoryId: 1);
      expect(rows, hasLength(1));
      expect(rows.first['month'], '2026-06');
      expect((rows.first['total'] as num).toDouble(), 30.0);
    });

    test('storeSpending counts same-day duplicates once', () async {
      final db = await dbHelper.database;
      const productDao = ProductDao();
      await productDao.insert(
        db,
        const Product(barcode: 'tie3', name: 'Tie Store'),
      );
      await inventoryDao.insert(
        db,
        const InventoryItem(barcode: 'tie3'),
      );
      final sameDay = DateTime(2026, 6, 15).millisecondsSinceEpoch;
      await dao.insert(
        db,
        Price(
          barcode: 'tie3',
          price: 10,
          store: 'Corner Shop',
          datePurchased: sameDay,
        ),
      );
      await dao.insert(
        db,
        Price(
          barcode: 'tie3',
          price: 30,
          store: 'Corner Shop',
          datePurchased: sameDay,
        ),
      );

      final rows = await dao.storeSpending(db, inventoryId: 1);
      expect(rows, hasLength(1));
      expect(rows.first['store'], 'Corner Shop');
      expect((rows.first['total'] as num).toDouble(), 30.0);
    });
  });

  group('PriceDao monthly and store spending scale by quantity', () {
    setUp(() async {
      final db = await dbHelper.database;
      const productDao = ProductDao();

      await productDao.insert(
        db,
        const Product(barcode: 'm1', name: 'Monthly 1'),
      );
      await productDao.insert(
        db,
        const Product(barcode: 's1', name: 'Store 1'),
      );

      // m1 held 2 units at a price of 10 in June 2026.
      await inventoryDao.insert(
        db,
        const InventoryItem(barcode: 'm1', quantity: 2),
      );
      await dao.insert(
        db,
        Price(
          barcode: 'm1',
          price: 10,
          datePurchased: DateTime(2026, 6, 15).millisecondsSinceEpoch,
        ),
      );

      // s1 held 4 units at a price of 5 in store "Big Box".
      await inventoryDao.insert(
        db,
        const InventoryItem(barcode: 's1', quantity: 4),
      );
      await dao.insert(
        db,
        Price(
          barcode: 's1',
          price: 5,
          store: 'Big Box',
          datePurchased: DateTime(2026, 6, 20).millisecondsSinceEpoch,
        ),
      );
    });

    test(
      'monthlyExpenditure multiplies the latest price by quantity',
      () async {
        final db = await dbHelper.database;
        final rows = await dao.monthlyExpenditure(db, inventoryId: 1);

        expect(rows, hasLength(1));
        expect(rows.first['month'], '2026-06');
        // 10 * 2 + 5 * 4 = 40.
        expect((rows.first['total'] as num).toDouble(), 40.0);
      },
    );

    test('storeSpending multiplies the latest price by quantity', () async {
      final db = await dbHelper.database;
      final rows = await dao.storeSpending(db, inventoryId: 1);

      expect(rows, hasLength(1));
      expect(rows.first['store'], 'Big Box');
      // 5 * 4 = 20.
      expect((rows.first['total'] as num).toDouble(), 20.0);
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
      expect(await dao.getLatest(db, '2', inventoryId: 1), isNotNull);
      expect(await dao.getLatest(db, '1', inventoryId: 1), isNull);
    });
  });
}
