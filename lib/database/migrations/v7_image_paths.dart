import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds nutrition_image_path, ingredients_image_path, and
/// product_image_path columns to products.
class MigrationV7 extends Migration {
  @override
  int get version => 7;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'nutrition_image_path')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN nutrition_image_path TEXT',
      );
    }
    if (!await columnExists(db, 'products', 'ingredients_image_path')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN ingredients_image_path TEXT',
      );
    }
    if (!await columnExists(db, 'products', 'product_image_path')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN product_image_path TEXT',
      );
    }
  }
}
