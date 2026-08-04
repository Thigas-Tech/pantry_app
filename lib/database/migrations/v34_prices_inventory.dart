import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds an inventory_id column to the prices table, backfills existing
/// rows to the first inventory, and creates a scoping index.
class MigrationV34 extends Migration {
  @override
  int get version => 34;

  @override
  Future<void> up(Database db) async {
    try {
      if (!await columnExists(db, 'prices', 'inventory_id')) {
        await db.execute(
          'ALTER TABLE prices ADD COLUMN inventory_id'
          ' INTEGER NOT NULL DEFAULT 1',
        );

        // Backfill pre-existing prices to the first inventory (seeded Home).
        final minId = await db.rawQuery(
          'SELECT COALESCE('
          '(SELECT id FROM inventories ORDER BY id ASC LIMIT 1),'
          ' 1'
          ') AS result',
        );
        final defaultId = minId.first['result'] as int? ?? 1;
        await db.rawUpdate(
          'UPDATE prices SET inventory_id = ?',
          [defaultId],
        );
      }

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_prices_inventory_id'
        ' ON prices(inventory_id)',
      );

      logInfo('Migration v34 completed (prices inventory_id)');
    } on Exception catch (e) {
      logWarning('Migration v34 failed: $e');
      rethrow;
    }
  }
}
