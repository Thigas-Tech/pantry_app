import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/v20_backfill_inventory_id.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v20 backfill inventory id', () {
    Future<Database> buildDb({bool withInventory = false}) async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE inventories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE shopping_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          inventory_id INTEGER,
          date_added INTEGER NOT NULL,
          FOREIGN KEY (inventory_id) REFERENCES inventories(id)
            ON DELETE SET NULL
        )
      ''');
      if (withInventory) {
        await db.insert('inventories', {'name': 'Home', 'created_at': 1});
        await db.insert('inventories', {'name': 'Work', 'created_at': 2});
      }
      return db;
    }

    test('backfills null inventory_id to the first inventory', () async {
      final db = await buildDb(withInventory: true);
      await db.insert('shopping_list', {
        'name': 'Milk',
        'date_added': 100,
      });

      await MigrationV20().up(db);

      final rows = await db.rawQuery('SELECT inventory_id FROM shopping_list');
      expect(rows.single['inventory_id'], 1);

      await db.close();
    });

    test(
      'skips the backfill when no inventories exist (no phantom id)',
      () async {
        final db = await buildDb();
        await db.insert('shopping_list', {
          'name': 'Milk',
          'date_added': 100,
        });

        await MigrationV20().up(db);

        final rows = await db.rawQuery(
          'SELECT inventory_id FROM shopping_list',
        );
        expect(rows.single['inventory_id'], isNull);

        await db.close();
      },
    );
  });
}
