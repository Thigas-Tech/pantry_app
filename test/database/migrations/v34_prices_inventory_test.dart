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

  group('v34 prices inventory', () {
    /// Builds a database at schema version 33 (pre-v34) with a price row.
    /// Mirrors the state of existing installs upgrading to v34.
    Future<Database> buildPreV34Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 33);

      // Seed two inventories and a price row (pre-migration prices have no
      // inventory_id column yet).
      await db.insert('inventories', {'name': 'Home', 'created_at': 1});
      await db.insert('inventories', {'name': 'Work', 'created_at': 2});
      await db.insert('products', {
        'barcode': '123',
        'name': 'Coffee',
        'source': 'manual',
      });
      await db.insert('prices', {
        'barcode': '123',
        'price': 9.99,
        'currency': 'USD',
        'date_added': DateTime.now().millisecondsSinceEpoch,
        'date_purchased': 1000,
      });
      return db;
    }

    test('adds inventory_id column to prices', () async {
      final db = await buildPreV34Db();
      await MigrationRunner(allMigrations()).run(db, 33, 34);

      expect(await columnExists(db, 'prices', 'inventory_id'), isTrue);

      await db.close();
    });

    test('backfills existing prices to the first inventory', () async {
      final db = await buildPreV34Db();
      await MigrationRunner(allMigrations()).run(db, 33, 34);

      final rows = await db.rawQuery(
        "SELECT inventory_id FROM prices WHERE barcode = '123'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first['inventory_id'], 1);

      await db.close();
    });

    test('creates an index on inventory_id', () async {
      final db = await buildPreV34Db();
      await MigrationRunner(allMigrations()).run(db, 33, 34);

      final result = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='index' AND name='idx_prices_inventory_id'",
      );
      expect(result, isNotEmpty);

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildPreV34Db();
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 33, 34);
      await runner.run(db, 33, 34);

      expect(await columnExists(db, 'prices', 'inventory_id'), isTrue);
      final rows = await db.rawQuery(
        "SELECT inventory_id FROM prices WHERE barcode = '123'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first['inventory_id'], 1);

      await db.close();
    });
  });
}
