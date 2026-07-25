import 'package:pantry_app/firebase_cache_config.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the firebase_cache_meta table.
///
/// Tracks which products have been cached in Firestore and when each
/// document needs its next refresh (180-day rolling cycle).
class FirebaseCacheMetaDao {
  /// Creates a [FirebaseCacheMetaDao].
  const FirebaseCacheMetaDao();

  /// Cache key for the global inventory refresh timestamp entry.
  static const String globalRefreshKey = '__global_refresh__';

  /// Creates the firebase_cache_meta table with indexes.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS firebase_cache_meta (
        cache_key TEXT PRIMARY KEY,
        cache_type TEXT NOT NULL,
        fdc_id INTEGER,
        last_refreshed_at INTEGER,
        next_refresh_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cache_type '
      'ON firebase_cache_meta(cache_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_next_refresh '
      'ON firebase_cache_meta(next_refresh_at)',
    );
  }

  /// Upserts a cache metadata row.
  Future<void> upsert(
    Database db,
    String cacheKey,
    String cacheType, {
    required int lastRefreshedAt,
    required int nextRefreshAt,
    int? fdcId,
  }) async {
    try {
      await db.insert(
        'firebase_cache_meta',
        {
          'cache_key': cacheKey,
          'cache_type': cacheType,
          'fdc_id': fdcId,
          'last_refreshed_at': lastRefreshedAt,
          'next_refresh_at': nextRefreshAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on Exception catch (e) {
      logError('Failed to upsert cache meta for $cacheKey: $e');
      rethrow;
    }
  }

  /// Retrieves a single entry by [cacheKey].
  /// Returns null when the key does not exist.
  Future<Map<String, dynamic>?> get(Database db, String cacheKey) async {
    final result = await db.query(
      'firebase_cache_meta',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Returns all entries where next_refresh_at < [nowInMs].
  ///
  /// Optionally filter by [cacheType] ('barcoded' | 'produce').
  Future<List<Map<String, dynamic>>> getStaleEntries(
    Database db, {
    required int nowInMs,
    String? cacheType,
  }) {
    final where = <String>['next_refresh_at < ?'];
    final args = <dynamic>[nowInMs];

    if (cacheType != null) {
      where.add('cache_type = ?');
      args.add(cacheType);
    }

    return db.query(
      'firebase_cache_meta',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'next_refresh_at ASC',
    );
  }

  /// Returns all cache keys, optionally filtered by [cacheType].
  Future<List<String>> getAllKeys(
    Database db, {
    String? cacheType,
  }) async {
    final where = cacheType != null ? 'cache_type = ?' : null;
    final args = cacheType != null ? <dynamic>[cacheType] : null;

    final result = await db.query(
      'firebase_cache_meta',
      columns: ['cache_key'],
      where: where,
      whereArgs: args,
    );
    return result
        .map((r) => r['cache_key'] as String?)
        .where((k) => k != null)
        .cast<String>()
        .toList();
  }

  /// Deletes an entry by [cacheKey].
  Future<void> remove(Database db, String cacheKey) async {
    await db.delete(
      'firebase_cache_meta',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
  }

  /// Updates only the refresh timestamps for an existing entry.
  ///
  /// Preserves all other columns (cache_key, cache_type, fdc_id).
  Future<void> updateRefreshTimestamps(
    Database db,
    String cacheKey, {
    required int lastRefreshedAt,
    required int nextRefreshAt,
  }) async {
    await db.update(
      'firebase_cache_meta',
      {
        'last_refreshed_at': lastRefreshedAt,
        'next_refresh_at': nextRefreshAt,
      },
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
  }

  /// Records the current time as the last global inventory refresh.
  ///
  /// Uses [globalRefreshKey] as the cache key with
  /// [inventoryRefreshOverdueDays] converted to milliseconds. This replaces
  /// the old SharedPreferences-based staleness tracking.
  Future<void> setGlobalRefreshTime(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await upsert(
      db,
      globalRefreshKey,
      'global_refresh',
      lastRefreshedAt: now,
      nextRefreshAt: now + inventoryRefreshOverdueDays * 24 * 60 * 60 * 1000,
    );
  }

  /// Returns the global inventory refresh row, or null if never set.
  Future<Map<String, dynamic>?> getGlobalRefreshTime(Database db) =>
      get(db, globalRefreshKey);

  /// Counts entries, optionally filtered by [cacheType].
  Future<int> count(
    Database db, {
    String? cacheType,
  }) async {
    final where = cacheType != null ? 'cache_type = ?' : null;
    final args = cacheType != null ? <dynamic>[cacheType] : null;

    return Sqflite.firstIntValue(
          await db.query(
            'firebase_cache_meta',
            columns: ['COUNT(*)'],
            where: where,
            whereArgs: args,
          ),
        ) ??
        0;
  }
}
