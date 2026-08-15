import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/v43_remove_recipe_shared_id.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v43 remove recipe shared id', () {
    /// Builds a recipes table that includes the shared_recipe_id column as
    /// created by the (now removed) v40 migration.
    Future<Database> buildPreV43Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE recipes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          instructions TEXT NOT NULL DEFAULT '',
          servings INTEGER NOT NULL DEFAULT 0,
          image_path TEXT NOT NULL DEFAULT '',
          search_text TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          inventory_id INTEGER NOT NULL DEFAULT 1,
          shared_recipe_id TEXT NOT NULL DEFAULT ''
        )
      ''');
      await db.insert('recipes', {
        'name': 'Soup',
        'created_at': 100,
        'updated_at': 200,
      });
      return db;
    }

    test('drops the shared_recipe_id column from recipes', () async {
      final db = await buildPreV43Db();
      expect(await columnExists(db, 'recipes', 'shared_recipe_id'), isTrue);

      await MigrationV43().up(db);

      expect(await columnExists(db, 'recipes', 'shared_recipe_id'), isFalse);

      // The remaining columns are untouched.
      final cols = await db.rawQuery("PRAGMA table_info('recipes')");
      expect(cols.map((c) => c['name']), contains('name'));
      expect(cols.map((c) => c['name']), contains('inventory_id'));

      await db.close();
    });

    test('preserves recipe rows when dropping the column', () async {
      final db = await buildPreV43Db();
      await MigrationV43().up(db);

      final rows = await db.query('recipes');
      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Soup');

      await db.close();
    });

    test('is idempotent when the column does not exist', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE recipes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          inventory_id INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await MigrationV43().up(db);

      expect(await columnExists(db, 'recipes', 'shared_recipe_id'), isFalse);

      await db.close();
    });
  });
}
