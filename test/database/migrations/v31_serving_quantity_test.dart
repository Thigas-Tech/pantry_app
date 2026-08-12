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

  group('v31 serving quantity', () {
    /// Builds a database at schema version 30 (pre-v31) with a product row.
    /// Mirrors the state of existing installs upgrading to v31.
    Future<Database> buildPreV31Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 30);
      await db.insert('products', {
        'barcode': '123',
        'name': 'Coke',
        'source': 'manual',
      });
      return db;
    }

    test('adds serving_quantity column to products', () async {
      final db = await buildPreV31Db();
      await MigrationRunner(allMigrations()).run(db, 30, 31);

      expect(
        await columnExists(db, 'products', 'serving_quantity'),
        isTrue,
      );

      await db.close();
    });

    test('existing rows have serving_quantity set to null', () async {
      final db = await buildPreV31Db();
      await MigrationRunner(allMigrations()).run(db, 30, 31);

      final rows = await db.rawQuery(
        'SELECT barcode, serving_quantity FROM products WHERE barcode = ?',
        ['123'],
      );
      expect(rows, isNotEmpty);
      expect(rows.first['serving_quantity'], isNull);

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildPreV31Db();
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 30, 31);
      await runner.run(db, 30, 31);

      // Verify column still exists after second run
      expect(
        await columnExists(db, 'products', 'serving_quantity'),
        isTrue,
      );

      await db.close();
    });
  });
}
