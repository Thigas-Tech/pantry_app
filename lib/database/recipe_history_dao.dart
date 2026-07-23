import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the recipe_history table.
///
/// Each method receives a [Database] instance so it can be used independently
/// of [DatabaseHelper] in tests.
class RecipeHistoryDao {
  /// Creates a [RecipeHistoryDao].
  const RecipeHistoryDao();

  /// Creates the recipe_history table.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipe_history (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id          INTEGER NOT NULL,
        made_at            INTEGER NOT NULL,
        cost_at_time       REAL DEFAULT 0,
        ingredient_snapshot TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_history_recipe'
      ' ON recipe_history(recipe_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_history_made_at'
      ' ON recipe_history(made_at)',
    );
  }

  /// Converts a [RecipeHistoryEntry] to a map for database insertion.
  Map<String, dynamic> toMap(RecipeHistoryEntry entry) => {
    if (entry.id != null) 'id': entry.id,
    'recipe_id': entry.recipeId,
    'made_at': entry.madeAt,
    'cost_at_time': entry.costAtTime,
    'ingredient_snapshot': entry.ingredientSnapshot,
  };

  /// Converts a database row map into a [RecipeHistoryEntry].
  RecipeHistoryEntry fromMap(Map<String, dynamic> map) => RecipeHistoryEntry(
    id: map['id'] as int?,
    recipeId: map['recipe_id'] as int,
    madeAt: map['made_at'] as int,
    costAtTime: (map['cost_at_time'] as num?)?.toDouble() ?? 0.0,
    ingredientSnapshot: map['ingredient_snapshot'] as String? ?? '[]',
  );

  /// Inserts a recipe history entry and returns its row ID.
  Future<int> insert(Database db, RecipeHistoryEntry entry) async {
    logInfo('Inserting recipe history for recipe ${entry.recipeId}');
    try {
      final id = await db.insert('recipe_history', toMap(entry));
      logInfo('Recipe history inserted with id $id');
      return id;
    } on Exception catch (e) {
      logError('Failed to insert recipe history: $e');
      rethrow;
    }
  }

  /// Returns all history entries for the given [recipeId], newest first.
  Future<List<RecipeHistoryEntry>> getByRecipeId(
    Database db,
    int recipeId,
  ) async {
    try {
      final rows = await db.query(
        'recipe_history',
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
        orderBy: 'made_at DESC',
      );
      return rows.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing history for recipe $recipeId: $e');
      rethrow;
    }
  }

  /// Returns all history entries made at or after [sinceMillis].
  Future<List<RecipeHistoryEntry>> getRecent(
    Database db,
    int sinceMillis,
  ) async {
    try {
      final rows = await db.query(
        'recipe_history',
        where: 'made_at >= ?',
        whereArgs: [sinceMillis],
        orderBy: 'made_at DESC',
      );
      return rows.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing recent history: $e');
      rethrow;
    }
  }

  /// Deletes the history entry with the given [id].
  Future<void> deleteById(Database db, int id) async {
    logInfo('Deleting recipe history entry $id');
    try {
      await db.delete('recipe_history', where: 'id = ?', whereArgs: [id]);
      logInfo('Recipe history entry $id deleted');
    } on Exception catch (e) {
      logError('Failed to delete recipe history entry $id: $e');
      rethrow;
    }
  }
}
