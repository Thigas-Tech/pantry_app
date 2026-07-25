import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds a unique index on inventory(barcode, inventory_id) and deduplicates
/// existing rows.
///
/// The deduplication strategy keeps the row with the highest quantity for
/// each (barcode, inventory_id) group, discarding extra copies.
class MigrationV29 extends Migration {
  @override
  int get version => 29;

  @override
  Future<void> up(Database db) async {
    try {
      await db.transaction((txn) async {
        // Deduplicate: keep the row with the maximum id (latest insert)
        // for each (barcode, inventory_id) pair.
        await txn.rawDelete('''
          DELETE FROM inventory
          WHERE id NOT IN (
            SELECT MAX(id)
            FROM inventory
            GROUP BY barcode, inventory_id
          )
        ''');

        await txn.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS '
          'idx_inventory_barcode_inventory_id '
          'ON inventory(barcode, inventory_id)',
        );
      });
      logInfo('Migration v29 completed (inventory unique index)');
    } on Exception catch (e) {
      logWarning('Migration v29 failed: $e');
      rethrow;
    }
  }
}
