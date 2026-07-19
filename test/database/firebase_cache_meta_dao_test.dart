import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 180 days in milliseconds (matches _produceRefreshIntervalMs).
const int _refreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late FirebaseCacheMetaDao dao;

  setUp(() async {
    dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
    await dbHelper.database;
    dao = const FirebaseCacheMetaDao();
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.close();
  });

  group('upsert', () {
    test('creates row for barcoded type', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        '7622210449283',
        'barcoded',
        lastRefreshedAt: 1000,
        nextRefreshAt: 1000 + _refreshIntervalMs,
      );

      final row = await dao.get(db, '7622210449283');
      expect(row, isNotNull);
      expect(row!['cache_key'], '7622210449283');
      expect(row['cache_type'], 'barcoded');
      expect(row['fdc_id'], isNull);
      expect(row['last_refreshed_at'], 1000);
      expect(row['next_refresh_at'], 1000 + _refreshIntervalMs);
    });

    test('creates row for produce type', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'produce:apple',
        'produce',
        fdcId: 1750339,
        lastRefreshedAt: 2000,
        nextRefreshAt: 2000 + _refreshIntervalMs,
      );

      final row = await dao.get(db, 'produce:apple');
      expect(row, isNotNull);
      expect(row!['cache_key'], 'produce:apple');
      expect(row['cache_type'], 'produce');
      expect(row['fdc_id'], 1750339);
    });

    test('replaces existing row with same key', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'key1',
        'barcoded',
        lastRefreshedAt: 100,
        nextRefreshAt: 200,
      );

      await dao.upsert(
        db,
        'key1',
        'produce',
        fdcId: 42,
        lastRefreshedAt: 300,
        nextRefreshAt: 400,
      );

      final row = await dao.get(db, 'key1');
      expect(row, isNotNull);
      expect(row!['cache_type'], 'produce');
      expect(row['fdc_id'], 42);
      expect(row['last_refreshed_at'], 300);
      expect(row['next_refresh_at'], 400);
    });
  });

  group('get', () {
    test('retrieves row by cache_key', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'test-key',
        'barcoded',
        lastRefreshedAt: 10,
        nextRefreshAt: 20,
      );

      final row = await dao.get(db, 'test-key');
      expect(row, isNotNull);
      expect(row!['cache_key'], 'test-key');
    });

    test('returns null for missing key', () async {
      final db = await dbHelper.database;
      final row = await dao.get(db, 'nonexistent');
      expect(row, isNull);
    });
  });

  group('getStaleEntries', () {
    test('returns entries with past next_refresh_at', () async {
      final db = await dbHelper.database;
      const now = 1000000;

      await dao.upsert(
        db,
        'stale1',
        'barcoded',
        lastRefreshedAt: 100,
        nextRefreshAt: now - 1,
      );
      await dao.upsert(
        db,
        'stale2',
        'produce',
        fdcId: 1,
        lastRefreshedAt: 200,
        nextRefreshAt: now - 1,
      );

      final stale = await dao.getStaleEntries(db, nowInMs: now);
      expect(stale.length, 2);
      final keys = stale.map((r) => r['cache_key'] as String).toList();
      expect(keys, containsAll(['stale1', 'stale2']));
    });

    test('excludes entries with future next_refresh_at', () async {
      final db = await dbHelper.database;
      const now = 1000000;

      await dao.upsert(
        db,
        'fresh',
        'barcoded',
        lastRefreshedAt: now,
        nextRefreshAt: now + 1000,
      );
      await dao.upsert(
        db,
        'stale',
        'produce',
        lastRefreshedAt: 100,
        nextRefreshAt: now - 1,
      );

      final stale = await dao.getStaleEntries(db, nowInMs: now);
      expect(stale.length, 1);
      expect(stale.first['cache_key'], 'stale');
    });

    test('filters by cacheType', () async {
      final db = await dbHelper.database;
      const now = 1000000;

      await dao.upsert(
        db,
        'b1',
        'barcoded',
        lastRefreshedAt: 100,
        nextRefreshAt: now - 1,
      );
      await dao.upsert(
        db,
        'b2',
        'barcoded',
        lastRefreshedAt: 200,
        nextRefreshAt: now - 1,
      );
      await dao.upsert(
        db,
        'p1',
        'produce',
        lastRefreshedAt: 300,
        nextRefreshAt: now - 1,
      );

      final staleProduce = await dao.getStaleEntries(
        db,
        cacheType: 'produce',
        nowInMs: now,
      );
      expect(staleProduce.length, 1);
      expect(staleProduce.first['cache_key'], 'p1');

      final staleBarcoded = await dao.getStaleEntries(
        db,
        cacheType: 'barcoded',
        nowInMs: now,
      );
      expect(staleBarcoded.length, 2);
    });
  });

  group('getAllKeys', () {
    test('returns all cache keys', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'k1',
        'barcoded',
        lastRefreshedAt: 1,
        nextRefreshAt: 2,
      );
      await dao.upsert(
        db,
        'k2',
        'produce',
        lastRefreshedAt: 3,
        nextRefreshAt: 4,
      );
      await dao.upsert(
        db,
        'k3',
        'barcoded',
        lastRefreshedAt: 5,
        nextRefreshAt: 6,
      );

      final keys = await dao.getAllKeys(db);
      expect(keys, hasLength(3));
      expect(keys, containsAll(['k1', 'k2', 'k3']));
    });

    test('filters by cacheType', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'b1',
        'barcoded',
        lastRefreshedAt: 1,
        nextRefreshAt: 2,
      );
      await dao.upsert(
        db,
        'b2',
        'barcoded',
        lastRefreshedAt: 3,
        nextRefreshAt: 4,
      );
      await dao.upsert(
        db,
        'p1',
        'produce',
        lastRefreshedAt: 5,
        nextRefreshAt: 6,
      );

      final barcodedKeys = await dao.getAllKeys(db, cacheType: 'barcoded');
      expect(barcodedKeys, hasLength(2));
      expect(barcodedKeys, containsAll(['b1', 'b2']));

      final produceKeys = await dao.getAllKeys(db, cacheType: 'produce');
      expect(produceKeys, hasLength(1));
      expect(produceKeys.first, 'p1');
    });
  });

  group('remove', () {
    test('deletes the entry', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'delete-me',
        'barcoded',
        lastRefreshedAt: 1,
        nextRefreshAt: 2,
      );
      expect(await dao.get(db, 'delete-me'), isNotNull);

      await dao.remove(db, 'delete-me');
      expect(await dao.get(db, 'delete-me'), isNull);
    });
  });

  group('updateRefreshTimestamps', () {
    test('updates only time columns, preserving others', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'meta-key',
        'produce',
        fdcId: 99,
        lastRefreshedAt: 100,
        nextRefreshAt: 200,
      );

      await dao.updateRefreshTimestamps(
        db,
        'meta-key',
        lastRefreshedAt: 500,
        nextRefreshAt: 500 + _refreshIntervalMs,
      );

      final row = await dao.get(db, 'meta-key');
      expect(row, isNotNull);
      expect(row!['cache_key'], 'meta-key');
      expect(row['cache_type'], 'produce');
      expect(row['fdc_id'], 99);
      expect(row['last_refreshed_at'], 500);
      expect(row['next_refresh_at'], 500 + _refreshIntervalMs);
    });
  });

  group('count', () {
    test('returns correct total', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'b1',
        'barcoded',
        lastRefreshedAt: 1,
        nextRefreshAt: 2,
      );
      await dao.upsert(
        db,
        'b2',
        'barcoded',
        lastRefreshedAt: 3,
        nextRefreshAt: 4,
      );
      await dao.upsert(
        db,
        'b3',
        'barcoded',
        lastRefreshedAt: 5,
        nextRefreshAt: 6,
      );
      await dao.upsert(
        db,
        'p1',
        'produce',
        lastRefreshedAt: 7,
        nextRefreshAt: 8,
      );
      await dao.upsert(
        db,
        'p2',
        'produce',
        lastRefreshedAt: 9,
        nextRefreshAt: 10,
      );

      expect(await dao.count(db), 5);
    });

    test('filters by cacheType', () async {
      final db = await dbHelper.database;
      await dao.upsert(
        db,
        'b1',
        'barcoded',
        lastRefreshedAt: 1,
        nextRefreshAt: 2,
      );
      await dao.upsert(
        db,
        'b2',
        'barcoded',
        lastRefreshedAt: 3,
        nextRefreshAt: 4,
      );
      await dao.upsert(
        db,
        'b3',
        'barcoded',
        lastRefreshedAt: 5,
        nextRefreshAt: 6,
      );
      await dao.upsert(
        db,
        'p1',
        'produce',
        lastRefreshedAt: 7,
        nextRefreshAt: 8,
      );
      await dao.upsert(
        db,
        'p2',
        'produce',
        lastRefreshedAt: 9,
        nextRefreshAt: 10,
      );

      expect(await dao.count(db, cacheType: 'barcoded'), 3);
      expect(await dao.count(db, cacheType: 'produce'), 2);
    });
  });
}
