import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds nutriscore_not_applicable_category column to products.
class MigrationV5 extends Migration {
  @override
  int get version => 5;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(
      db,
      'products',
      'nutriscore_not_applicable_category',
    )) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN nutriscore_not_applicable_category '
        'TEXT',
      );
    }
  }
}
