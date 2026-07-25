import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds plu_code and product_type columns to products.
class MigrationV21 extends Migration {
  @override
  int get version => 21;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'plu_code')) {
      await db.execute('ALTER TABLE products ADD COLUMN plu_code TEXT');
    }
    if (!await columnExists(db, 'products', 'product_type')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN product_type TEXT'
        " NOT NULL DEFAULT 'barcoded'",
      );
    }
  }
}
