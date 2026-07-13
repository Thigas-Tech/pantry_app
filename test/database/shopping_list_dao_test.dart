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
          pricePhotoPath: '/photos/1.jpg',
        ),
      );

      final item = await dao.getById(db, id);
      expect(item!.priceAmount, 2.99);
      expect(item.priceCurrency, 'USD');
      expect(item.priceStore, 'Kroger');
      expect(item.pricePhotoPath, '/photos/1.jpg');
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
        pricePhotoPath: '/photos/2.jpg',
      );

      final item = await dao.getById(db, id);
      expect(item!.name, 'Eggs');
      expect(item.quantity, 6.0);
      expect(item.isPurchased, false);
      expect(item.priceAmount, 3.00);
      expect(item.priceCurrency, 'EUR');
      expect(item.priceStore, 'Aldi');
      expect(item.pricePhotoPath, '/photos/2.jpg');
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
}
