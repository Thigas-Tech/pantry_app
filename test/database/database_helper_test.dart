import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests for [DatabaseHelper] using an in‑memory SQLite database.
///
/// Each test runs against a fresh database created with
/// [DatabaseHelper.withPath]. The schema is version 2, which
/// includes the `inventories` table and the `inventory_id` column.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper db;

  setUp(() async {
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    await db.database;
  });

  tearDown(() async {
    final database = await db.database;
    await database.close();
  });

  group('Product CRUD', () {
    const product = Product(barcode: '123', name: 'Test', energyKcal: 100);

    test('insert and getProduct', () async {
      await db.insertProduct(product);
      final fetched = await db.getProduct('123');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Test');
      expect(fetched.energyKcal, 100);
    });

    test('upsert replaces existing', () async {
      await db.insertProduct(product);
      final updated = product.copyWith(name: 'Updated');
      await db.insertProduct(updated);
      final fetched = await db.getProduct('123');
      expect(fetched!.name, 'Updated');
    });

    test('getProduct returns null for missing barcode', () async {
      final result = await db.getProduct('nonexistent');
      expect(result, isNull);
    });
  });

  group('Inventories CRUD', () {
    test('createInventory and getInventories', () async {
      await db.createInventory('Work');
      await db.createInventory('Camping');
      final list = await db.getInventories();
      expect(list.length, 3);
      expect(
        list.map((e) => e['name']),
        containsAll(['Home', 'Work', 'Camping']),
      );
    });

    test('renameInventory changes the name', () async {
      final id = await db.createInventory('Old');
      await db.renameInventory(id, 'New');
      final list = await db.getInventories();
      final renamed = list.firstWhere((e) => e['id'] == id);
      expect(renamed['name'], 'New');
    });

    test('deleteInventory removes the inventory and its items', () async {
      final id = await db.createInventory('Temp');
      await db.insertProduct(const Product(barcode: 'p1', name: 'P1'));
      await db.insertInventoryItem(
        InventoryItem(barcode: 'p1', inventoryId: id),
      );
      // Item in the default Home inventory (no explicit inventoryId needed).
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'p1'),
      );

      await db.deleteInventory(id);

      final list = await db.getInventories();
      expect(list.any((e) => e['id'] == id), isFalse);

      final items = await db.getInventoryItems(inventoryId: 1);
      expect(items.length, 1);

      final tempItems = await db.getInventoryItems(inventoryId: id);
      expect(tempItems, isEmpty);
    });
  });

  group('Inventory Item CRUD', () {
    const product = Product(barcode: '123', name: 'Test');

    setUp(() async {
      await db.insertProduct(product);
    });

    test('insert and retrieve inventory items', () async {
      const item = InventoryItem(
        barcode: '123',
        quantity: 2,
        unit: 'kg',
      );
      final id = await db.insertInventoryItem(item);
      expect(id, greaterThan(0));

      final items = await db.getInventoryItems(inventoryId: 1);
      expect(items.length, 1);
      expect(items.first.quantity, 2);
    });

    test('getInventoryItemsByBarcode filters correctly', () async {
      final workId = await db.createInventory('Work');
      await db.insertInventoryItem(
        const InventoryItem(barcode: '123'),
      );
      await db.insertInventoryItem(
        InventoryItem(barcode: '123', quantity: 3, inventoryId: workId),
      );

      final homeItems = await db.getInventoryItemsByBarcode(
        '123',
        inventoryId: 1,
      );
      final workItems = await db.getInventoryItemsByBarcode(
        '123',
        inventoryId: workId,
      );
      expect(homeItems.length, 1);
      expect(workItems.length, 1);
      expect(workItems.first.quantity, 3);
    });

    test('updateInventoryItem modifies existing', () async {
      const item = InventoryItem(barcode: '123');
      final id = await db.insertInventoryItem(item);
      final updated = item.copyWith(id: id, quantity: 5);
      await db.updateInventoryItem(updated);
      final items = await db.getInventoryItems(inventoryId: 1);
      expect(items.first.quantity, 5);
    });

    test('deleteInventoryItem removes item', () async {
      final id = await db.insertInventoryItem(
        const InventoryItem(barcode: '123'),
      );
      await db.deleteInventoryItem(id);
      final items = await db.getInventoryItems(inventoryId: 1);
      expect(items, isEmpty);
    });
  });

  group('cleanupOldEntries', () {
    test(
      'removes items older than retention days and orphaned products',
      () async {
        await db.insertProduct(const Product(barcode: 'p1', name: 'P1'));
        final oldItem = InventoryItem(
          barcode: 'p1',
          dateAdded: DateTime.now()
              .subtract(const Duration(days: 70))
              .millisecondsSinceEpoch,
        );
        final newItem = InventoryItem(
          barcode: 'p1',
          dateAdded: DateTime.now()
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
        );
        await db.insertInventoryItem(oldItem);
        await db.insertInventoryItem(newItem);

        await db.cleanupOldEntries();

        final remaining = await db.getInventoryItems(inventoryId: 1);
        expect(remaining.length, 1);
        expect(remaining.first.dateAdded, newItem.dateAdded);

        final product = await db.getProduct('p1');
        expect(product, isNotNull);
      },
    );

    test('removes orphaned product after all items are cleaned', () async {
      await db.insertProduct(const Product(barcode: 'p2', name: 'P2'));
      await db.insertInventoryItem(
        InventoryItem(
          barcode: 'p2',
          dateAdded: DateTime.now()
              .subtract(const Duration(days: 70))
              .millisecondsSinceEpoch,
        ),
      );

      await db.cleanupOldEntries();

      final product = await db.getProduct('p2');
      expect(product, isNull);
    });
  });

  group('getInventoryWithProduct', () {
    test('returns joined data with inventory name', () async {
      await db.insertProduct(
        const Product(barcode: 'p1', name: 'Prod1', imageUrl: 'img'),
      );
      await db.insertInventoryItem(
        const InventoryItem(
          barcode: 'p1',
          quantity: 3,
          unit: 'kg',
          expiryDate: '2026-01-01',
        ),
      );

      final rows = await db.getInventoryWithProduct(inventoryId: 1);
      expect(rows.length, 1);
      expect(rows.first['product_name'], 'Prod1');
      expect(rows.first['product_image_url'], 'img');
      expect(rows.first['quantity'], 3);
      expect(rows.first['inventory_name'], 'Home');
    });
  });

  group('counts', () {
    test('getProductCount and getInventoryCount', () async {
      await db.insertProduct(const Product(barcode: 'a', name: 'A'));
      await db.insertProduct(const Product(barcode: 'b', name: 'B'));
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'a'),
      );

      expect(await db.getProductCount(), 2);
      expect(await db.getInventoryCount(), 1);
      expect(await db.getInventoryCount(inventoryId: 1), 1);
    });
  });

  group('getExportData', () {
    test('returns export data scoped to inventory', () async {
      /// Export data includes product nutrition, brand, category, and
      /// inventory name.
      final workId = await db.createInventory('Work');
      await db.insertProduct(
        const Product(
          barcode: 'p1',
          name: 'Prod1',
          brand: 'Brand1',
          category: 'Cat1',
          energyKcal: 100,
        ),
      );
      await db.insertInventoryItem(
        InventoryItem(
          barcode: 'p1',
          quantity: 5,
          expiryDate: '2026-06-01',
          location: 'fridge',
          notes: 'note',
          dateAdded: 123456789,
          inventoryId: workId, // place it in the Work inventory
        ),
      );

      final rows = await db.getExportData(inventoryId: workId);
      expect(rows.length, 1);
      expect(rows.first['product_name'], 'Prod1');
      expect(rows.first['brand'], 'Brand1');
      expect(rows.first['category'], 'Cat1');
      expect(rows.first['barcode'], 'p1');
      expect(rows.first['quantity'], 5);
      expect(rows.first['unit'], 'pcs');
      expect(rows.first['expiry_date'], '2026-06-01');
      expect(rows.first['location'], 'fridge');
      expect(rows.first['notes'], 'note');
      expect(rows.first['date_added'], 123456789);
      expect(rows.first['energy_kcal'], 100);
      expect(rows.first['inventory_name'], 'Work');
    });
  });
}
