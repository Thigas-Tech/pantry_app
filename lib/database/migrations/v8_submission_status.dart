import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds submission_status column to the products table.
class MigrationV8 extends Migration {
  @override
  int get version => 8;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'submission_status')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN submission_status '
        "TEXT NOT NULL DEFAULT 'not_submitted'",
      );
    }
  }
}
