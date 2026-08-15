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
class MigrationV43 extends Migration {
  @override
  int get version => 43;

  @override
  Future<void> up(Database db) async {
    try {
      if (!await columnExists(db, 'recipes', 'shared_recipe_id')) {
        return;
      }
      await db.execute(
        'ALTER TABLE recipes DROP COLUMN shared_recipe_id',
      );
      logInfo('Migration v43 completed (recipes.shared_recipe_id dropped)');
    } on Exception catch (e) {
      logWarning('Migration v43 failed: $e');
      rethrow;
    }
  }
}
