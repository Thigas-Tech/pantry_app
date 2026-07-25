import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Normalizes produce barcodes across all tables.
///
/// Lowercases, trims, and replaces spaces with underscores in produce
/// barcodes (those starting with 'produce-') across products, inventory,
/// recipe_ingredients, prices, and shopping_list.
class MigrationV28 extends Migration {
  @override
  int get version => 28;

  @override
  Future<void> up(Database db) async {
    for (final table in [
      'products',
      'inventory',
      'recipe_ingredients',
      'prices',
      'shopping_list',
    ]) {
      await db.rawUpdate('''
        UPDATE $table
        SET barcode = 'produce-'
          || REPLACE(LOWER(TRIM(SUBSTR(barcode, 9))), ' ', '_')
        WHERE barcode LIKE 'produce-%'
      ''');
    }
  }
}
