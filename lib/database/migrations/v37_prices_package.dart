import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds package-size columns to the prices table and packaging-quantity
/// columns to the products table.
///
/// The prices table gains `package_quantity` and `package_unit` so a price
/// observation can carry the size of the package it applies to (e.g. a
/// dozen eggs, a 1 L bottle). The products table gains `quantity` and
/// `product_quantity` so the packaging data fetched from Open Food Facts
/// is persisted locally and can be used as a package-size fallback.
class MigrationV37 extends Migration {
  @override
  int get version => 37;

  @override
  Future<void> up(Database db) async {
    try {
      if (!await columnExists(db, 'prices', 'package_quantity')) {
        await db.execute(
          'ALTER TABLE prices ADD COLUMN package_quantity REAL',
        );
      }
      if (!await columnExists(db, 'prices', 'package_unit')) {
        await db.execute('ALTER TABLE prices ADD COLUMN package_unit TEXT');
      }

      if (!await columnExists(db, 'products', 'quantity')) {
        await db.execute('ALTER TABLE products ADD COLUMN quantity TEXT');
      }
      if (!await columnExists(db, 'products', 'product_quantity')) {
        await db.execute(
          'ALTER TABLE products ADD COLUMN product_quantity REAL',
        );
      }

      logInfo('Migration v37 completed (package size columns)');
    } on Exception catch (e) {
      logWarning('Migration v37 failed: $e');
      rethrow;
    }
  }
}
