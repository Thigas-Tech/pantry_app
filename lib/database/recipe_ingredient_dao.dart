import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the recipe_ingredients table.
///
/// All methods receive a [Database] instance so they can be used
/// independently of [DatabaseHelper] in tests.
class RecipeIngredientDao {
  /// Creates a [RecipeIngredientDao].
  const RecipeIngredientDao();

  /// Creates the recipe_ingredients table.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        barcode TEXT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit TEXT NOT NULL DEFAULT 'pieces',
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id'
      ' ON recipe_ingredients(recipe_id)',
    );
  }

  /// Converts a [RecipeIngredient] to a map for database insertion.
  Map<String, dynamic> toMap(RecipeIngredient item) => {
    if (item.id != null) 'id': item.id,
    'recipe_id': item.recipeId,
    'barcode': item.barcode,
    'name': item.name,
    'quantity': item.quantity,
    'unit': item.unit,
  };

  /// Converts a database row map into a [RecipeIngredient].
  RecipeIngredient fromMap(Map<String, dynamic> map) => RecipeIngredient(
    id: map['id'] as int?,
    recipeId: map['recipe_id'] as int,
    barcode: map['barcode'] as String?,
    name: map['name'] as String,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
    unit: map['unit'] as String? ?? 'pieces',
  );

  /// Inserts a recipe ingredient and returns its row ID.
  Future<int> insert(Database db, RecipeIngredient item) async {
    logInfo('Inserting recipe ingredient: ${item.name}');
    try {
      final id = await db.insert('recipe_ingredients', toMap(item));
      logInfo('Recipe ingredient inserted with id $id');
      return id;
    } on Exception catch (e) {
      logError('Failed to insert recipe ingredient: $e');
      rethrow;
    }
  }

  /// Returns all ingredients for the given [recipeId].
  Future<List<RecipeIngredient>> listByRecipeId(
    Database db,
    int recipeId,
  ) async {
    try {
      final result = await db.query(
        'recipe_ingredients',
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
        orderBy: 'id ASC',
      );
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing ingredients for recipe $recipeId: $e');
      rethrow;
    }
  }

  /// Updates an existing recipe ingredient. Returns rows affected.
  Future<int> update(Database db, RecipeIngredient item) async {
    logInfo('Updating recipe ingredient ${item.id}');
    try {
      final affected = await db.update(
        'recipe_ingredients',
        toMap(item),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      logInfo('Recipe ingredient ${item.id} updated');
      return affected;
    } on Exception catch (e) {
      logError('Failed to update recipe ingredient ${item.id}: $e');
      rethrow;
    }
  }

  /// Deletes the ingredient with the given [id]. Returns rows deleted.
  Future<int> delete(Database db, int id) async {
    logInfo('Deleting recipe ingredient $id');
    try {
      final affected = await db.delete(
        'recipe_ingredients',
        where: 'id = ?',
        whereArgs: [id],
      );
      logInfo('Recipe ingredient $id deleted');
      return affected;
    } on Exception catch (e) {
      logError('Failed to delete recipe ingredient $id: $e');
      rethrow;
    }
  }

  /// Deletes all ingredients for the given [recipeId]. Returns rows deleted.
  Future<int> deleteByRecipeId(Database db, int recipeId) async {
    logInfo('Deleting all ingredients for recipe $recipeId');
    try {
      final affected = await db.delete(
        'recipe_ingredients',
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
      );
      logInfo('Deleted $affected ingredients for recipe $recipeId');
      return affected;
    } on Exception catch (e) {
      logError('Failed to delete ingredients for recipe $recipeId: $e');
      rethrow;
    }
  }
}
