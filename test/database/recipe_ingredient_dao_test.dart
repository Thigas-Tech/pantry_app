import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/recipe_ingredient_dao.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late RecipeIngredientDao dao;

  /// Inserts a default recipe row with id=1 so ingredient FK constraints pass.
  Future<void> seedDefaultRecipe() async {
    await db.insert('recipes', {
      'name': 'Default Recipe',
      'created_at': 0,
      'updated_at': 0,
    });
  }

  setUp(() async {
    dao = const RecipeIngredientDao();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    // Create the parent recipes table for FK constraints.
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        instructions TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await dao.createTable(db);
    await seedDefaultRecipe();
  });

  tearDown(() async {
    await db.close();
  });

  group('RecipeIngredientDao', () {
    test('createTable creates the table', () async {
      final id = await dao.insert(
        db,
        const RecipeIngredient(recipeId: 1, name: 'Chicken'),
      );
      expect(id, isNonNegative);
    });

    test('insert returns id', () async {
      final id = await dao.insert(
        db,
        const RecipeIngredient(recipeId: 1, name: 'Chicken', quantity: 2),
      );
      expect(id, greaterThan(0));
    });

    test('insert persists all fields', () async {
      const ingredient = RecipeIngredient(
        recipeId: 1,
        name: 'Chicken',
        barcode: '001',
        quantity: 2,
        unit: 'g',
      );
      final id = await dao.insert(db, ingredient);

      final items = await dao.listByRecipeId(db, 1);
      expect(items.length, 1);
      expect(items[0].id, id);
      expect(items[0].recipeId, 1);
      expect(items[0].name, 'Chicken');
      expect(items[0].barcode, '001');
      expect(items[0].quantity, 2);
      expect(items[0].unit, 'g');
    });

    test(
      'listByRecipeId returns only ingredients for the given recipe',
      () async {
        await db.insert('recipes', {
          'name': 'Recipe 2',
          'created_at': 0,
          'updated_at': 0,
        });

        await dao.insert(
          db,
          const RecipeIngredient(recipeId: 1, name: 'Chicken'),
        );
        await dao.insert(
          db,
          const RecipeIngredient(recipeId: 1, name: 'Bread'),
        );
        await dao.insert(
          db,
          const RecipeIngredient(recipeId: 2, name: 'Eggs'),
        );

        final recipe1 = await dao.listByRecipeId(db, 1);
        final recipe2 = await dao.listByRecipeId(db, 2);

        expect(recipe1.length, 2);
        expect(recipe1.map((i) => i.name), containsAll(['Chicken', 'Bread']));
        expect(recipe2.length, 1);
        expect(recipe2[0].name, 'Eggs');
      },
    );

    test(
      'listByRecipeId returns empty list for recipe with no ingredients',
      () async {
        final items = await dao.listByRecipeId(db, 999);
        expect(items, isEmpty);
      },
    );

    test('update modifies fields', () async {
      await dao.insert(
        db,
        const RecipeIngredient(recipeId: 1, name: 'Chicken'),
      );
      await dao.update(
        db,
        const RecipeIngredient(
          id: 1,
          recipeId: 1,
          name: 'Grilled Chicken',
          quantity: 2,
          unit: 'g',
        ),
      );

      final items = await dao.listByRecipeId(db, 1);
      expect(items.length, 1);
      expect(items[0].name, 'Grilled Chicken');
      expect(items[0].quantity, 2);
    });

    test('delete removes single ingredient', () async {
      await dao.insert(
        db,
        const RecipeIngredient(recipeId: 1, name: 'Chicken'),
      );
      final id2 = await dao.insert(
        db,
        const RecipeIngredient(recipeId: 1, name: 'Bread'),
      );

      await dao.delete(db, id2);

      final items = await dao.listByRecipeId(db, 1);
      expect(items.length, 1);
      expect(items[0].name, 'Chicken');
    });

    test('deleteByRecipeId removes all ingredients for a recipe', () async {
      await db.insert('recipes', {
        'name': 'Recipe 2',
        'created_at': 0,
        'updated_at': 0,
      });

      await dao.insert(
        db,
        const RecipeIngredient(recipeId: 1, name: 'Chicken'),
      );
      await dao.insert(
        db,
        const RecipeIngredient(recipeId: 1, name: 'Bread'),
      );
      await dao.insert(
        db,
        const RecipeIngredient(recipeId: 2, name: 'Eggs'),
      );

      await dao.deleteByRecipeId(db, 1);

      final recipe1 = await dao.listByRecipeId(db, 1);
      final recipe2 = await dao.listByRecipeId(db, 2);
      expect(recipe1, isEmpty);
      expect(recipe2.length, 1);
      expect(recipe2[0].name, 'Eggs');
    });

    test('cascade delete when recipe is removed', () async {
      final recipeId = await db.insert('recipes', {
        'name': 'Test Recipe',
        'created_at': 0,
        'updated_at': 0,
      });
      await dao.insert(
        db,
        RecipeIngredient(recipeId: recipeId, name: 'Chicken'),
      );

      await db.delete('recipes', where: 'id = ?', whereArgs: [recipeId]);

      final items = await dao.listByRecipeId(db, recipeId);
      expect(items, isEmpty);
    });

    test('delete returns 0 for non-existent id', () async {
      final affected = await dao.delete(db, 999);
      expect(affected, 0);
    });
  });
}
