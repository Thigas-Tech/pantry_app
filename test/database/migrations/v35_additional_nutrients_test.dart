import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v35 additional nutrients', () {
    /// Builds a database at schema version 34 (pre-v35) with a product row.
    /// Mirrors the state of existing installs upgrading to v35.
    Future<Database> buildPreV35Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 34);
      await db.insert('products', {
        'barcode': '123',
        'name': 'Coffee',
        'source': 'manual',
      });
      return db;
    }

    test('adds additional_nutrients column to products', () async {
      final db = await buildPreV35Db();
      await MigrationRunner(allMigrations()).run(db, 34, 35);

      expect(
        await columnExists(db, 'products', 'additional_nutrients'),
        isTrue,
      );

      await db.close();
    });

    test('existing rows keep their data after the upgrade', () async {
      final db = await buildPreV35Db();
      await MigrationRunner(allMigrations()).run(db, 34, 35);

      final rows = await db.rawQuery(
        "SELECT barcode, name FROM products WHERE barcode = '123'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first['name'], 'Coffee');

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildPreV35Db();
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 34, 35);
      await runner.run(db, 34, 35);

      expect(
        await columnExists(db, 'products', 'additional_nutrients'),
        isTrue,
      );

      await db.close();
    });
  });
}
