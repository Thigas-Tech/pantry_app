import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v39 inventory and shopping-list indexes', () {
    Future<Database> buildV38Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 38);
      return db;
    }

    Future<Set<String>> indexNames(Database db) async {
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'"
        " AND name NOT LIKE 'sqlite_%'",
      );
      return rows.map((r) => r['name']! as String).toSet();
    }

    test('adds the composite inventory and shopping-list indexes', () async {
      final db = await buildV38Db();
      await MigrationRunner(allMigrations()).run(db, 38, 39);

      final indexes = await indexNames(db);
      expect(
        indexes,
        containsAll([
          'idx_inventory_inventory_expiry',
          'idx_shopping_list_inventory_purchased_date',
        ]),
      );
    });

    test('is idempotent when run twice', () async {
      final db = await buildV38Db();
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 38, 39);
      await runner.run(db, 38, 39);

      final indexes = await indexNames(db);
      expect(indexes, contains('idx_inventory_inventory_expiry'));
      expect(indexes, contains('idx_shopping_list_inventory_purchased_date'));
    });
  });
}
