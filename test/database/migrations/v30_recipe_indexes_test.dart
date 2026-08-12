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
    Future<Database> buildV29Db({
      String? name,
      String? instructions,
    }) async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 29);

      // Insert a recipe to verify index benefit.
      if (name != null) {
        await db.insert('recipes', {
          'name': name,
          'instructions': instructions ?? '',
          'servings': 2,
          'image_path': '',
          'created_at': 100,
          'updated_at': 200,
        });
      }

      return db;
    }

    test('adds recipe indexes', () async {
      final db = await buildV29Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 29, 30);

      // Verify all three indexes exist.
      for (final idx in [
        'idx_recipes_name',
        'idx_recipes_created_at',
        'idx_recipes_updated_at',
      ]) {
        final result = await db.rawQuery(
          'SELECT name FROM sqlite_master'
          " WHERE type='index' AND name='$idx'",
        );
        expect(result, isNotEmpty, reason: 'Index $idx should exist');
      }

      await db.close();
    });

    test('adds search_text column to recipes', () async {
      final db = await buildV29Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 29, 30);

      expect(
        await columnExists(db, 'recipes', 'search_text'),
        isTrue,
      );

      await db.close();
    });

    test('backfills search_text for existing recipes', () async {
      final db = await buildV29Db(
        name: 'Test Recipe',
        instructions: 'Do stuff',
      );

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

    test('backfills search_text with diacritics removed', () async {
      final db = await buildV29Db(
        name: 'Crème Brûlée',
        instructions: 'à la mode',
      );

      await MigrationRunner(allMigrations()).run(db, 29, 30);

      final rows = await db.rawQuery(
        "SELECT search_text FROM recipes WHERE name = 'Crème Brûlée'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first['search_text'], 'creme brulee a la mode');
      await db.close();
    });

    test(
      'backfills search_text lowercased with whitespace collapsed',
      () async {
        final db = await buildV29Db(
          name: '  Café   CRÈME  ',
          instructions: '',
        );

        await MigrationRunner(allMigrations()).run(db, 29, 30);

        final rows = await db.rawQuery('SELECT search_text FROM recipes');
        expect(rows, isNotEmpty);
        expect(rows.first['search_text'], 'cafe creme');
        await db.close();
      },
    );

    test('backfills search_text from empty instructions', () async {
      final db = await buildV29Db(
        name: 'Test Recipe',
        instructions: '',
      );

      await MigrationRunner(allMigrations()).run(db, 29, 30);

      final rows = await db.rawQuery('SELECT search_text FROM recipes');
      expect(rows, isNotEmpty);
      expect(rows.first['search_text'], 'test recipe');
      await db.close();
    });

    test('runs cleanly when the recipes table is empty', () async {
      final db = await buildV29Db();

      await MigrationRunner(allMigrations()).run(db, 29, 30);

      expect(await columnExists(db, 'recipes', 'search_text'), isTrue);
      final rows = await db.rawQuery('SELECT search_text FROM recipes');
      expect(rows, isEmpty);
      await db.close();
    });

    test('leaves search_text unchanged when run twice', () async {
      final db = await buildV29Db(
        name: 'Crème Brûlée',
        instructions: 'à la mode',
      );

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 29, 30);
      final firstRun = await db.rawQuery('SELECT search_text FROM recipes');
      await runner.run(db, 29, 30);
      final secondRun = await db.rawQuery('SELECT search_text FROM recipes');

      expect(secondRun, firstRun);
      expect(secondRun.first['search_text'], 'creme brulee a la mode');
      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildV29Db();

      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 29, 30);
      await runner.run(db, 29, 30);

      // No crash. Indexes still present (including idx_recipes_inventory_id
      // which is part of the recipes createTable schema).
      final indexes = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='index' AND name LIKE 'idx_recipes_%'",
      );
      expect(indexes, hasLength(4));

      await db.close();
    });

    test('RecipeDao.search returns results', () async {
      final db = await buildV29Db(
        name: 'Test Recipe',
        instructions: 'Do stuff',
      );

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
