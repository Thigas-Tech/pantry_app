import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds categories_hierarchy column to the products table.
class MigrationV10 extends Migration {
  @override
  int get version => 10;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'categories_hierarchy')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN categories_hierarchy TEXT',
      );
    }
  }
}
