import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v36 non-unique inventory index', () {
    /// Builds a database at schema version 35 (pre-v36) with a product row
    /// and one inventory entry. Mirrors an existing install upgrading.
    Future<Database> buildPreV36Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 35);
      await db.insert('products', {
        'barcode': '123',
        'name': 'Coke',
        'source': 'manual',
      });
      await db.insert('inventory', {
        'barcode': '123',
        'quantity': 2.0,
        'unit': 'pieces',
        'expiry_date': '2026-12-31',
        'location': 'pantry',
        'inventory_id': 1,
      });
      return db;
    }

    test('index still exists after the migration', () async {
      final db = await buildPreV36Db();
      await MigrationRunner(allMigrations()).run(db, 35, 36);

      final rows = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='index' AND name='idx_inventory_barcode_inventory_id'",
      );
      expect(rows, hasLength(1));

      await db.close();
    });

    test('allows a second row with a different expiry date', () async {
      final db = await buildPreV36Db();
      await MigrationRunner(allMigrations()).run(db, 35, 36);

      final id = await db.insert('inventory', {
        'barcode': '123',
        'quantity': 3.0,
        'unit': 'pieces',
        'expiry_date': '2027-01-15',
        'location': 'pantry',
        'inventory_id': 1,
      });
      expect(id, greaterThan(0));

      final rows = await db.rawQuery(
        'SELECT count(*) AS cnt FROM inventory'
        " WHERE barcode = '123' AND inventory_id = 1",
      );
      expect(Sqflite.firstIntValue(rows), 2);

      await db.close();
    });

    test('index is non-unique at the schema level', () async {
      final db = await buildPreV36Db();
      await MigrationRunner(allMigrations()).run(db, 35, 36);

      final indexList = await db.rawQuery(
        "PRAGMA index_list('inventory')",
      );
      final match = indexList.where(
        (row) => row['name'] == 'idx_inventory_barcode_inventory_id',
      );
      expect(match, hasLength(1));
      expect(match.first['unique'], 0);

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildPreV36Db();
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 35, 36);
      await runner.run(db, 35, 36);

      final rows = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='index' AND name='idx_inventory_barcode_inventory_id'",
      );
      expect(rows, hasLength(1));

      await db.close();
    });
  });
}
