import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

Future<Map<String, List<String>>> _schemaSnapshot(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table'"
    " AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  final snapshot = <String, List<String>>{};
  for (final row in rows) {
    final table = row['name']! as String;
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    snapshot[table] = columns.map((c) => c['name']! as String).toList();
  }
  return snapshot;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('migration round trip', () {
    test('down removes the schema and up rebuilds it identically', () async {
      final db = await databaseFactory.openDatabase(uniqueTestDbPath());
      final runner = MigrationRunner(allMigrations());

      await runner.run(db, 0, DatabaseHelper.databaseVersion);
      final before = await _schemaSnapshot(db);
      expect(before, isNotEmpty);

      await runner.runDown(db, DatabaseHelper.databaseVersion, 0);
      final remaining = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
        " AND name NOT LIKE 'sqlite_%'",
      );
      expect(remaining, isEmpty);

      await runner.run(db, 0, DatabaseHelper.databaseVersion);
      final after = await _schemaSnapshot(db);
      expect(after, before);

      await db.close();
    });

    test('resetDatabase wipes data and reseeds the default pantry', () async {
      final helper = DatabaseHelper.withPath(uniqueTestDbPath());
      final db = await helper.database;
      await db.insert('products', {'barcode': '123', 'name': 'Test'});
      await db.insert('inventory', {'barcode': '123', 'inventory_id': 1});
      expect(await db.query('products'), hasLength(1));

      await helper.resetDatabase();

      expect(await db.query('products'), isEmpty);
      expect(await db.query('inventory'), isEmpty);
      final inventories = await db.query('inventories');
      expect(inventories, hasLength(1));
      expect(inventories.single['name'], 'Home');

      await db.close();
    });
  });
}
