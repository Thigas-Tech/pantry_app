import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late ShoppingListDao dao;

  setUp(() async {
    dao = const ShoppingListDao();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await dao.createTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ShoppingListDao', () {
    test('createTable creates the table', () async {
      final id = await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', quantity: 2),
      );
      expect(id, isNonNegative);
    });

    test('insert and listAll', () async {
      await dao.insert(db, const ShoppingItem(name: 'Eggs'));
      await dao.insert(db, const ShoppingItem(name: 'Bread'));

      final items = await dao.listAll(db);
      expect(items.length, 2);
      expect(items.map((e) => e.name), containsAll(['Eggs', 'Bread']));
    });

    test('listPending returns only non-purchased items', () async {
      final id = await dao.insert(db, const ShoppingItem(name: 'Milk'));
      await dao.insert(db, const ShoppingItem(name: 'Eggs'));
      await dao.togglePurchased(db, id);

      final pending = await dao.listPending(db);
      expect(pending.length, 1);
      expect(pending[0].name, 'Eggs');
    });

    test('listPurchased returns only purchased items', () async {
      final id = await dao.insert(db, const ShoppingItem(name: 'Milk'));
      await dao.insert(db, const ShoppingItem(name: 'Eggs'));
      await dao.togglePurchased(db, id);

      final purchased = await dao.listPurchased(db);
      expect(purchased.length, 1);
      expect(purchased[0].name, 'Milk');
    });

    test('togglePurchased marks as purchased', () async {
      final id = await dao.insert(db, const ShoppingItem(name: 'Milk'));
      await dao.togglePurchased(db, id);

      final item = await dao.getById(db, id);
      expect(item!.isPurchased, true);
      expect(item.datePurchased, isNotNull);
    });

    test('togglePurchased unmarks when already purchased', () async {
      final id = await dao.insert(db, const ShoppingItem(name: 'Milk'));
      await dao.togglePurchased(db, id);
      await dao.togglePurchased(db, id);

      final item = await dao.getById(db, id);
      expect(item!.isPurchased, false);
      expect(item.datePurchased, isNull);
    });

    test('update modifies fields', () async {
      final id = await dao.insert(db, const ShoppingItem(name: 'Milk'));
      await dao.update(db, const ShoppingItem(name: 'Almond Milk', id: 1));

      final item = await dao.getById(db, id);
      expect(item!.name, 'Almond Milk');
    });

    test('delete removes item', () async {
      final id = await dao.insert(db, const ShoppingItem(name: 'Milk'));
      await dao.delete(db, id);

      final items = await dao.listAll(db);
      expect(items, isEmpty);
    });

    test('clearPurchased removes only purchased items', () async {
      await dao.insert(db, const ShoppingItem(name: 'Milk'));
      final id = await dao.insert(db, const ShoppingItem(name: 'Eggs'));
      await dao.togglePurchased(db, id);

      await dao.clearPurchased(db);

      final items = await dao.listAll(db);
      expect(items.length, 1);
      expect(items[0].name, 'Milk');
    });

    test('markPurchasedByBarcode marks matching items', () async {
      await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123'),
      );
      await dao.insert(
        db,
        const ShoppingItem(name: 'Other Milk', barcode: '123'),
      );
      await dao.insert(
        db,
        const ShoppingItem(name: 'Bread', barcode: '456'),
      );

      final affected = await dao.markPurchasedByBarcode(db, '123');
      expect(affected, 2);

      final pending = await dao.listPending(db);
      expect(pending.length, 1);
      expect(pending[0].barcode, '456');
    });

    test('markPurchasedByBarcode ignores already purchased items', () async {
      final id = await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123'),
      );
      await dao.togglePurchased(db, id);

      final affected = await dao.markPurchasedByBarcode(db, '123');
      expect(affected, 0);
    });

    test('pendingCount returns correct count', () async {
      await dao.insert(db, const ShoppingItem(name: 'Milk'));
      final id = await dao.insert(db, const ShoppingItem(name: 'Eggs'));
      await dao.togglePurchased(db, id);

      final count = await dao.pendingCount(db);
      expect(count, 1);
    });

    test('getById returns null for non-existent id', () async {
      final item = await dao.getById(db, 999);
      expect(item, isNull);
    });
  });

  group('inventory-scoped queries', () {
    test('listAll filters by inventoryId', () async {
      await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', inventoryId: 1),
      );
      await dao.insert(
        db,
        const ShoppingItem(name: 'Bread', inventoryId: 2),
      );

      final inv1 = await dao.listAll(db, inventoryId: 1);
      expect(inv1.length, 1);
      expect(inv1[0].name, 'Milk');

      final inv2 = await dao.listAll(db, inventoryId: 2);
      expect(inv2.length, 1);
      expect(inv2[0].name, 'Bread');
    });

    test('listPending filters by inventoryId', () async {
      final id1 = await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', inventoryId: 1),
      );
      await dao.insert(
        db,
        const ShoppingItem(name: 'Bread', inventoryId: 2),
      );
      await dao.togglePurchased(db, id1);

      final pendingInv1 = await dao.listPending(db, inventoryId: 1);
      expect(pendingInv1, isEmpty);

      final pendingInv2 = await dao.listPending(db, inventoryId: 2);
      expect(pendingInv2.length, 1);
      expect(pendingInv2[0].name, 'Bread');
    });

    test('listPurchased filters by inventoryId', () async {
      final id1 = await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', inventoryId: 1),
      );
      await dao.insert(
        db,
        const ShoppingItem(name: 'Bread', inventoryId: 2),
      );
      await dao.togglePurchased(db, id1);

      final purchasedInv1 = await dao.listPurchased(db, inventoryId: 1);
      expect(purchasedInv1.length, 1);
      expect(purchasedInv1[0].name, 'Milk');

      final purchasedInv2 = await dao.listPurchased(db, inventoryId: 2);
      expect(purchasedInv2, isEmpty);
    });

    test('pendingCount filters by inventoryId', () async {
      await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', inventoryId: 1),
      );
      await dao.insert(
        db,
        const ShoppingItem(name: 'Bread', inventoryId: 2),
      );

      final count1 = await dao.pendingCount(db, inventoryId: 1);
      expect(count1, 1);

      final count2 = await dao.pendingCount(db, inventoryId: 2);
      expect(count2, 1);

      final countAll = await dao.pendingCount(db);
      expect(countAll, 2);
    });
  });

  group('price fields', () {
    test('persists price fields on insert', () async {
      final id = await dao.insert(
        db,
        const ShoppingItem(
          name: 'Milk',
          priceAmount: 2.99,
          priceCurrency: 'USD',
          priceStore: 'Kroger',
        ),
      );

      final item = await dao.getById(db, id);
      expect(item!.priceAmount, 2.99);
      expect(item.priceCurrency, 'USD');
      expect(item.priceStore, 'Kroger');
    });

    test('price fields survive toggle purchased', () async {
      final id = await dao.insert(
        db,
        const ShoppingItem(
          name: 'Bread',
          priceAmount: 1.50,
          priceCurrency: 'BRL',
          priceStore: 'Pao de Acucar',
        ),
      );

      await dao.togglePurchased(db, id);

      final item = await dao.getById(db, id);
      expect(item!.isPurchased, true);
      expect(item.priceAmount, 1.50);
      expect(item.priceCurrency, 'BRL');
      expect(item.priceStore, 'Pao de Acucar');
    });

    test('updatePriceFields changes only price columns', () async {
      final id = await dao.insert(
        db,
        const ShoppingItem(name: 'Eggs', quantity: 6),
      );

      await dao.updatePriceFields(
        db,
        id,
        priceAmount: 3,
        priceCurrency: 'EUR',
        priceStore: 'Aldi',
      );

      final item = await dao.getById(db, id);
      expect(item!.name, 'Eggs');
      expect(item.quantity, 6.0);
      expect(item.isPurchased, false);
      expect(item.priceAmount, 3.00);
      expect(item.priceCurrency, 'EUR');
      expect(item.priceStore, 'Aldi');
    });

    test('updatePriceFields clears price fields when null', () async {
      final id = await dao.insert(
        db,
        const ShoppingItem(
          name: 'Juice',
          priceAmount: 4.50,
          priceCurrency: 'USD',
          priceStore: 'Walmart',
        ),
      );

      await dao.updatePriceFields(db, id);

      final item = await dao.getById(db, id);
      expect(item!.priceAmount, isNull);
      expect(item.priceCurrency, isNull);
      expect(item.priceStore, isNull);
    });

    test('listPending includes price fields from DB', () async {
      await dao.insert(
        db,
        const ShoppingItem(
          name: 'Butter',
          priceAmount: 2,
          priceCurrency: 'USD',
        ),
      );

      final items = await dao.listPending(db);
      expect(items.length, 1);
      expect(items[0].priceAmount, 2.00);
      expect(items[0].priceCurrency, 'USD');
    });
  });

  group('insertOrMergeByBarcode inventory scoping', () {
    test('merges within same inventory', () async {
      await dao.insertOrMergeByBarcode(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123', inventoryId: 1),
      );
      await dao.insertOrMergeByBarcode(
        db,
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          quantity: 3,
          inventoryId: 1,
        ),
      );

      final inv1 = await dao.listPending(db, inventoryId: 1);
      expect(inv1.length, 1);
      expect(inv1[0].quantity, 4.0);
    });

    test('does not merge across different inventories', () async {
      await dao.insertOrMergeByBarcode(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123', inventoryId: 1),
      );
      await dao.insertOrMergeByBarcode(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123', inventoryId: 2),
      );

      final inv1 = await dao.listPending(db, inventoryId: 1);
      final inv2 = await dao.listPending(db, inventoryId: 2);
      expect(inv1.length, 1);
      expect(inv2.length, 1);
      expect(inv1[0].inventoryId, 1);
      expect(inv2[0].inventoryId, 2);
    });

    test('with null inventoryId merges across all (backward compat)', () async {
      await dao.insertOrMergeByBarcode(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123'),
      );
      await dao.insertOrMergeByBarcode(
        db,
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          quantity: 2,
        ),
      );

      final all = await dao.listAll(db);
      expect(all.length, 1);
      expect(all[0].quantity, 3.0);
    });
  });

  group('clearPurchased inventory scoping', () {
    test('scoped only deletes items from the given inventory', () async {
      await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', inventoryId: 1),
      );
      final milkId = await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', inventoryId: 2),
      );
      await dao.togglePurchased(db, milkId);

      await dao.clearPurchased(db, inventoryId: 2);

      final inv1 = await dao.listAll(db, inventoryId: 1);
      final inv2 = await dao.listAll(db, inventoryId: 2);
      expect(inv1.length, 1);
      expect(inv2, isEmpty);
    });

    test('without inventoryId clears all (backward compat)', () async {
      final id1 = await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', inventoryId: 1),
      );
      final id2 = await dao.insert(
        db,
        const ShoppingItem(name: 'Bread', inventoryId: 2),
      );
      await dao.togglePurchased(db, id1);
      await dao.togglePurchased(db, id2);

      await dao.clearPurchased(db);

      final all = await dao.listAll(db);
      expect(all, isEmpty);
    });
  });

  group('markPurchasedByBarcode inventory scoping', () {
    test('scoped only marks items from the given inventory', () async {
      await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123', inventoryId: 1),
      );
      await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123', inventoryId: 2),
      );

      await dao.markPurchasedByBarcode(db, '123', inventoryId: 1);

      final pendingInv1 = await dao.listPending(db, inventoryId: 1);
      final pendingInv2 = await dao.listPending(db, inventoryId: 2);
      expect(pendingInv1, isEmpty);
      expect(pendingInv2.length, 1);
      expect(pendingInv2[0].inventoryId, 2);
    });

    test('without inventoryId marks across all (backward compat)', () async {
      await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123', inventoryId: 1),
      );
      await dao.insert(
        db,
        const ShoppingItem(name: 'Milk', barcode: '123', inventoryId: 2),
      );

      await dao.markPurchasedByBarcode(db, '123');

      final pendingInv1 = await dao.listPending(db, inventoryId: 1);
      final pendingInv2 = await dao.listPending(db, inventoryId: 2);
      expect(pendingInv1, isEmpty);
      expect(pendingInv2, isEmpty);
    });

    group('insertOrMergeByBarcode FK fallback', () {
      setUp(() async {
        // Create referenced tables so FK constraints are enforceable.
        await db.execute('''
          CREATE TABLE IF NOT EXISTS products (
            barcode TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            source TEXT NOT NULL DEFAULT 'api'
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS inventories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('PRAGMA foreign_keys = ON');
      });

      test('insert with valid barcode and existing product succeeds', () async {
        await db.insert('products', {
          'barcode': '001',
          'name': 'Existing Product',
          'source': 'api',
        });

        final id = await dao.insertOrMergeByBarcode(
          db,
          const ShoppingItem(
            name: 'Test',
            barcode: '001',
          ),
        );

        expect(id, isNonNegative);
        final items = await dao.listAll(db);
        expect(items.length, 1);
        expect(items.first.barcode, '001');
      });

      test(
        'insert with barcode missing from products table falls back to null',
        () async {
          // Do NOT insert the product row — FK will fail.
          final id = await dao.insertOrMergeByBarcode(
            db,
            const ShoppingItem(
              name: 'Orphan',
              barcode: '999',
            ),
          );

          expect(id, isNonNegative);
          final items = await dao.listAll(db);
          expect(items.length, 1);
          expect(items.first.barcode, isNull);
          expect(items.first.name, 'Orphan');
        },
      );

      test('merge path still works after FK fallback', () async {
        await db.insert('products', {
          'barcode': '001',
          'name': 'Existing',
          'source': 'api',
        });

        // First insert (will succeed via FK)
        await dao.insertOrMergeByBarcode(
          db,
          const ShoppingItem(
            name: 'Item',
            barcode: '001',
          ),
        );

        // Delete the product row to simulate cache flush.
        await db.delete('products', where: 'barcode = ?', whereArgs: ['001']);

        // Second insert — FK fails, should fall back to null barcode.
        final id = await dao.insertOrMergeByBarcode(
          db,
          const ShoppingItem(
            name: 'Item',
            barcode: '001',
            quantity: 2,
          ),
        );

        expect(id, isNonNegative);
        // Should NOT merge because barcode was nulled.
        final items = await dao.listAll(db);
        expect(items.length, 2);
        // The second item should have null barcode.
        final newest = items.first;
        expect(newest.barcode, isNull);
        expect(newest.quantity, 2);
      });
    });
  });

  group('sort_order', () {
    test('pending items ordered by sort_order ascending', () async {
      final a = await dao.insert(db, const ShoppingItem(name: 'A'));
      final b = await dao.insert(db, const ShoppingItem(name: 'B'));
      final c = await dao.insert(db, const ShoppingItem(name: 'C'));

      await dao.reorder(db, [c, a, b]);

      final pending = await dao.listPending(db);
      expect(pending.map((e) => e.name).toList(), ['C', 'A', 'B']);
      expect(pending.map((e) => e.id).toList(), [c, a, b]);
    });

    test('reorder applies atomically and persists', () async {
      final a = await dao.insert(db, const ShoppingItem(name: 'A'));
      final b = await dao.insert(db, const ShoppingItem(name: 'B'));

      await dao.reorder(db, [b, a]);

      final items = await dao.listAll(db);
      expect(items.map((e) => e.name).toList(), ['B', 'A']);
      expect(items.first.sortOrder, 1);
      expect(items.last.sortOrder, 2);
    });

    test('listPending falls back to date_added tie-break', () async {
      final a = await dao.insert(
        db,
        const ShoppingItem(name: 'A', dateAdded: 100),
      );
      final b = await dao.insert(
        db,
        const ShoppingItem(name: 'B', dateAdded: 200),
      );

      // Both at sort_order 0 -> newer date first.
      final pending = await dao.listPending(db);
      expect(pending.map((e) => e.name).toList(), ['B', 'A']);
      expect(pending.map((e) => e.id).toList(), [b, a]);
    });
  });
}
