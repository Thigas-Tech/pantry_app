import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration tests for [DatabaseHelper.clearCachedProducts] and the
/// LEFT JOIN fix that prevents inventory items from disappearing after
/// a cache flush.
///
/// Every test runs against a fresh in‑memory database at schema version 8.
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

  group('clearCachedProducts — LEFT JOIN regression guard', () {
    test('inventory items survive cache flush (LEFT JOIN)', () async {
      // Insert 2 API products and 1 manual product.
      await db.insertProduct(
        const Product(barcode: 'api1', name: 'API One', brand: 'BrandA'),
      );
      await db.insertProduct(
        const Product(barcode: 'api2', name: 'API Two', brand: 'BrandB'),
      );
      await db.insertProduct(
        const Product(barcode: 'manual1', name: 'Manual One', source: 'manual'),
      );
      expect(await db.getProductCount(), 3);

      // Insert inventory items referencing all three.
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'api1'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'api2'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'manual1'),
      );
      expect(await db.getInventoryCount(inventoryId: 1), 3);

      // 1. Before flush: INNER JOIN returns all items.
      var rows = await db.getInventoryWithProduct(inventoryId: 1);
      expect(rows.length, 3, reason: 'all items visible before flush');
      final names = rows.map((r) => r['product_name'] as String).toSet();
      expect(names, containsAll(['API One', 'API Two', 'Manual One']));

      // 2. Flush clears only API products.
      await db.clearCachedProducts();
      expect(
        await db.getProductCount(),
        1,
        reason: 'only manual product survives',
      );
      expect(await db.getProduct('api1'), isNull);
      expect(await db.getProduct('api2'), isNull);
      expect(await db.getProduct('manual1'), isNotNull);

      // 3. After flush: LEFT JOIN returns all 3 items (API ones have null
      //    product_name). This is the regression guard.
      rows = await db.getInventoryWithProduct(inventoryId: 1);
      expect(
        rows.length,
        3,
        reason:
            'LEFT JOIN must return all 3 items even though 2 products are gone',
      );
      expect(rows[0]['product_name'], anyOf(isNull, 'Manual One'));
      // Count non-null product names (only manual1 still has one).
      final nonNullNames = rows.where((r) => r['product_name'] != null).length;
      expect(nonNullNames, 1, reason: 'only manual1 still has a product_name');
    });

    test('clearCachedProducts preserves manual products', () async {
      await db.insertProduct(
        const Product(barcode: 'a', name: 'A'),
      );
      await db.insertProduct(
        const Product(barcode: 'm', name: 'M', source: 'manual'),
      );
      await db.clearCachedProducts();
      expect(await db.getProduct('a'), isNull);
      expect((await db.getProduct('m'))!.name, 'M');
      expect(await db.getProductCount(), 1);
    });
  });

  group('re-fetch after flush (simulating refreshInventoryProducts)', () {
    test('re-inserting a product restores it in the join', () async {
      await db.insertProduct(
        const Product(barcode: 'a', name: 'A'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'a'),
      );

      // Flush.
      await db.clearCachedProducts();

      // Re-insert simulating API re-fetch.
      await db.insertProduct(
        const Product(barcode: 'a', name: 'A (refreshed)'),
      );

      final rows = await db.getInventoryWithProduct(inventoryId: 1);
      expect(rows.length, 1);
      expect(rows.first['product_name'], 'A (refreshed)');
    });
  });
}
