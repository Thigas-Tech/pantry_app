import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v46 prices resilience', () {
    /// Builds a database at schema version 45 (pre-v46) holding the messy
    /// price rows a production install can accumulate: prices whose product
    /// left the cache, prices without a purchase date, and prices whose
    /// pantry was deleted.
    Future<Database> buildPreV46Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 45);

      await db.insert('inventories', {'name': 'Home', 'created_at': 1});
      await db.insert('products', {
        'barcode': '123',
        'name': 'Eggs',
        'source': 'manual',
      });
      await db.insert('products', {
        'barcode': 'gone',
        'name': 'Flushed product',
        'source': 'api',
      });

      final now = DateTime.now().millisecondsSinceEpoch;
      final old = now - 10 * 86400000;

      // A normal row.
      await db.insert('prices', {
        'barcode': '123',
        'price': 9.99,
        'currency': 'USD',
        'inventory_id': 1,
        'date_added': now,
        'date_purchased': 1000,
      });
      // A price whose product is not in the cache.
      await db.insert('prices', {
        'barcode': 'gone',
        'price': 4.50,
        'currency': 'USD',
        'inventory_id': 1,
        'date_added': now,
        'date_purchased': 2000,
      });
      // A price without a purchase date.
      await db.insert('prices', {
        'barcode': '123',
        'price': 11.99,
        'currency': 'USD',
        'inventory_id': 1,
        'date_added': old,
        'date_purchased': null,
      });
      // A price whose pantry no longer exists.
      await db.insert('prices', {
        'barcode': '123',
        'price': 3.25,
        'currency': 'USD',
        'inventory_id': 99,
        'date_added': now,
        'date_purchased': 3000,
      });

      return db;
    }

    test('preserves every price row through the rebuild', () async {
      final db = await buildPreV46Db();
      await MigrationRunner(allMigrations()).run(db, 45, 46);

      final count = await db.rawQuery('SELECT COUNT(*) AS c FROM prices');
      expect(count.first['c'], 4);

      final orphan = await db.rawQuery(
        "SELECT * FROM prices WHERE barcode = 'gone'",
      );
      expect(orphan, hasLength(1));
      expect(orphan.first['price'], 4.50);

      final strayPantry = await db.rawQuery(
        'SELECT * FROM prices WHERE inventory_id = 99',
      );
      expect(strayPantry, hasLength(1));
      expect(strayPantry.first['price'], 3.25);

      await db.close();
    });

    test('backfills NULL date_purchased from date_added', () async {
      final db = await buildPreV46Db();
      await MigrationRunner(allMigrations()).run(db, 45, 46);

      final rows = await db.rawQuery(
        'SELECT * FROM prices WHERE barcode = ? AND price = 11.99',
        ['123'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['date_purchased'], isNotNull);
      expect(rows.first['date_purchased'], rows.first['date_added']);

      await db.close();
    });

    test('drops the foreign keys on the prices table', () async {
      final db = await buildPreV46Db();
      await MigrationRunner(allMigrations()).run(db, 45, 46);

      final fks = await db.rawQuery("PRAGMA foreign_key_list('prices')");
      expect(fks, isEmpty);

      await db.close();
    });

    test('creates the composite latest-price index', () async {
      final db = await buildPreV46Db();
      await MigrationRunner(allMigrations()).run(db, 45, 46);

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'"
        " AND name = 'idx_prices_barcode_inventory_date'",
      );
      expect(indexes, hasLength(1));

      await db.close();
    });

    test('adds price package columns to shopping_list', () async {
      final db = await buildPreV46Db();
      await MigrationRunner(allMigrations()).run(db, 45, 46);

      expect(
        await columnExists(db, 'shopping_list', 'price_package_quantity'),
        isTrue,
      );
      expect(
        await columnExists(db, 'shopping_list', 'price_package_unit'),
        isTrue,
      );

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildPreV46Db();
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 45, 46);
      await runner.run(db, 45, 46);

      final count = await db.rawQuery('SELECT COUNT(*) AS c FROM prices');
      expect(count.first['c'], 4);

      await db.close();
    });
  });
}
