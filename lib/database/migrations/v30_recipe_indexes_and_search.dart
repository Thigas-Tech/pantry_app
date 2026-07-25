import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/search_utils.dart';
import 'package:sqflite/sqflite.dart';

/// Adds indexes on recipes table (name, created_at, updated_at) and a
/// search_text column for full-text search.
class MigrationV30 extends Migration {
  @override
  int get version => 30;

  @override
  Future<void> up(Database db) async {
    try {
      // Add search_text column if missing.
      if (!await columnExists(db, 'recipes', 'search_text')) {
        await db.execute('ALTER TABLE recipes ADD COLUMN search_text TEXT');
      }

      // Backfill search_text for existing recipes.
      final recipes = await db.query('recipes');
      if (recipes.isNotEmpty) {
        await db.transaction((txn) async {
          for (final row in recipes) {
            final name = (row['name'] as String?) ?? '';
            final instructions = (row['instructions'] as String?) ?? '';
            final combined = '$name $instructions';
            final normalized = normalizeForSearch(combined);
            await txn.update(
              'recipes',
              {'search_text': normalized},
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          }
        });
      }

      // Create indexes.
      for (final col in ['name', 'created_at', 'updated_at']) {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_recipes_$col'
          ' ON recipes($col)',
        );
      }

      logInfo(
        'Migration v30 completed'
        ' (recipe indexes and search_text)',
      );
    } on Exception catch (e) {
      logWarning('Migration v30 failed: $e');
      rethrow;
    }
  }
}
