import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/store.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the `stores` table.
///
/// All methods receive a [Database] instance so they can be used
/// independently of [DatabaseHelper] in tests.
class StoreDao {
  /// Creates a [StoreDao].
  const StoreDao();

  /// Creates the `stores` table.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE stores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
  }

  /// Converts a [Store] to a map for database insertion.
  Map<String, dynamic> toMap(Store store) => {
    'id': store.id,
    'name': store.name,
  };

  /// Converts a database row map to a [Store].
  Store fromMap(Map<String, dynamic> map) => Store(
    id: map['id'] as int,
    name: map['name'] as String,
  );

  /// Returns all stores ordered alphabetically (case-insensitive).
  Future<List<Store>> getAll(Database db) async {
    final result = await db.query('stores', orderBy: 'name COLLATE NOCASE');
    return result.map(fromMap).toList();
  }

  /// Inserts a new store with [name].
  ///
  /// The name is trimmed and truncated to 100 characters. Returns the
  /// existing store's [Store.id] if a case-insensitive match exists;
  /// otherwise inserts and returns the new row ID. Returns `-1` if the
  /// trimmed name is empty.
  Future<int> insert(Database db, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return -1;
    final safeName = trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;

    final existing = await getByName(db, safeName);
    if (existing != null) {
      logInfo('Store "$safeName" already exists (id=${existing.id})');
      return existing.id;
    }

    final id = await db.insert('stores', {'name': safeName});
    logInfo('Inserted store "$safeName" (id=$id)');
    return id;
  }

  /// Looks up a store by name (case-insensitive).
  Future<Store?> getByName(Database db, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final result = await db.query(
      'stores',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return fromMap(result.first);
  }

  /// Deletes a store by [id].
  ///
  /// Does not cascade to existing [Price] records — store names in
  /// the prices table remain unchanged.
  Future<void> delete(Database db, int id) async {
    logInfo('Deleting store $id');
    await db.delete('stores', where: 'id = ?', whereArgs: [id]);
  }
}
