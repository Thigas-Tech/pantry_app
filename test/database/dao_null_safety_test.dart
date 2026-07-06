import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests that aggregate DAO methods do not crash on empty tables.
///
/// SQLite returns NULL for SUM on empty result sets — the DAO layer
/// must handle this with null-coalescing (`?? 0`) instead of `!`.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper db;

  setUp(() async {
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    await db.database;
  });

  tearDown(() async {
    final database = await db.database;
    await database.close();
  });

  group('photoCompleteness on empty database', () {
    test('returns zeros for all fields', () async {
      final database = await db.database;
      final result = await db.productDao.photoCompleteness(database);
      expect(result['total'], 0);
      expect(result['nutrition'], 0);
      expect(result['ingredients'], 0);
      expect(result['product'], 0);
    });
  });

  group('offPhotoCompleteness on empty database', () {
    test('returns zeros for all fields', () async {
      final database = await db.database;
      final result = await db.productDao.offPhotoCompleteness(database);
      expect(result['total'], 0);
      expect(result['nutrition'], 0);
      expect(result['ingredients'], 0);
      expect(result['product'], 0);
    });
  });

  group('locationDistribution on empty database', () {
    test('returns empty map', () async {
      final database = await db.database;
      final result = await db.inventoryDao.locationDistribution(
        database,
        inventoryId: 1,
      );
      expect(result, isEmpty);
    });
  });
}
