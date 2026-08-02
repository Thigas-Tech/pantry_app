import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/utils/logger.dart';
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
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Converts a [Recipe] to a map for database insertion.
  Map<String, dynamic> toMap(Recipe recipe) => {
    if (recipe.id != null) 'id': recipe.id,
    'name': recipe.name,
    'instructions': recipe.instructions,
    'servings': recipe.servings,
    'image_path': recipe.imagePath,
    'created_at': recipe.createdAt,
    'updated_at': recipe.updatedAt,
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
  );

  /// Inserts a recipe and returns its row ID.
  ///
  /// If [Recipe.createdAt] or [Recipe.updatedAt] is 0, the current epoch
  /// timestamp is used.
  Future<int> insert(Database db, Recipe recipe) async {
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
  Future<Recipe?> get(Database db, int id) async {
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

  /// Returns all recipes, ordered by updated_at descending.
  Future<List<Recipe>> listAll(Database db) async {
    try {
      final result = await db.query(
        'recipes',
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
  /// The original createdAt field is preserved from the existing row.
  /// updatedAt is set to the current epoch timestamp.
  Future<int> update(Database db, Recipe recipe) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Preserve original createdAt from the database.
    final existing = await get(db, recipe.id!);
    final preservedCreatedAt = existing?.createdAt ?? recipe.createdAt;

    final updated = recipe.copyWith(
      createdAt: preservedCreatedAt,
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
  Future<int> delete(Database db, int id) async {
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
