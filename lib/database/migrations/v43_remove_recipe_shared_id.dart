import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Drops the shared_recipe_id column from the recipes table.
///
/// The column was added by v40 to track the recipe_cache Firestore document
/// id for the Firebase shared-recipe cache. That intermediate cache has been
/// removed, so the column is no longer needed. The drop is idempotent: fresh
/// installs never created the column (v40 is no longer registered), while
/// upgraded installs that have it lose it here.
///
/// ALTER TABLE DROP COLUMN requires SQLite 3.35 (Android 13+). On older
/// Android versions the statement fails, so it runs inside a try/catch and
/// the column is retained rather than blocking the upgrade. A table rebuild
/// is not a safe alternative: recipe_ingredients and recipe_history reference
/// recipes with ON DELETE CASCADE, so dropping the parent table deletes child
/// rows even with defer_foreign_keys, and foreign keys cannot be disabled
/// inside the upgrade transaction. The retained column is inert because
/// nothing reads or writes it.
class MigrationV43 extends Migration {
  @override
  int get version => 43;

  @override
  Future<void> up(Database db) async {
    try {
      if (!await columnExists(db, 'recipes', 'shared_recipe_id')) {
        return;
      }
      try {
        await db.execute(
          'ALTER TABLE recipes DROP COLUMN shared_recipe_id',
        );
        logInfo('Migration v43 completed (recipes.shared_recipe_id dropped)');
      } on Exception catch (e) {
        logWarning(
          'Migration v43 could not drop recipes.shared_recipe_id'
          ' (SQLite < 3.35 on this device); retaining the inert column: $e',
        );
      }
    } on Exception catch (e) {
      logWarning('Migration v43 failed: $e');
      rethrow;
    }
  }
}
