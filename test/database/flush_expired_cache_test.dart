import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration tests for [DatabaseHelper.flushExpiredCachedProducts], the
/// age-based device cache flush that removes API-fetched product rows older
/// than the configured window while preserving manual products.
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

  group('flushExpiredCachedProducts', () {
    // A non-default window so tests exercise the parameter explicitly.
    const maxAge = Duration(days: 90);
    final now = DateTime(2026, 8, 1, 12);

    int ms(Duration ago) => now.subtract(ago).millisecondsSinceEpoch;

    test(
      'deletes api products older than max age and keeps fresh ones',
      () async {
        await db.insertProduct(
          const Product(barcode: 'old', name: 'Old').copyWith(
            lastSynced: ms(const Duration(days: 91)),
          ),
        );
        await db.insertProduct(
          const Product(barcode: 'fresh', name: 'Fresh').copyWith(
            lastSynced: ms(const Duration(days: 1)),
          ),
        );

        final deleted = await db.flushExpiredCachedProducts(
          maxAge: maxAge,
          now: () => now,
        );

        expect(deleted, 1);
        expect(await db.getProduct('old'), isNull);
        expect(await db.getProduct('fresh'), isNotNull);
      },
    );

    test('keeps manual products regardless of age', () async {
      await db.insertProduct(
        const Product(
          barcode: 'manual',
          name: 'Manual',
          source: 'manual',
        ).copyWith(lastSynced: ms(const Duration(days: 400))),
      );
      // USDA produce products use synthetic plu- barcodes that cannot be
      // re-fetched from OFF; they are manual-sourced and must survive the
      // flush too (data-loss regression).
      await db.insertProduct(
        const Product(
          barcode: 'plu-9003',
          name: 'Apple',
          source: 'manual',
        ).copyWith(lastSynced: ms(const Duration(days: 400))),
      );

      await db.flushExpiredCachedProducts(maxAge: maxAge, now: () => now);

      expect(await db.getProduct('manual'), isNotNull);
      expect(await db.getProduct('plu-9003'), isNotNull);
    });

    test('treats a null last_synced api product as expired', () async {
      await db.insertProduct(const Product(barcode: 'nulldate', name: 'None'));

      final deleted = await db.flushExpiredCachedProducts(
        maxAge: maxAge,
        now: () => now,
      );

      expect(deleted, 1);
      expect(await db.getProduct('nulldate'), isNull);
    });

    test('keeps api products at exactly the cutoff boundary', () async {
      await db.insertProduct(
        const Product(barcode: 'boundary', name: 'B').copyWith(
          lastSynced: ms(maxAge),
        ),
      );

      final deleted = await db.flushExpiredCachedProducts(
        maxAge: maxAge,
        now: () => now,
      );

      expect(deleted, 0);
      expect(await db.getProduct('boundary'), isNotNull);
    });

    test('deletes api products one millisecond past the cutoff', () async {
      await db.insertProduct(
        const Product(barcode: 'past', name: 'P').copyWith(
          lastSynced: ms(maxAge) - 1,
        ),
      );

      final deleted = await db.flushExpiredCachedProducts(
        maxAge: maxAge,
        now: () => now,
      );

      expect(deleted, 1);
      expect(await db.getProduct('past'), isNull);
    });

    test('inventory items referencing flushed products survive', () async {
      await db.insertProduct(
        const Product(barcode: 'a', name: 'A').copyWith(
          lastSynced: ms(const Duration(days: 120)),
        ),
      );
      await db.insertInventoryItem(const InventoryItem(barcode: 'a'));

      await db.flushExpiredCachedProducts(maxAge: maxAge, now: () => now);

      expect(await db.getProduct('a'), isNull);
      final rows = await db.getInventoryWithProduct(inventoryId: 1);
      expect(rows.length, 1);
      expect(rows.first['product_name'], isNull);
    });

    test('nulls shopping list barcode refs to flushed products', () async {
      await db.insertProduct(
        const Product(barcode: 'b', name: 'B').copyWith(
          lastSynced: ms(const Duration(days: 120)),
        ),
      );
      await db.insertShoppingItem(
        const ShoppingItem(name: 'Buy B', barcode: 'b'),
      );

      await db.flushExpiredCachedProducts(maxAge: maxAge, now: () => now);

      expect(await db.getProduct('b'), isNull);
      final items = await db.getShoppingList();
      expect(items, hasLength(1));
      expect(items.first.barcode, isNull);
    });

    test(
      're-fetching a flushed product restores it in the inventory join',
      () async {
        await db.insertProduct(
          const Product(barcode: 'c', name: 'C').copyWith(
            lastSynced: ms(const Duration(days: 120)),
          ),
        );
        await db.insertInventoryItem(const InventoryItem(barcode: 'c'));

        await db.flushExpiredCachedProducts(maxAge: maxAge, now: () => now);

        await db.insertProduct(
          const Product(barcode: 'c', name: 'C refreshed').copyWith(
            lastSynced: ms(const Duration(days: 1)),
          ),
        );

        final rows = await db.getInventoryWithProduct(inventoryId: 1);
        expect(rows.length, 1);
        expect(rows.first['product_name'], 'C refreshed');
      },
    );

    test('uses the two-month default window when maxAge is omitted', () async {
      await db.insertProduct(
        const Product(barcode: 'old61', name: 'Old').copyWith(
          lastSynced: ms(const Duration(days: 61)),
        ),
      );
      await db.insertProduct(
        const Product(barcode: 'fresh1', name: 'Fresh').copyWith(
          lastSynced: ms(const Duration(days: 1)),
        ),
      );

      final deleted = await db.flushExpiredCachedProducts(now: () => now);

      expect(deleted, 1);
      expect(await db.getProduct('old61'), isNull);
      expect(await db.getProduct('fresh1'), isNotNull);
    });
  });
}
