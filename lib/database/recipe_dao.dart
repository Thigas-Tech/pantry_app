import 'dart:core';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/search_utils.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the recipes table.
///
/// All methods receive a [Database] instance so they can be used
/// independently of [DatabaseHelper] in tests.
class RecipeDao {
  /// Creates a [RecipeDao].
  const RecipeDao();

  /// Creates the recipes table.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        instructions TEXT NOT NULL DEFAULT '',
        servings INTEGER NOT NULL DEFAULT 0,
        image_path TEXT NOT NULL DEFAULT '',
        search_text TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        inventory_id INTEGER NOT NULL DEFAULT 1,
        shared_recipe_id TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (inventory_id) REFERENCES inventories(id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipes_inventory_id'
      ' ON recipes(inventory_id)',
    );
  }

  /// Converts a [Recipe] to a map for database insertion.
  ///
  /// Emits the derived search_text column via [buildRecipeSearchText] so
  /// every write path (DAO insert/update and the DatabaseHelper
  /// transaction helpers, which all funnel through this map) keeps the
  /// normalized search text in sync with the recipe name and
  /// instructions.
  Map<String, dynamic> toMap(Recipe recipe) => {
    if (recipe.id != null) 'id': recipe.id,
    'name': recipe.name,
    'instructions': recipe.instructions,
    'servings': recipe.servings,
    'image_path': recipe.imagePath,
    'created_at': recipe.createdAt,
    'updated_at': recipe.updatedAt,
    'inventory_id': recipe.inventoryId,
    'shared_recipe_id': recipe.sharedRecipeId,
    'search_text': buildRecipeSearchText(recipe),
  };

  /// Converts a database row map into a [Recipe].
  Recipe fromMap(Map<String, dynamic> map) => Recipe(
    id: map['id'] as int?,
    name: map['name'] as String,
    instructions: map['instructions'] as String? ?? '',
    servings: (map['servings'] as num?)?.toInt() ?? 0,
    imagePath: map['image_path'] as String? ?? '',
    createdAt: map['created_at'] as int? ?? 0,
    updatedAt: map['updated_at'] as int? ?? 0,
    inventoryId: (map['inventory_id'] as num?)?.toInt() ?? 1,
    sharedRecipeId: map['shared_recipe_id'] as String? ?? '',
  );

  /// Inserts a recipe and returns its row ID.
  ///
  /// If [Recipe.createdAt] or [Recipe.updatedAt] is 0, the current epoch
  /// timestamp is used.
  ///
  /// Throws [ArgumentError] if the recipe name is empty.
  Future<int> insert(Database db, Recipe recipe) async {
    if (recipe.name.isEmpty) {
      throw ArgumentError('recipe name must not be empty');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final stamped = recipe.createdAt == 0
        ? recipe.copyWith(createdAt: now)
        : recipe;
    final finalRecipe = stamped.updatedAt == 0
        ? stamped.copyWith(updatedAt: now)
        : stamped;

    logInfo('Inserting recipe: ${finalRecipe.name}');
    try {
      final id = await db.insert('recipes', toMap(finalRecipe));
      logInfo('Recipe inserted with id $id');
      return id;
    } on Exception catch (e) {
      logError('Failed to insert recipe: $e');
      rethrow;
    }
  }

  /// Returns the recipe with the given [id], or null.
  ///
  /// Throws [ArgumentError] if [id] is non-positive.
  Future<Recipe?> get(Database db, int id) async {
    if (id <= 0) {
      throw ArgumentError('recipe id must be positive');
    }
    try {
      final result = await db.query(
        'recipes',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return fromMap(result.first);
    } on Exception catch (e) {
      logError('Error looking up recipe $id: $e');
      rethrow;
    }
  }

  /// Returns all recipes for the given [inventoryId],
  /// ordered by updated_at descending.
  ///
  /// Throws [ArgumentError] if [inventoryId] is non-positive.
  Future<List<Recipe>> listAll(Database db, int inventoryId) async {
    if (inventoryId <= 0) {
      throw ArgumentError('inventory id must be positive');
    }
    try {
      final result = await db.query(
        'recipes',
        where: 'inventory_id = ?',
        whereArgs: [inventoryId],
        orderBy: 'updated_at DESC',
      );
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing recipes: $e');
      rethrow;
    }
  }

  /// Updates an existing recipe. Returns rows affected.
  ///
  /// The original createdAt and inventory_id fields are preserved from the
  /// existing row, so an update never silently moves a recipe to another
  /// inventory. updatedAt is set to the current epoch timestamp.
  ///
  /// Throws [ArgumentError] if id is non-positive.
  Future<int> update(Database db, Recipe recipe) async {
    if (recipe.id == null || recipe.id! <= 0) {
      throw ArgumentError('recipe id must be positive');
    }
    final now = DateTime.now().millisecondsSinceEpoch;

    // Preserve original createdAt and inventoryId from the database.
    final existing = await get(db, recipe.id!);
    final preservedCreatedAt = existing?.createdAt ?? recipe.createdAt;
    final preservedInventoryId = existing?.inventoryId ?? recipe.inventoryId;

    final updated = recipe.copyWith(
      createdAt: preservedCreatedAt,
      inventoryId: preservedInventoryId,
      updatedAt: now,
    );

    logInfo('Updating recipe ${recipe.id}');
    try {
      final affected = await db.update(
        'recipes',
        toMap(updated),
        where: 'id = ?',
        whereArgs: [recipe.id],
      );
      logInfo('Recipe ${recipe.id} updated');
      return affected;
    } on Exception catch (e) {
      logError('Failed to update recipe ${recipe.id}: $e');
      rethrow;
    }
  }

  /// Deletes the recipe with the given [id]. Returns rows deleted.
  ///
  /// Throws [ArgumentError] if [id] is non-positive.
  Future<int> delete(Database db, int id) async {
    if (id <= 0) {
      throw ArgumentError('recipe id must be positive');
    }
    logInfo('Deleting recipe $id');
    try {
      final affected = await db.delete(
        'recipes',
        where: 'id = ?',
        whereArgs: [id],
      );
      logInfo('Recipe $id deleted');
      return affected;
    } on Exception catch (e) {
      logError('Failed to delete recipe $id: $e');
      rethrow;
    }
  }

  /// Returns the total number of recipes.
  Future<int> count(Database db) async {
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM recipes'),
        ) ??
        0;
  }
}
