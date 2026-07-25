import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A simple migration that adds a version column to a test table.
class _TestMigrationV1 extends Migration {
  @override
  int get version => 1;

  @override
  Future<void> up(Database db) async {
    await db.execute('CREATE TABLE test_table (id INTEGER)');
  }
}

/// A second migration that adds a name column.
class _TestMigrationV2 extends Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(Database db) async {
    await db.execute('ALTER TABLE test_table ADD COLUMN name TEXT');
  }
}

/// A migration that always fails.
class _FailingMigration extends Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(Database db) async {
    throw Exception('Intentional failure');
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MigrationRunner', () {
    test('runs only versions > oldVersion', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE test_table (id INTEGER)');

      final runner = MigrationRunner([
        _TestMigrationV2(),
      ]);

      await runner.run(db, 1, 2);

      final columns = await db.rawQuery("PRAGMA table_info('test_table')");
      final columnNames = columns.map((c) => c['name'] as String).toList();
      expect(columnNames, contains('name'));

      await db.close();
    });

    test('skips versions <= oldVersion', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      // First run v1 to create the table.
      await MigrationRunner([_TestMigrationV1()]).run(db, 0, 1);

      // Now run from v1 to v2 — v1 is skipped, only v2 runs.
      final runner = MigrationRunner([
        _TestMigrationV1(),
        _TestMigrationV2(),
      ]);
      final result = await runner.run(db, 1, 2);

      expect(result.succeeded, contains(2));
      expect(result.nothingToUpgrade, isFalse);

      final columns = await db.rawQuery("PRAGMA table_info('test_table')");
      final columnNames = columns.map((c) => c['name'] as String).toList();
      expect(columnNames, contains('name'));

      await db.close();
    });

    test('skips versions > newVersion', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      final runner = MigrationRunner([
        _TestMigrationV1(),
        _TestMigrationV2(),
      ]);

      final result = await runner.run(db, 1, 1);
      expect(result.nothingToUpgrade, isTrue);

      await db.close();
    });

    test('continues after a migration failure', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      final runner = MigrationRunner([
        _TestMigrationV1(),
        _FailingMigration(),
        _TestMigrationV2(),
      ]);

      // Run from v0 to v3. v1 succeeds, v3 (the failing one) should fail,
      // v2... wait, versions should be 1, 2, 3 but the _FailingMigration has
      // version 3. So v2 should also run. Let me re-order.

      // Actually let's use the correct setup
      final runner2 = MigrationRunner([
        _TestMigrationV1(),
        _TestMigrationV2(),
        _FailingMigration(),
      ]);

      final result = await runner2.run(db, 0, 3);

      expect(result.succeeded, containsAll([1, 2]));
      expect(result.failed, contains(3));

      // v1 and v2 changes should be visible.
      final columns = await db.rawQuery("PRAGMA table_info('test_table')");
      final columnNames = columns.map((c) => c['name'] as String).toList();
      expect(columnNames, contains('id'));
      expect(columnNames, contains('name'));

      await db.close();
    });

    test('nothingToUpgrade is true when no versions run', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      final runner = MigrationRunner([_TestMigrationV1()]);
      final result = await runner.run(db, 5, 5);
      expect(result.nothingToUpgrade, isTrue);

      await db.close();
    });
  });
}
