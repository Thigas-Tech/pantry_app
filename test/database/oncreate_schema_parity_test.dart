import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Returns a unique in-memory database path for each call so that sqflite
/// does not share state across tests.
String _uniqueDbPath() =>
    '$inMemoryDatabasePath'
    '${DateTime.now().microsecondsSinceEpoch}${_counter++}';
int _counter = 0;

Future<Set<String>> _tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table'"
    " AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((r) => r['name']! as String).toSet();
}

Future<Set<String>> _columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name']! as String).toSet();
}

Future<bool> _indexExists(Database db, String name) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='index' AND name = ?",
    [name],
  );
  return rows.isNotEmpty;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('fresh-install schema parity', () {
    test(
      'fresh install includes the v29 unique inventory index',
      () async {
        final db = DatabaseHelper.withPath(_uniqueDbPath());
        final database = await db.database;

        final exists = await _indexExists(
          database,
          'idx_inventory_barcode_inventory_id',
        );
        expect(exists, isTrue);
        await database.close();
      },
    );

    test(
      'fresh install includes the v30 recipe search_text column',
      () async {
        final db = DatabaseHelper.withPath(_uniqueDbPath());
        final database = await db.database;

        final columns = await _columnNames(database, 'recipes');
        expect(columns, contains('search_text'));
        await database.close();
      },
    );

    test(
      'fresh install includes the v30 recipe indexes',
      () async {
        final db = DatabaseHelper.withPath(_uniqueDbPath());
        final database = await db.database;

        for (final name in [
          'idx_recipes_name',
          'idx_recipes_created_at',
          'idx_recipes_updated_at',
        ]) {
          expect(
            await _indexExists(database, name),
            isTrue,
            reason: 'missing index $name',
          );
        }
        await database.close();
      },
    );

    test(
      'fresh install includes the v33 recipes inventory_id column',
      () async {
        final db = DatabaseHelper.withPath(_uniqueDbPath());
        final database = await db.database;

        final columns = await _columnNames(database, 'recipes');
        expect(columns, contains('inventory_id'));
        expect(
          await _indexExists(database, 'idx_recipes_inventory_id'),
          isTrue,
        );
        await database.close();
      },
    );

    test(
      'fresh install includes the v34 prices inventory_id column',
      () async {
        final db = DatabaseHelper.withPath(_uniqueDbPath());
        final database = await db.database;

        final columns = await _columnNames(database, 'prices');
        expect(columns, contains('inventory_id'));
        expect(
          await _indexExists(database, 'idx_prices_inventory_id'),
          isTrue,
        );
        await database.close();
      },
    );

    test(
      'fresh install includes the v35 products additional_nutrients column',
      () async {
        final db = DatabaseHelper.withPath(_uniqueDbPath());
        final database = await db.database;

        final columns = await _columnNames(database, 'products');
        expect(columns, contains('additional_nutrients'));
        await database.close();
      },
    );

    test(
      'onCreate schema matches a full migration replay (0 to 35)',
      () async {
        // Fresh-install path: onCreate builds the schema directly.
        final fresh = DatabaseHelper.withPath(_uniqueDbPath());
        final freshDb = await fresh.database;

        // Upgrade path: replay every migration from scratch.
        final replayDb = await databaseFactory.openDatabase(_uniqueDbPath());
        await MigrationRunner(allMigrations()).run(replayDb, 0, 35);

        final freshTables = await _tableNames(freshDb);
        final replayTables = await _tableNames(replayDb);
        expect(freshTables, replayTables);

        for (final table in freshTables) {
          final freshColumns = await _columnNames(freshDb, table);
          final replayColumns = await _columnNames(replayDb, table);
          expect(
            freshColumns,
            replayColumns,
            reason: 'column drift on table $table',
          );
        }

        await freshDb.close();
        await replayDb.close();
      },
    );
  });
}
