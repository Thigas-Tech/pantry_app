import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/v44_query_performance_indexes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v44 query performance indexes', () {
    Future<Database> buildPreV44Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE inventory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT NOT NULL,
          quantity REAL DEFAULT 1,
          unit TEXT DEFAULT 'pieces',
          inventory_id INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE shopping_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          inventory_id INTEGER,
          is_purchased INTEGER NOT NULL DEFAULT 0,
          sort_order REAL NOT NULL DEFAULT 0
        )
      ''');
      return db;
    }

    Future<bool> indexExists(Database db, String name) async {
      final rows = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='index' AND name = ?",
        [name],
      );
      return rows.isNotEmpty;
    }

    test('creates the inventory(inventory_id, barcode) index', () async {
      final db = await buildPreV44Db();
      await MigrationV44().up(db);

      expect(
        await indexExists(db, 'idx_inventory_inventory_barcode'),
        isTrue,
      );

      await db.close();
    });

    test('creates the shopping sort_order index', () async {
      final db = await buildPreV44Db();
      await MigrationV44().up(db);

      expect(
        await indexExists(db, 'idx_shopping_inventory_purchased_sort'),
        isTrue,
      );

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildPreV44Db();
      await MigrationV44().up(db);
      await MigrationV44().up(db);

      expect(
        await indexExists(db, 'idx_inventory_inventory_barcode'),
        isTrue,
      );
      expect(
        await indexExists(db, 'idx_shopping_inventory_purchased_sort'),
        isTrue,
      );

      await db.close();
    });
  });
}
