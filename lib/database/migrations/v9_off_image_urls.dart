import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds off_nutrition_image_url, off_ingredients_image_url, and
/// off_product_image_url columns to products.
class MigrationV9 extends Migration {
  @override
  int get version => 9;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'off_nutrition_image_url')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN off_nutrition_image_url TEXT',
      );
    }
    if (!await columnExists(db, 'products', 'off_ingredients_image_url')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN off_ingredients_image_url TEXT',
      );
    }
    if (!await columnExists(db, 'products', 'off_product_image_url')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN off_product_image_url TEXT',
      );
    }
  }
}
