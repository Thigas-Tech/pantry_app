import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Optimizes the database index set.
///
/// Drops redundant indexes (products.barcode is the PRIMARY KEY so
/// idx_barcode duplicates the auto-index; idx_inventory_barcode is
/// covered by the composite idx_inventory_barcode_inventory_id) and
/// adds composite/missing indexes that serve the hot queries:
/// - prices(barcode, inventory_id, date_purchased): latest-price lookups
///   and the correlated latest-row subqueries
/// - recipes(inventory_id, updated_at): per-inventory list ordering
/// - products(source): cache-flush scans and source distribution
class MigrationV38 extends Migration {
  @override
  int get version => 38;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('DROP INDEX IF EXISTS idx_barcode');
      await db.execute('DROP INDEX IF EXISTS idx_inventory_barcode');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_prices_barcode_inventory_date'
        ' ON prices(barcode, inventory_id, date_purchased)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipes_inventory_updated'
        ' ON recipes(inventory_id, updated_at)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_source'
        ' ON products(source)',
      );
      logInfo('Migration v38 completed (index optimizations)');
    } on Exception catch (e) {
      logWarning('Migration v38 failed: $e');
      rethrow;
    }
  }
}
