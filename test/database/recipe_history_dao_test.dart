import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/recipe_history_dao.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late RecipeHistoryDao dao;

  setUp(() async {
    dao = const RecipeHistoryDao();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await dao.createTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('insert', () {
    test('returns an id after insert', () async {
      final id = await dao.insert(
        db,
        const RecipeHistoryEntry(
          recipeId: 1,
          madeAt: 1000,
          ingredientSnapshot: '[]',
        ),
      );
      expect(id, isNonNegative);
    });
  });

  group('getByRecipeId', () {
    test('returns entries ordered by made_at DESC', () async {
      await dao.insert(
        db,
        const RecipeHistoryEntry(
          recipeId: 1,
          madeAt: 100,
          ingredientSnapshot: '[]',
        ),
      );
      await dao.insert(
        db,
        const RecipeHistoryEntry(
          recipeId: 1,
          madeAt: 200,
          ingredientSnapshot: '[]',
        ),
      );
      await dao.insert(
        db,
        const RecipeHistoryEntry(
          recipeId: 2,
          madeAt: 300,
          ingredientSnapshot: '[]',
        ),
      );

      final entries = await dao.getByRecipeId(db, 1);
      expect(entries.length, 2);
      expect(entries[0].madeAt, 200);
      expect(entries[1].madeAt, 100);
    });

    test('returns empty for recipe with no history', () async {
      final entries = await dao.getByRecipeId(db, 999);
      expect(entries, isEmpty);
    });
  });

  group('getRecent', () {
    test('returns entries after the given timestamp', () async {
      await dao.insert(
        db,
        const RecipeHistoryEntry(
          recipeId: 1,
          madeAt: 100,
          ingredientSnapshot: '[]',
        ),
      );
      await dao.insert(
        db,
        const RecipeHistoryEntry(
          recipeId: 1,
          madeAt: 200,
          ingredientSnapshot: '[]',
        ),
      );

      final entries = await dao.getRecent(db, 150);
      expect(entries.length, 1);
      expect(entries[0].madeAt, 200);
    });

    test('returns empty when no entries after timestamp', () async {
      await dao.insert(
        db,
        const RecipeHistoryEntry(
          recipeId: 1,
          madeAt: 100,
          ingredientSnapshot: '[]',
        ),
      );
      final entries = await dao.getRecent(db, 999);
      expect(entries, isEmpty);
    });
  });

  group('deleteById', () {
    test('removes the entry', () async {
      final id = await dao.insert(
        db,
        const RecipeHistoryEntry(
          recipeId: 1,
          madeAt: 100,
          ingredientSnapshot: '[]',
        ),
      );
      await dao.deleteById(db, id);

      final entries = await dao.getByRecipeId(db, 1);
      expect(entries, isEmpty);
    });
  });
}
