import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds source column (default 'api') to the products table.
class MigrationV6 extends Migration {
  @override
  int get version => 6;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'source')) {
      await db.execute(
        "ALTER TABLE products ADD COLUMN source TEXT NOT NULL DEFAULT 'api'",
      );
    }
  }
}
