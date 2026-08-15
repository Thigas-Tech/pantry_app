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
    // Foreign keys are enabled (onConfigure runs before onUpgrade) while the
    // upgrade runs inside a transaction. Normalizing products.barcode (the
    // FK parent) first would violate the child FKs in inventory, prices, and
    // shopping_list the instant the parent key changes. Deferring the checks
    // to the outer COMMIT lets all tables normalize together; by then every
    // barcode is consistent. defer_foreign_keys is reset at each COMMIT, so
    // this stays scoped to the upgrade transaction.
    await db.execute('PRAGMA defer_foreign_keys = ON');
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
