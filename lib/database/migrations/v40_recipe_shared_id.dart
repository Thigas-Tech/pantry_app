import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds the shared_recipe_id column to the recipes table.
///
/// Stores the random UUID4 used as the recipe_cache Firestore document id
/// so the shared document can be located for deletion. Existing rows get
/// an empty string (no shared snapshot id yet).
class MigrationV40 extends Migration {
  @override
  int get version => 40;

  @override
  Future<void> up(Database db) async {
    try {
      if (await columnExists(db, 'recipes', 'shared_recipe_id')) {
        return;
      }
      await db.execute(
        'ALTER TABLE recipes ADD COLUMN shared_recipe_id TEXT NOT NULL'
        " DEFAULT ''",
      );
      logInfo('Migration v40 completed (recipes.shared_recipe_id)');
    } on Exception catch (e) {
      logWarning('Migration v40 failed: $e');
      rethrow;
    }
  }
}
