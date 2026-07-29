import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds serving_quantity column to the products table.
class MigrationV31 extends Migration {
  @override
  int get version => 31;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'serving_quantity')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN serving_quantity REAL',
      );
    }
  }
}
