/// Tests for [DatabaseHelper] – product/inventory CRUD, cleanup, and
/// joined queries.
///
/// Each test runs against an isolated in‑memory database created with
/// [DatabaseHelper.withPath]. Tables are created in `setUp` and the
/// database is closed in `tearDown` so that every test starts fresh.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper db;

  setUp(() async {
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    await db.database; // force schema creation
  });

  tearDown(() async {
    final database = await db.database;
    await database.close();
  });

  group('Product CRUD', () {
    const product = Product(barcode: '123', name: 'Test', energyKcal: 100);

    test('insert and getProduct', () async {
      /// Verifies that a product can be inserted and then retrieved
      /// by its barcode.
      await db.insertProduct(product);
      final fetched = await db.getProduct('123');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Test');
      expect(fetched.energyKcal, 100);
    });

    test('upsert replaces existing', () async {
      /// Ensures that inserting a product with the same barcode replaces
      /// the previous row (upsert behaviour).
      await db.insertProduct(product);
      final updated = product.copyWith(name: 'Updated');
      await db.insertProduct(updated);
      final fetched = await db.getProduct('123');
      expect(fetched!.name, 'Updated');
    });

    test('getProduct returns null for missing barcode', () async {
      /// Non‑existent barcodes should return `null`.
      final result = await db.getProduct('nonexistent');
      expect(result, isNull);
    });
  });

  group('Inventory CRUD', () {
    const product = Product(barcode: '123', name: 'Test');

    setUp(() async {
      // Every inventory test needs the referenced product to exist.
      await db.insertProduct(product);
    });

    test('insert and retrieve inventory items', () async {
      /// An inventory item can be inserted and then appears in the
      /// unfiltered list.
      const item = InventoryItem(barcode: '123', quantity: 2, unit: 'kg');
      final id = await db.insertInventoryItem(item);
      expect(id, greaterThan(0));

      final items = await db.getInventoryItems();
      expect(items.length, 1);
      expect(items.first.quantity, 2);
    });

    test('getInventoryItemsByBarcode filters correctly', () async {
      /// Multiple items with the same barcode are all returned.
      await db.insertInventoryItem(const InventoryItem(barcode: '123'));
      await db.insertInventoryItem(
        const InventoryItem(barcode: '123', quantity: 3),
      );
      final items = await db.getInventoryItemsByBarcode('123');
      expect(items.length, 2);
    });

    test('updateInventoryItem modifies existing', () async {
      /// The `updateInventoryItem` method changes the stored row.
      const item = InventoryItem(barcode: '123');
      final id = await db.insertInventoryItem(item);
      final updated = item.copyWith(id: id, quantity: 5);
      await db.updateInventoryItem(updated);
      final items = await db.getInventoryItems();
      expect(items.first.quantity, 5);
    });

    test('deleteInventoryItem removes item', () async {
      /// Deleted items are no longer returned by `getInventoryItems`.
      final id = await db.insertInventoryItem(
        const InventoryItem(barcode: '123'),
      );
      await db.deleteInventoryItem(id);
      final items = await db.getInventoryItems();
      expect(items, isEmpty);
    });
  });

  group('cleanupOldEntries', () {
    test('removes items older than 60 days and orphaned products', () async {
      /// Items with a `date_added` more than 60 days ago are deleted.
      /// Products that still have at least one recent inventory entry
      /// are kept.
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

      final remaining = await db.getInventoryItems();
      expect(remaining.length, 1);
      expect(remaining.first.dateAdded, newItem.dateAdded);

      final product = await db.getProduct('p1');
      expect(product, isNotNull);
    });

    test('removes orphaned product after all items are cleaned', () async {
      /// When every inventory entry for a product is cleaned up, the
      /// product itself is also removed from the cache.
      await db.insertProduct(const Product(barcode: 'p2', name: 'P2'));
      final oldItem = InventoryItem(
        barcode: 'p2',
        dateAdded: DateTime.now()
            .subtract(const Duration(days: 70))
            .millisecondsSinceEpoch,
      );
      await db.insertInventoryItem(oldItem);

      await db.cleanupOldEntries();

      final product = await db.getProduct('p2');
      expect(product, isNull);
    });
  });

  group('getInventoryWithProduct', () {
    test('returns joined data', () async {
      /// The joined query returns product metadata alongside inventory
      /// columns.
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

      final rows = await db.getInventoryWithProduct();
      expect(rows.length, 1);
      expect(rows.first['product_name'], 'Prod1');
      expect(rows.first['product_image_url'], 'img');
      expect(rows.first['quantity'], 3);
    });
  });

  group('counts', () {
    test('getProductCount and getInventoryCount', () async {
      /// `getProductCount` and `getInventoryCount` return the correct
      /// number of rows.
      await db.insertProduct(const Product(barcode: 'a', name: 'A'));
      await db.insertProduct(const Product(barcode: 'b', name: 'B'));
      await db.insertInventoryItem(const InventoryItem(barcode: 'a'));
      expect(await db.getProductCount(), 2);
      expect(await db.getInventoryCount(), 1);
    });
  });
}
