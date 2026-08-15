import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds composite indexes for the remaining hot queries:
/// - inventory(inventory_id, barcode): the per-inventory price statistics
///   that GROUP BY barcode and the "from your pantry" suggestions that
///   filter by inventory_id, avoiding a temporary b-tree over the whole
///   pantry partition
/// - shopping_list(inventory_id, is_purchased, sort_order): the pending
///   item list ordered by its manual drag order, avoiding a temporary sort
///   on every pending-list read
class MigrationV44 extends Migration {
  @override
  int get version => 44;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_inventory_inventory_barcode'
        ' ON inventory(inventory_id, barcode)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_shopping_inventory_purchased_sort'
        ' ON shopping_list(inventory_id, is_purchased, sort_order)',
      );
      logInfo('Migration v44 completed (query performance indexes)');
    } on Exception catch (e) {
      logWarning('Migration v44 failed: $e');
      rethrow;
    }
  }
}
