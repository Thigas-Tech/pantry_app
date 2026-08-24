import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Rebuilds the prices table as cache-independent user data.
///
/// The barcode and inventory_id foreign keys are dropped so price history
/// survives product cache flushes and pantry deletion. A price observation is
/// the user's own record: it must never be deleted as a side effect of cache
/// maintenance, and a missing product row must never block a new price from
/// being recorded.
///
/// The rebuild also backfills NULL `date_purchased` values from `date_added`
/// so ordering stays deterministic, and adds a composite index for the
/// latest-price-per-barcode query used across the app.
///
/// `shopping_list` gains `price_package_quantity` and `price_package_unit`
/// columns so package sizes entered during a market trip survive into the
/// prices table when the trip is finished.
///
/// The table rebuild is safe under the upgrade transaction: `prices` is a
/// child table (no other table references it), so dropping it cannot violate
/// foreign keys.
class MigrationV46 extends Migration {
  @override
  int get version => 46;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE prices_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT NOT NULL,
          price REAL NOT NULL,
          currency TEXT NOT NULL,
          store TEXT,
          is_discounted INTEGER NOT NULL DEFAULT 0,
          regular_price REAL,
          date_purchased INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'local_only',
          open_prices_id INTEGER,
          location_osm_id TEXT,
          location_osm_type TEXT,
          receipt_series TEXT,
          receipt_number TEXT,
          receipt_item_index INTEGER,
          notes TEXT,
          package_quantity REAL,
          package_unit TEXT,
          date_added INTEGER NOT NULL,
          inventory_id INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        INSERT INTO prices_new (
          id, barcode, price, currency, store, is_discounted,
          regular_price, date_purchased, sync_status, open_prices_id,
          location_osm_id, location_osm_type, receipt_series,
          receipt_number, receipt_item_index, notes, package_quantity,
          package_unit, date_added, inventory_id
        )
        SELECT id, barcode, price, currency, store, is_discounted,
          regular_price, COALESCE(date_purchased, date_added),
          sync_status, open_prices_id, location_osm_id, location_osm_type,
          receipt_series, receipt_number, receipt_item_index, notes,
          package_quantity, package_unit, COALESCE(date_added, 0),
          inventory_id
        FROM prices
      ''');
      await db.execute('DROP TABLE prices');
      await db.execute('ALTER TABLE prices_new RENAME TO prices');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_prices_barcode ON prices(barcode)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_prices_date'
        ' ON prices(date_purchased)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_prices_sync_status'
        ' ON prices(sync_status)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_prices_inventory_id'
        ' ON prices(inventory_id)',
      );
      await db.execute(
        'CREATE INDEX idx_prices_barcode_inventory_date'
        ' ON prices(barcode, inventory_id, date_purchased, id)',
      );

      if (!await columnExists(db, 'shopping_list', 'price_package_quantity')) {
        await db.execute(
          'ALTER TABLE shopping_list ADD COLUMN price_package_quantity REAL',
        );
      }
      if (!await columnExists(db, 'shopping_list', 'price_package_unit')) {
        await db.execute(
          'ALTER TABLE shopping_list ADD COLUMN price_package_unit TEXT',
        );
      }

      logInfo('Migration v46 completed (prices resilience)');
    } on Exception catch (e) {
      logWarning('Migration v46 failed: $e');
      rethrow;
    }
  }
}
