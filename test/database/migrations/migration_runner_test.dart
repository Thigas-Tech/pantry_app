import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A simple migration that creates a version column in a test table.
class _TestMigrationV1 extends Migration {
  @override
  int get version => 1;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('CREATE TABLE test_table (id INTEGER)');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    await db.execute('DROP TABLE IF EXISTS test_table');
  }
}

/// A second migration that adds a name column.
class _TestMigrationV2 extends Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE test_table ADD COLUMN name TEXT');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE test_table DROP COLUMN name');
  }
}

/// A migration that always fails on the way up.
class _FailingMigration extends Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(DatabaseExecutor db) {
    throw Exception('Intentional failure');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {}
}

/// A migration that always fails on the way down.
class _FailingDownMigration extends Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE test_table ADD COLUMN extra TEXT');
  }

  @override
  Future<void> down(DatabaseExecutor db) {
    throw Exception('Intentional rollback failure');
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MigrationRunner up', () {
    test('runs only versions > oldVersion', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE test_table (id INTEGER)');

      final runner = MigrationRunner([_TestMigrationV2()]);

      await runner.run(db, 1, 2);

      final columns = await db.rawQuery("PRAGMA table_info('test_table')");
      final columnNames = columns.map((c) => c['name'] as String?).toList();
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
      final columnNames = columns.map((c) => c['name'] as String?).toList();
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

    test('throws on a migration failure', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      final runner = MigrationRunner([
        _TestMigrationV1(),
        _TestMigrationV2(),
        _FailingMigration(),
      ]);

      await expectLater(
        runner.run(db, 0, 3),
        throwsA(isA<Exception>()),
      );

      // Earlier migrations ran, but the exception propagates so the
      // surrounding upgrade transaction can roll back and retry later.
      final columns = await db.rawQuery("PRAGMA table_info('test_table')");
      final columnNames = columns.map((c) => c['name'] as String?).toList();
      expect(columnNames, contains('id'));

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

  group('MigrationRunner down', () {
    test('runs versions in descending order within the window', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await MigrationRunner([
        _TestMigrationV1(),
        _TestMigrationV2(),
      ]).run(db, 0, 2);

      final order = <int>[];
      final runner = MigrationRunner([
        _OrderTrackingMigration(1, order),
        _OrderTrackingMigration(2, order),
      ]);

      final result = await runner.runDown(db, 2, 0);

      expect(order, [2, 1]);
      expect(result.succeeded, containsAll([1, 2]));
      expect(result.nothingToRollback, isFalse);
      expect(result.isSuccess, isTrue);

      await db.close();
    });

    test('skips versions <= toVersion', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await MigrationRunner([
        _TestMigrationV1(),
        _TestMigrationV2(),
      ]).run(db, 0, 2);

      final order = <int>[];
      final result = await MigrationRunner([
        _OrderTrackingMigration(1, order),
        _OrderTrackingMigration(2, order),
      ]).runDown(db, 2, 1);

      expect(order, [2]);
      expect(result.succeeded, contains(2));
      expect(result.succeeded, isNot(contains(1)));

      await db.close();
    });

    test('nothingToRollback is true when no versions run', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      final result = await MigrationRunner([
        _TestMigrationV1(),
      ]).runDown(db, 1, 1);

      expect(result.nothingToRollback, isTrue);

      await db.close();
    });

    test('throws on a rollback failure', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await MigrationRunner([
        _TestMigrationV1(),
        _FailingDownMigration(),
      ]).run(db, 0, 3);

      await expectLater(
        MigrationRunner([
          _TestMigrationV1(),
          _FailingDownMigration(),
        ]).runDown(db, 3, 0),
        throwsA(isA<Exception>()),
      );

      await db.close();
    });

    test('down drops the schema created by up', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      await MigrationRunner([_TestMigrationV1()]).run(db, 0, 1);
      final before = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
        " AND name NOT LIKE 'sqlite_%'",
      );
      expect(before, isNotEmpty);

      await MigrationRunner([_TestMigrationV1()]).runDown(db, 1, 0);
      final after = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
        " AND name NOT LIKE 'sqlite_%'",
      );
      expect(after, isEmpty);

      await db.close();
    });
  });
}

/// A migration that records the order in which [up] and [down] run.
class _OrderTrackingMigration extends Migration {
  _OrderTrackingMigration(this._version, this._order);

  final int _version;
  final List<int> _order;

  @override
  int get version => _version;

  @override
  Future<void> up(DatabaseExecutor db) async {
    _order.add(_version);
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    _order.add(_version);
  }
}
