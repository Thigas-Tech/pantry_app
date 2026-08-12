import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/v33_recipes_inventory.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v33 recipes inventory', () {
    /// Builds a database with the pre-v33 schema: a recipes table WITHOUT an
    /// inventory_id column, plus two inventories. Mirrors the schema created
    /// by v25 for existing installs upgrading to v33.
    Future<Database> buildPreV33Db() async {
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
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.insert('inventories', {'name': 'Home', 'created_at': 1});
      await db.insert('inventories', {'name': 'Work', 'created_at': 2});
      await db.insert('recipes', {
        'name': 'Soup',
        'instructions': 'Cook',
        'servings': 2,
        'image_path': '',
        'created_at': 100,
        'updated_at': 200,
      });
      return db;
    }

    test('adds inventory_id column to recipes', () async {
      final db = await buildPreV33Db();
      await MigrationV33().up(db);

      expect(await columnExists(db, 'recipes', 'inventory_id'), isTrue);

      await db.close();
    });

    test('backfills existing recipes to the first inventory', () async {
      final db = await buildPreV33Db();
      await MigrationV33().up(db);

      final rows = await db.rawQuery(
        "SELECT inventory_id FROM recipes WHERE name = 'Soup'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first['inventory_id'], 1);

      await db.close();
    });

    test('creates an index on inventory_id', () async {
      final db = await buildPreV33Db();
      await MigrationV33().up(db);

      final result = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='index' AND name='idx_recipes_inventory_id'",
      );
      expect(result, isNotEmpty);

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildPreV33Db();
      await MigrationV33().up(db);
      await MigrationV33().up(db);

      expect(await columnExists(db, 'recipes', 'inventory_id'), isTrue);
      final rows = await db.rawQuery(
        "SELECT inventory_id FROM recipes WHERE name = 'Soup'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first['inventory_id'], 1);

      await db.close();
    });

    test('backfills to the fallback id when inventories is empty', () async {
      // Build a pre-v33 schema with recipes but no inventories rows at all.
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
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.insert('recipes', {
        'name': 'Soup',
        'instructions': 'Cook',
        'servings': 2,
        'image_path': '',
        'created_at': 100,
        'updated_at': 200,
      });

      await MigrationV33().up(db);

      final rows = await db.rawQuery(
        "SELECT inventory_id FROM recipes WHERE name = 'Soup'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first['inventory_id'], 1);

      await db.close();
    });

    test(
      'defaults inventory_id to 1 for rows inserted after migration',
      () async {
        final db = await buildPreV33Db();
        await MigrationV33().up(db);

        final id = await db.insert('recipes', {
          'name': 'New Recipe',
          'instructions': '',
          'servings': 1,
          'image_path': '',
          'created_at': 300,
          'updated_at': 300,
        });
        expect(id, isNonNegative);

        final rows = await db.rawQuery(
          "SELECT inventory_id FROM recipes WHERE name = 'New Recipe'",
        );
        expect(rows, isNotEmpty);
        expect(rows.first['inventory_id'], 1);

        await db.close();
      },
    );
  });
}
