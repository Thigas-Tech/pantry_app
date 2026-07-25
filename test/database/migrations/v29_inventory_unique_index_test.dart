import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Returns a unique in-memory database path for each call so that sqflite
/// does not share state across tests.
String _uniqueDbPath() =>
    '$inMemoryDatabasePath${DateTime.now().microsecondsSinceEpoch}${_counter++}';
int _counter = 0;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v29 inventory unique index', () {
    Future<Database> _buildV28Db() async {
      final db = await databaseFactory.openDatabase(_uniqueDbPath());
      // Run all migrations up to v28 to ensure we have the full schema.
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 28);

      // Insert a product first (FK target).
      await db.insert('products', {
        'barcode': 'test',
        'name': 'Test Product',
        'source': 'api',
        'product_type': 'barcoded',
        'language_code': 'en',
        'submission_status': 'not_submitted',
      });

      // Insert duplicate inventory rows (simulating the pre-v29 state).
      await db.insert('inventory', {
        'barcode': 'test',
        'quantity': 1.0,
        'unit': 'pieces',
        'inventory_id': 1,
        'date_added': 100,
      });
      await db.insert('inventory', {
        'barcode': 'test',
        'quantity': 2.0,
        'unit': 'pieces',
        'inventory_id': 1,
        'date_added': 200,
      });

      return db;
    }

    test('creates the unique index and deduplicates', () async {
      final db = await _buildV28Db();

      // Run v29 migration.
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 28, 29);

      // Verify index exists.
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master"
        " WHERE type='index' AND name='idx_inventory_barcode_inventory_id'",
      );
      expect(indexes, isNotEmpty);

      // Verify duplicate was removed (only 1 row left).
      final rows = await db.rawQuery(
        "SELECT count(*) AS cnt FROM inventory"
        " WHERE barcode = 'test' AND inventory_id = 1",
      );
      final count = Sqflite.firstIntValue(rows) ?? 0;
      expect(count, 1);

      // Verify the remaining row has the max id (latest insert).
      final remaining = await db.rawQuery(
        "SELECT quantity FROM inventory"
        " WHERE barcode = 'test' AND inventory_id = 1",
      );
      expect((remaining.first['quantity'] as num).toDouble(), 2.0);

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await _buildV28Db();

      // Run v29 twice.
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 28, 29);
      await runner.run(db, 28, 29);

      // No errors on second run. Index still exists.
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master"
        " WHERE type='index' AND name='idx_inventory_barcode_inventory_id'",
      );
      expect(indexes, hasLength(1));

      await db.close();
    });
  });
}
