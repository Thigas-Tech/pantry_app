import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Returns a unique in-memory database path for each call so that sqflite
/// does not share state across tests.
String _uniqueDbPath() =>
    '$inMemoryDatabasePath'
    '${DateTime.now().microsecondsSinceEpoch}${_counter++}';
int _counter = 0;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v32 scan_history table', () {
    Future<Database> buildV31Db() async {
      final db = await databaseFactory.openDatabase(_uniqueDbPath());
      // Run all migrations up to v31 to ensure we have the full schema.
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 31);
      return db;
    }

    test('creates the scan_history table with an index', () async {
      final db = await buildV31Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 31, 32);

      final tables = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='table' AND name='scan_history'",
      );
      expect(tables, hasLength(1));

      final indexes = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='index' AND name='idx_scan_history_scanned_at'",
      );
      expect(indexes, hasLength(1));

      // Insert + read to verify the schema is usable.
      final id = await db.insert('scan_history', {
        'barcode': '5012345678900',
        'name': 'Test Product',
        'scanned_at': 1000,
      });
      expect(id, isNonNegative);

      final rows = await db.query(
        'scan_history',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows, hasLength(1));
      expect(rows.first['image_url'], isNull);

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildV31Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 31, 32);
      await runner.run(db, 31, 32);

      final tables = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='table' AND name='scan_history'",
      );
      expect(tables, hasLength(1));

      await db.close();
    });
  });
}
