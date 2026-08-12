import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v38 index optimizations', () {
    Future<Database> buildV37Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 37);
      return db;
    }

    Future<Set<String>> indexNames(Database db) async {
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'"
        " AND name NOT LIKE 'sqlite_%'",
      );
      return rows.map((r) => r['name']! as String).toSet();
    }

    test('adds the new composite and source indexes', () async {
      final db = await buildV37Db();
      await MigrationRunner(allMigrations()).run(db, 37, 38);

      final indexes = await indexNames(db);
      expect(
        indexes,
        containsAll([
          'idx_prices_barcode_inventory_date',
          'idx_recipes_inventory_updated',
          'idx_products_source',
        ]),
      );

      await db.close();
    });

    test('drops the redundant indexes', () async {
      final db = await buildV37Db();
      await MigrationRunner(allMigrations()).run(db, 37, 38);

      final indexes = await indexNames(db);
      expect(indexes, isNot(contains('idx_barcode')));
      expect(indexes, isNot(contains('idx_inventory_barcode')));

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildV37Db();
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 37, 38);
      await runner.run(db, 37, 38);

      final indexes = await indexNames(db);
      expect(
        indexes,
        containsAll([
          'idx_prices_barcode_inventory_date',
          'idx_recipes_inventory_updated',
          'idx_products_source',
        ]),
      );

      await db.close();
    });
  });
}
