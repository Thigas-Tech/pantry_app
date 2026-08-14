import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/v41_shopping_sort_order.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v41 shopping sort order', () {
    /// Builds a database with the pre-v41 shopping_list schema (no
    /// sort_order column) plus two pending and one purchased item.
    Future<Database> buildPreV41Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE shopping_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT,
          name TEXT NOT NULL,
          quantity REAL NOT NULL DEFAULT 1.0,
          unit TEXT NOT NULL DEFAULT 'pieces',
          is_purchased INTEGER NOT NULL DEFAULT 0,
          inventory_id INTEGER,
          date_added INTEGER NOT NULL,
          date_purchased INTEGER
        )
      ''');
      await db.insert('shopping_list', {
        'name': 'Oldest',
        'is_purchased': 0,
        'inventory_id': 1,
        'date_added': 100,
      });
      await db.insert('shopping_list', {
        'name': 'Newest',
        'is_purchased': 0,
        'inventory_id': 1,
        'date_added': 300,
      });
      await db.insert('shopping_list', {
        'name': 'Bought',
        'is_purchased': 1,
        'inventory_id': 1,
        'date_added': 200,
        'date_purchased': 400,
      });
      return db;
    }

    test('adds sort_order column to shopping_list', () async {
      final db = await buildPreV41Db();
      await MigrationV41().up(db);

      expect(await columnExists(db, 'shopping_list', 'sort_order'), isTrue);

      await db.close();
    });

    test('is idempotent when sort_order already exists', () async {
      final db = await buildPreV41Db();
      await db.execute(
        'ALTER TABLE shopping_list ADD COLUMN sort_order REAL'
        ' NOT NULL DEFAULT 0',
      );
      await MigrationV41().up(db);

      expect(await columnExists(db, 'shopping_list', 'sort_order'), isTrue);

      await db.close();
    });

    test('backfills pending items by date_added and zeros purchased', () async {
      final db = await buildPreV41Db();
      await MigrationV41().up(db);

      final rows = await db.query(
        'shopping_list',
        orderBy: 'id ASC',
      );
      final oldest = rows[0];
      final newest = rows[1];
      final bought = rows[2];

      expect(oldest['name'], 'Oldest');
      expect(oldest['sort_order'], 2.0);
      expect(newest['name'], 'Newest');
      expect(newest['sort_order'], 1.0);
      expect(bought['name'], 'Bought');
      expect(bought['sort_order'], 0.0);

      await db.close();
    });
  });
}
