import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the idx_inventory_date_added index on inventory.
class MigrationV14 extends Migration {
  @override
  int get version => 14;

  @override
  Future<void> up(Database db) async {
    final existingIndexes = await db.rawQuery(
      'SELECT name FROM sqlite_master'
      " WHERE type='index' AND name='idx_inventory_date_added'",
    );
    if (existingIndexes.isEmpty) {
      await db.execute(
        'CREATE INDEX idx_inventory_date_added ON inventory(date_added)',
      );
    }
  }
}
