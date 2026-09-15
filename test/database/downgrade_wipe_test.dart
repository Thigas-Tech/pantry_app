import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'a database with a higher user_version is wiped and rebuilt from the '
    'baseline',
    () async {
      final dir = Directory.systemTemp.createTempSync('pantry_downgrade_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/legacy.db';

      // Simulate an install created by an older app version (v46 schema).
      final legacy = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 46,
          onCreate: (db, version) async {
            await db.execute('CREATE TABLE legacy_table (id INTEGER)');
          },
        ),
      );
      await legacy.insert('legacy_table', {'id': 1});
      await legacy.close();

      final helper = DatabaseHelper.withPath(path);
      final db = await helper.database;

      final legacyTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
        " AND name='legacy_table'",
      );
      expect(legacyTables, isEmpty);
      expect(await db.query('inventories'), hasLength(1));

      final userVersion = await db.rawQuery('PRAGMA user_version');
      expect(userVersion.single.values.first, DatabaseHelper.databaseVersion);

      await db.close();
    },
  );
}
