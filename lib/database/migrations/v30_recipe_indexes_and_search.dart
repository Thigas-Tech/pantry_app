import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/search_utils.dart';
import 'package:sqflite/sqflite.dart';

/// Adds indexes on the recipes table (name, created_at, updated_at) and a
/// search_text column for full-text search.
///
/// The search_text backfill intentionally stays Dart-based: it applies
/// [normalizeForSearch] to every existing row instead of relying on raw
/// SQL. SQLite's built-in string functions cannot strip diacritics
/// (accents, eszett, Latin Extended-A) the way the Dart
/// [normalizeForSearch] does, so a raw-SQL backfill would degrade search
/// correctness. The performance gain of raw SQL is marginal for typical
/// recipe counts, so correctness is prioritized over that optimization.
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
