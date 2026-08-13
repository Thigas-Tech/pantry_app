import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/v40_recipe_shared_id.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v40 recipe shared id', () {
    /// Builds a database with the pre-v40 schema: a recipes table WITHOUT a
    /// shared_recipe_id column. Mirrors the schema created by v33 for
    /// existing installs upgrading to v40.
    Future<Database> buildPreV40Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE inventories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
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
          inventory_id INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.insert('inventories', {'name': 'Home', 'created_at': 1});
      await db.insert('recipes', {
        'name': 'Soup',
        'instructions': 'Cook',
        'servings': 2,
        'image_path': '',
        'created_at': 100,
        'updated_at': 200,
        'inventory_id': 1,
      });
      return db;
    }

    test('adds shared_recipe_id column to recipes', () async {
      final db = await buildPreV40Db();
      await MigrationV40().up(db);

      expect(await columnExists(db, 'recipes', 'shared_recipe_id'), isTrue);

      await db.close();
    });

    test('defaults existing rows to an empty shared id', () async {
      final db = await buildPreV40Db();
      await MigrationV40().up(db);

      final rows = await db.rawQuery(
        "SELECT shared_recipe_id FROM recipes WHERE name = 'Soup'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first['shared_recipe_id'], '');

      await db.close();
    });
  });
}
