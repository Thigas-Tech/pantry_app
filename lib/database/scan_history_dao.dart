import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the scan_history table.
///
/// Each method receives a [DatabaseExecutor] (a [Database] or a transaction)
/// so it can be used independently of [DatabaseHelper] in tests and composed
/// inside transactions.
class ScanHistoryDao {
  /// Creates a [ScanHistoryDao].
  const ScanHistoryDao();

  /// The maximum number of history entries kept in the table.
  ///
  /// Older entries are pruned by [deleteOld] after new inserts so the table
  /// never grows without bound.
  static const int defaultKeepCount = 50;

  /// Creates the scan_history table.
  Future<void> createTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scan_history (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode     TEXT NOT NULL,
        name        TEXT NOT NULL,
        scanned_at  INTEGER NOT NULL,
        image_url   TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_scan_history_scanned_at'
      ' ON scan_history(scanned_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_scan_history_barcode'
      ' ON scan_history(barcode)',
    );
  }

  /// Converts a [ScanHistoryEntry] to a map for database insertion.
  Map<String, dynamic> toMap(ScanHistoryEntry entry) => {
    if (entry.id != null) 'id': entry.id,
    'barcode': entry.barcode,
    'name': entry.name,
    'scanned_at': entry.scannedAt,
    'image_url': entry.imageUrl,
  };

  /// Converts a database row map into a [ScanHistoryEntry].
  ScanHistoryEntry fromMap(Map<String, dynamic> map) => ScanHistoryEntry(
    id: map['id'] as int?,
    barcode: map['barcode'] as String,
    name: map['name'] as String,
    scannedAt: map['scanned_at'] as int,
    imageUrl: map['image_url'] as String?,
  );

  /// Inserts a scan history entry and returns its row ID.
  Future<int> insert(DatabaseExecutor db, ScanHistoryEntry entry) async {
    if (entry.barcode.isEmpty) {
      throw ArgumentError('scan barcode must not be empty');
    }
    if (entry.name.isEmpty) {
      throw ArgumentError('scan name must not be empty');
    }
    logInfo('Inserting scan history for ${entry.barcode}');
    try {
      final id = await db.insert('scan_history', toMap(entry));
      logInfo('Scan history inserted with id $id');
      return id;
    } on Exception catch (e) {
      logError('Failed to insert scan history: $e');
      rethrow;
    }
  }

  /// Returns the most recent scan history entries, newest first.
  ///
  /// Results are capped at [limit] rows. Ties in [ScanHistoryEntry.scannedAt]
  /// are broken by descending row id so the ordering is stable.
  Future<List<ScanHistoryEntry>> getRecent(
    DatabaseExecutor db, {
    int limit = ScanHistoryDao.defaultKeepCount,
  }) async {
    try {
      final rows = await db.query(
        'scan_history',
        orderBy: 'scanned_at DESC, id DESC',
        limit: limit,
      );
      return rows.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing recent scans: $e');
      rethrow;
    }
  }

  /// Deletes all but the [keepCount] most recent history entries.
  ///
  /// Returns the number of rows deleted. This keeps the table bounded to
  /// avoid unbounded growth over time.
  Future<int> deleteOld(
    DatabaseExecutor db, {
    int keepCount = ScanHistoryDao.defaultKeepCount,
  }) async {
    logInfo('Pruning scan history to keep $keepCount entries');
    try {
      final result = await db.rawDelete(
        '''
        DELETE FROM scan_history
        WHERE id NOT IN (
          SELECT id FROM scan_history
          ORDER BY scanned_at DESC, id DESC
          LIMIT ?
        )
      ''',
        [keepCount],
      );
      logInfo('Pruned $result old scan history entries');
      return result;
    } on Exception catch (e) {
      logError('Failed to prune scan history: $e');
      rethrow;
    }
  }

  /// Deletes every row from the scan_history table.
  Future<int> clear(DatabaseExecutor db) async {
    logInfo('Clearing scan history');
    try {
      final count = await db.delete('scan_history');
      logInfo('Cleared $count scan history entries');
      return count;
    } on Exception catch (e) {
      logError('Failed to clear scan history: $e');
      rethrow;
    }
  }
}
