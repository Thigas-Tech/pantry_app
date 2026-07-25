import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds serving_weight_g column to the inventory table.
class MigrationV22 extends Migration {
  @override
  int get version => 22;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'inventory', 'serving_weight_g')) {
      await db.execute(
        'ALTER TABLE inventory ADD COLUMN serving_weight_g REAL',
      );
    }
  }
}
