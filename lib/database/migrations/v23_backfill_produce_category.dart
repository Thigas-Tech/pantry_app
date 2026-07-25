import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Backfills the category for produce-type products.
class MigrationV23 extends Migration {
  @override
  int get version => 23;

  @override
  Future<void> up(Database db) async {
    await db.rawUpdate(
      "UPDATE products SET category = 'Fruits and vegetables based foods'"
      " WHERE product_type = 'produce' AND category IS NULL",
    );
  }
}
