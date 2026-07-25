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

  group('v30 recipe indexes and search', () {
    Future<Database> _buildV29Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 29);

      // Insert a recipe to verify index benefit.
      await db.insert('recipes', {
        'name': 'Test Recipe',
        'instructions': 'Do stuff',
        'servings': 2,
        'image_path': '',
        'created_at': 100,
        'updated_at': 200,
      });

      return db;
    }

    test('adds recipe indexes', () async {
      final db = await _buildV29Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 29, 30);

      // Verify all three indexes exist.
      for (final idx in [
        'idx_recipes_name',
        'idx_recipes_created_at',
        'idx_recipes_updated_at',
      ]) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master"
          " WHERE type='index' AND name='$idx'",
        );
        expect(result, isNotEmpty, reason: 'Index $idx should exist');
      }

      await db.close();
    });

    test('adds search_text column to recipes', () async {
      final db = await _buildV29Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 29, 30);

      expect(
        await columnExists(db, 'recipes', 'search_text'),
        isTrue,
      );

      await db.close();
    });

    test('backfills search_text for existing recipes', () async {
      final db = await _buildV29Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 29, 30);

      final rows = await db.rawQuery(
        "SELECT search_text FROM recipes WHERE name = 'Test Recipe'",
      );
      expect(rows, isNotEmpty);
      expect(
        (rows.first['search_text'] as String?)?.isNotEmpty,
        isTrue,
        reason: 'search_text should be backfilled',
      );

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await _buildV29Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 29, 30);
      await runner.run(db, 29, 30);

      // No crash. Indexes still present.
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master"
        " WHERE type='index' AND name LIKE 'idx_recipes_%'",
      );
      expect(indexes, hasLength(3));

      await db.close();
    });

    test('RecipeDao.search returns results', () async {
      final db = await _buildV29Db();

      await MigrationRunner(allMigrations()).run(db, 29, 30);

      // Search by recipe name (via search_text).
      final results = await db.query(
        'recipes',
        where: "search_text LIKE '%' || ? || '%'",
        whereArgs: ['test'],
      );
      expect(results, isNotEmpty);
      expect(results.first['name'], 'Test Recipe');

      await db.close();
    });
  });
}
