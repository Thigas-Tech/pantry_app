import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('columnExists', () {
    test('returns true for an existing column', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE test (id INTEGER, name TEXT)');

      expect(await columnExists(db, 'test', 'id'), isTrue);
      expect(await columnExists(db, 'test', 'name'), isTrue);

      await db.close();
    });

    test('returns false for a non-existing column', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE test (id INTEGER)');

      expect(await columnExists(db, 'test', 'missing'), isFalse);

      await db.close();
    });

    test('returns false for a non-existing table', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      expect(await columnExists(db, 'nonexistent', 'id'), isFalse);
      await db.close();
    });

    test('returns true for column added via ALTER TABLE', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE test (id INTEGER)');
      await db.execute('ALTER TABLE test ADD COLUMN extra TEXT');

      expect(await columnExists(db, 'test', 'extra'), isTrue);

      await db.close();
    });
  });

  group('tableColumns', () {
    test('returns all column names in order', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE test (id INTEGER, name TEXT, value REAL)');

      final columns = await tableColumns(db, 'test');
      expect(columns, ['id', 'name', 'value']);

      await db.close();
    });

    test('returns empty list for non-existing table', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final columns = await tableColumns(db, 'nonexistent');
      expect(columns, isEmpty);
      await db.close();
    });
  });
}
