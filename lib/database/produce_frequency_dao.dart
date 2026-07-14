import 'package:sqflite/sqflite.dart';

/// Data access for the produce_purchase_frequency table.
///
/// Tracks how often each produce item is purchased, stored in SQLite
/// for fast ordering and offline access. Replaces the previous
/// SharedPreferences-based frequency store.
class ProduceFrequencyDao {
  /// Creates a [ProduceFrequencyDao].
  const ProduceFrequencyDao();

  static const table = 'produce_purchase_frequency';

  /// Creates the produce_purchase_frequency table if it does not exist.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        produce_key  TEXT PRIMARY KEY,
        count        INTEGER NOT NULL DEFAULT 0,
        last_used    INTEGER
      )
    ''');
  }

  /// Increments the purchase count for [produceKey] by 1.
  ///
  /// If [produceKey] does not exist in the table, a row with count 1
  /// is inserted. The [last_used] timestamp is updated to now.
  Future<void> increment(String produceKey, Database db) async {
    final key = produceKey.toLowerCase().trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawInsert(
      'INSERT INTO $table (produce_key, count, last_used) '
      'VALUES (?, 1, ?) '
      'ON CONFLICT(produce_key) DO UPDATE SET '
      'count = count + 1, last_used = ?',
      [key, now, now],
    );
  }

  /// Decrements the purchase count for [produceKey] by 1.
  ///
  /// The count is never reduced below 0. If [produceKey] does not
  /// exist, this is a no-op.
  Future<void> decrement(String produceName, Database db) async {
    final key = produceName.toLowerCase().trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawUpdate(
      'UPDATE $table SET count = MAX(0, count - 1), last_used = ? '
      'WHERE produce_key = ?',
      [now, key],
    );
  }

  /// Returns all purchase counts as a map from produce key to count.
  Future<Map<String, int>> getAll(Database db) async {
    final rows = await db.query(table);
    return {
      for (final row in rows) row['produce_key'] as String: row['count'] as int,
    };
  }

  /// Returns the top [limit] produce items ordered by purchase count
  /// descending.
  ///
  /// Each entry is a map with keys `produce_key` (String) and
  /// `count` (int).
  Future<List<Map<String, dynamic>>> getTopPurchases(
    Database db, {
    int limit = 8,
  }) async {
    return db.query(
      table,
      orderBy: 'count DESC',
      limit: limit,
    );
  }
}
