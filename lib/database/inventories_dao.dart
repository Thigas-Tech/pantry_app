import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the `inventories` table (named pantries).
///
/// All methods receive a [Database] instance so they can be used
/// independently of [DatabaseHelper] in tests.
class InventoriesDao {
  /// Creates an [InventoriesDao].
  const InventoriesDao();

  /// Creates a new inventory (pantry) with the given [name].
  Future<int> create(Database db, String name) {
    return db.insert('inventories', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Returns all inventories with their item count, ordered by creation time.
  Future<List<Map<String, dynamic>>> list(Database db) {
    return db.rawQuery(
      'SELECT i.id, i.name, i.created_at, '
      '(SELECT COUNT(*) FROM inventory '
      '   WHERE inventory_id = i.id) AS item_count '
      'FROM inventories i '
      'ORDER BY i.created_at ASC',
    );
  }

  /// Deletes the inventory with the given [id] and all its items.
  Future<void> delete(Database db, int id) async {
    await db.delete('inventory', where: 'inventory_id = ?', whereArgs: [id]);
    await db.delete('inventories', where: 'id = ?', whereArgs: [id]);
  }

  /// Renames the inventory with the given [id].
  Future<void> rename(Database db, int id, String newName) async {
    await db.update(
      'inventories',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Creates the schema for the `inventories` table.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE inventories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  /// Seeds the default "Home" inventory.
  Future<int> seedDefault(Database db) {
    logInfo('Creating default "Home" inventory');
    return db.insert('inventories', {
      'name': 'Home',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
