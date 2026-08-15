import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds an inventory_id column to the recipes table, backfills existing
/// rows to the first inventory, and creates a scoping index.
class MigrationV33 extends Migration {
  @override
  int get version => 33;

  @override
  Future<void> up(Database db) async {
    try {
      if (!await columnExists(db, 'recipes', 'inventory_id')) {
        await db.execute(
          'ALTER TABLE recipes ADD COLUMN inventory_id'
          ' INTEGER NOT NULL DEFAULT 1',
        );

        // Backfill pre-existing recipes to the first inventory (seeded Home).
        // If every pantry was deleted before upgrading, skip the backfill:
        // writing a phantom id would violate the recipes FK and block the
        // upgrade.
        final hasInventory = await db.rawQuery(
          'SELECT 1 FROM inventories LIMIT 1',
        );
        if (hasInventory.isNotEmpty) {
          final minId = await db.rawQuery(
            'SELECT MIN(id) AS result FROM inventories',
          );
          final defaultId = minId.first['result'] as int?;
          if (defaultId != null) {
            await db.rawUpdate(
              'UPDATE recipes SET inventory_id = ?',
              [defaultId],
            );
          }
        }
      }

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipes_inventory_id'
        ' ON recipes(inventory_id)',
      );

      logInfo('Migration v33 completed (recipes inventory_id)');
    } on Exception catch (e) {
      logWarning('Migration v33 failed: $e');
      rethrow;
    }
  }
}
