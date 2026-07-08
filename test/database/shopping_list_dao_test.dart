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
}
