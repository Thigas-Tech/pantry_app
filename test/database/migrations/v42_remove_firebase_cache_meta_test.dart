import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/v42_remove_firebase_cache_meta.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v42 remove firebase cache meta', () {
    test('drops the firebase_cache_meta table', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE firebase_cache_meta (
          cache_key TEXT PRIMARY KEY,
          cache_type TEXT NOT NULL,
          fdc_id INTEGER,
          last_refreshed_at INTEGER,
          next_refresh_at INTEGER
        )
      ''');
      await db.insert('firebase_cache_meta', {
        'cache_key': '123',
        'cache_type': 'barcoded',
      });

      await MigrationV42().up(db);

      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'"
        " AND name = 'firebase_cache_meta'",
      );
      expect(rows, isEmpty);

      await db.close();
    });

    test('is idempotent when the table does not exist', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      await MigrationV42().up(db);

      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'"
        " AND name = 'firebase_cache_meta'",
      );
      expect(rows, isEmpty);

      await db.close();
    });
  });
}
