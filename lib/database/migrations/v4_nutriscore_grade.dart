import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds nutriscore_grade column to the products table.
class MigrationV4 extends Migration {
  @override
  int get version => 4;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'nutriscore_grade')) {
      await db.execute('ALTER TABLE products ADD COLUMN nutriscore_grade TEXT');
    }
  }
}
