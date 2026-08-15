import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Backfills null inventory_id on shopping_list rows.
class MigrationV20 extends Migration {
  @override
  int get version => 20;

  @override
  Future<void> up(Database db) async {
    // Only backfill when at least one inventory exists. If the user deleted
    // every pantry before upgrading, writing a phantom id would violate the
    // shopping_list FK and block the upgrade; rows are left unassigned
    // instead.
    final hasInventory = await db.rawQuery(
      'SELECT 1 FROM inventories LIMIT 1',
    );
    if (hasInventory.isEmpty) return;
    final minId = await db.rawQuery(
      'SELECT MIN(id) AS result FROM inventories',
    );
    final defaultId = minId.first['result'] as int?;
    if (defaultId == null) return;
    await db.rawUpdate(
      'UPDATE shopping_list SET inventory_id = ?'
      ' WHERE inventory_id IS NULL',
      [defaultId],
    );
  }
}
