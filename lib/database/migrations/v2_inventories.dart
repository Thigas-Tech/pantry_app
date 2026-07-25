import 'package:pantry_app/database/inventories_dao.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Adds the inventories table and the inventory_id column to inventory.
///
/// Seeds a default "Home" inventory and backfills existing inventory rows.
class MigrationV2 extends Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(Database db) async {
    await const InventoriesDao().createTable(db);

    await db.execute('ALTER TABLE inventory ADD COLUMN inventory_id INTEGER');

    final homeId = await const InventoriesDao().seedDefault(db);

    await db.update(
      'inventory',
      {'inventory_id': homeId},
      where: 'inventory_id IS NULL',
    );
  }
}
