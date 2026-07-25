import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the prices table with indexes.
class MigrationV12 extends Migration {
  @override
  int get version => 12;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE prices (
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
        date_added INTEGER NOT NULL,
        FOREIGN KEY (barcode) REFERENCES products(barcode)
      )
    ''');
    await db.execute('CREATE INDEX idx_prices_barcode ON prices(barcode)');
    await db.execute('CREATE INDEX idx_prices_date ON prices(date_purchased)');
    await db.execute(
      'CREATE INDEX idx_prices_sync_status ON prices(sync_status)',
    );
  }
}
