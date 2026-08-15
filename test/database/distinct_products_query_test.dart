import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests for [DatabaseHelper.getDistinctProductsFromInventory], the
/// "from your pantry" suggestion query used when adding to a shopping list.
///
/// The query must order distinct products by their most recently added
/// inventory batch. Using ORDER BY on a non-selected column inside a
/// SELECT DISTINCT lets SQLite pick an arbitrary row per group, so the
/// "most recent" ordering is non-deterministic (and was a hard error on the
/// SQLite 3.9.2 bundled with minSdk 24).
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

  group('getDistinctProductsFromInventory', () {
    test(
      'orders products by their most recently added batch',
      () async {
        await db.insertProduct(
          const Product(barcode: 'a', name: 'Apple'),
        );
        await db.insertProduct(
          const Product(barcode: 'b', name: 'Banana'),
        );
        // Banana's newest batch (5000) is newer than Apple's newest (3000),
        // so Banana must rank first regardless of arbitrary row choice.
        await db.insertInventoryItem(
          const InventoryItem(barcode: 'a', dateAdded: 1000),
        );
        await db.insertInventoryItem(
          const InventoryItem(barcode: 'b', dateAdded: 5000),
        );
        await db.insertInventoryItem(
          const InventoryItem(barcode: 'a', dateAdded: 3000),
        );

        final rows = await db.getDistinctProductsFromInventory(
          inventoryId: 1,
        );

        expect(rows.map((r) => r['barcode']).toList(), ['b', 'a']);
        // Each row carries the newest batch date so the ordering is
        // deterministic and provable.
        final byBarcode = {for (final r in rows) r['barcode']: r};
        expect(byBarcode['b']!['last_added'], 5000);
        expect(byBarcode['a']!['last_added'], 3000);
      },
    );

    test('limits the result set', () async {
      for (var i = 0; i < 5; i++) {
        await db.insertProduct(Product(barcode: 'p$i', name: 'P$i'));
        await db.insertInventoryItem(
          InventoryItem(barcode: 'p$i', dateAdded: i),
        );
      }

      final rows = await db.getDistinctProductsFromInventory(
        inventoryId: 1,
        limit: 3,
      );

      expect(rows, hasLength(3));
    });
  });
}
