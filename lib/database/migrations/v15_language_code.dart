import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds language_code column to the products table.
class MigrationV15 extends Migration {
  @override
  int get version => 15;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'language_code')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN language_code TEXT'
        " NOT NULL DEFAULT 'en'",
      );
    }
  }
}
