import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/scan_history_dao.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late ScanHistoryDao dao;

  setUp(() async {
    dao = const ScanHistoryDao();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await dao.createTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  ScanHistoryEntry entry(int scannedAt, {String barcode = '5012345678900'}) =>
      ScanHistoryEntry(
        barcode: barcode,
        name: 'Product $barcode',
        scannedAt: scannedAt,
        imageUrl: scannedAt.isEven ? 'https://example.com/img.jpg' : null,
      );

  group('createTable', () {
    test('is idempotent when run twice', () async {
      await dao.createTable(db);
      await dao.createTable(db);
      final rows = await db.rawQuery(
        'SELECT name FROM sqlite_master'
        " WHERE type='table' AND name='scan_history'",
      );
      expect(rows, hasLength(1));
    });
  });

  group('insert', () {
    test('returns a non-negative id', () async {
      final id = await dao.insert(db, entry(1000));
      expect(id, isNonNegative);
    });

    test('persists all fields including null image', () async {
      await dao.insert(db, entry(1000));
      await dao.insert(db, entry(1001, barcode: '9999999999999'));
      final rows = await db.query('scan_history');
      expect(rows, hasLength(2));
      final withImage = rows.firstWhere(
        (r) => r['image_url'] != null,
        orElse: () => {},
      );
      expect(withImage, isNotEmpty);
      final noImage = rows.firstWhere(
        (r) => r['image_url'] == null,
        orElse: () => {},
      );
      expect(noImage, isNotEmpty);
    });

    test('toMap/fromMap roundtrip preserves values', () async {
      final id = await dao.insert(db, entry(1000));
      final rows = await db.query(
        'scan_history',
        where: 'id = ?',
        whereArgs: [id],
      );
      final parsed = dao.fromMap(rows.first);
      expect(parsed.id, id);
      expect(parsed.barcode, '5012345678900');
      expect(parsed.scannedAt, 1000);
      expect(parsed.imageUrl, 'https://example.com/img.jpg');
      expect(parsed.name, 'Product 5012345678900');
    });
  });

  group('getRecent', () {
    test('returns entries newest first', () async {
      await dao.insert(db, entry(100));
      await dao.insert(db, entry(300));
      await dao.insert(db, entry(200));

      final entries = await dao.getRecent(db);
      expect(entries.map((e) => e.scannedAt).toList(), [300, 200, 100]);
    });

    test('respects the limit', () async {
      await dao.insert(db, entry(100));
      await dao.insert(db, entry(200));
      await dao.insert(db, entry(300));

      final entries = await dao.getRecent(db, limit: 2);
      expect(entries, hasLength(2));
      expect(entries.map((e) => e.scannedAt).toList(), [300, 200]);
    });

    test('returns empty for empty table', () async {
      final entries = await dao.getRecent(db);
      expect(entries, isEmpty);
    });

    test('orders ties by insertion id descending', () async {
      await dao.insert(db, entry(100));
      await dao.insert(db, entry(100));
      final entries = await dao.getRecent(db);
      expect(entries, hasLength(2));
      expect(entries[0].id, greaterThan(entries[1].id!));
    });
  });

  group('deleteOld', () {
    test('prunes entries beyond keepCount keeping newest', () async {
      for (var i = 1; i <= 5; i++) {
        await dao.insert(db, entry(i * 100));
      }
      final deleted = await dao.deleteOld(db, keepCount: 3);

      expect(deleted, 2);
      final entries = await dao.getRecent(db);
      expect(entries, hasLength(3));
      expect(entries.map((e) => e.scannedAt).toList(), [500, 400, 300]);
    });

    test('is a no-op when count is at or below keepCount', () async {
      await dao.insert(db, entry(100));
      await dao.insert(db, entry(200));
      final deleted = await dao.deleteOld(db, keepCount: 5);

      expect(deleted, 0);
      final entries = await dao.getRecent(db);
      expect(entries, hasLength(2));
    });

    test('is a no-op on an empty table', () async {
      final deleted = await dao.deleteOld(db);
      expect(deleted, 0);
    });
  });
}
