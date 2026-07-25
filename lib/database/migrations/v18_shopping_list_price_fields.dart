import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds price columns to shopping_list and an index on inventory_id.
class MigrationV18 extends Migration {
  @override
  int get version => 18;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'shopping_list', 'price_amount')) {
      await db.execute(
        'ALTER TABLE shopping_list ADD COLUMN price_amount REAL',
      );
    }
    if (!await columnExists(db, 'shopping_list', 'price_currency')) {
      await db.execute(
        'ALTER TABLE shopping_list ADD COLUMN price_currency TEXT',
      );
    }
    if (!await columnExists(db, 'shopping_list', 'price_store')) {
      await db.execute(
        'ALTER TABLE shopping_list ADD COLUMN price_store TEXT',
      );
    }
    if (!await columnExists(db, 'shopping_list', 'price_photo_path')) {
      await db.execute(
        'ALTER TABLE shopping_list ADD COLUMN price_photo_path TEXT',
      );
    }

    final existingIndex = await db.rawQuery(
      'SELECT name FROM sqlite_master'
      " WHERE type='index' AND name='idx_shopping_inventory_id'",
    );
    if (existingIndex.isEmpty) {
      await db.execute(
        'CREATE INDEX idx_shopping_inventory_id'
        ' ON shopping_list(inventory_id)',
      );
    }
  }
}
