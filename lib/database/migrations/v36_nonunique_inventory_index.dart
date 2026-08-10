import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Replaces the unique inventory index with a non-unique one.
///
/// The v29 unique index on inventory(barcode, inventory_id) forbids multiple
/// rows for the same barcode and inventory. Since expiry-aware quick-add needs
/// to keep distinct batches (same barcode, different expiry) as separate rows,
/// the index is dropped and recreated without UNIQUE. Existing rows are left
/// untouched — v29 already deduplicated them.
class MigrationV36 extends Migration {
  @override
  int get version => 36;

  @override
  Future<void> up(Database db) async {
    try {
      await db.transaction((txn) async {
        await txn.execute(
          'DROP INDEX IF EXISTS idx_inventory_barcode_inventory_id',
        );
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_inventory_barcode_inventory_id '
          'ON inventory(barcode, inventory_id)',
        );
      });
      logInfo('Migration v36 completed (non-unique inventory index)');
    } on Exception catch (e) {
      logWarning('Migration v36 failed: $e');
      rethrow;
    }
  }
}
