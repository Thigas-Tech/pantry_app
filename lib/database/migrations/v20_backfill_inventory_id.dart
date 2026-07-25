import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Backfills null inventory_id on shopping_list rows.
class MigrationV20 extends Migration {
  @override
  int get version => 20;

  @override
  Future<void> up(Database db) async {
    final minId = await db.rawQuery(
      'SELECT COALESCE('
      '(SELECT id FROM inventories ORDER BY id ASC LIMIT 1),'
      ' 1'
      ') AS result',
    );
    final defaultId = minId.first['result'] as int? ?? 1;
    await db.rawUpdate(
      'UPDATE shopping_list SET inventory_id = ?'
      ' WHERE inventory_id IS NULL',
      [defaultId],
    );
  }
}
