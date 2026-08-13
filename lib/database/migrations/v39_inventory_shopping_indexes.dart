import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds composite indexes for the hottest inventory and shopping-list
/// queries:
/// - inventory(inventory_id, expiry_date): the per-inventory pantry list
///   filtered by inventory_id and ordered by expiry_date, avoiding a
///   temporary sort of every pantry on load
/// - shopping_list(inventory_id, is_purchased, date_added): the pending
///   and purchased item lists ordered by their add/purchase dates
class MigrationV39 extends Migration {
  @override
  int get version => 39;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_inventory_inventory_expiry'
        ' ON inventory(inventory_id, expiry_date)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_shopping_list_inventory_purchased_date'
        ' ON shopping_list(inventory_id, is_purchased, date_added)',
      );
      logInfo('Migration v39 completed (inventory and shopping indexes)');
    } on Exception catch (e) {
      logWarning('Migration v39 failed: $e');
      rethrow;
    }
  }
}
