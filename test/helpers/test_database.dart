import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _counter = 0;

/// Returns a unique in-memory database path for a single test.
///
/// sqflite caches open databases by path, so tests that open more than one
/// database (or reopen after a close) must use distinct paths.
String uniqueTestDbPath() =>
    '$inMemoryDatabasePath${DateTime.now().microsecondsSinceEpoch}'
    '${_counter++}';

/// Applies the current schema to an already-open [db].
///
/// Runs every known migration from version 0 to the highest declared
/// version, mirroring a fresh production install.
Future<void> applySchema(Database db) async {
  final migrations = allMigrations();
  final version = migrations
      .map((m) => m.version)
      .reduce((a, b) => a > b ? a : b);
  await MigrationRunner(migrations).run(db, 0, version);
}

/// Opens an in-memory database with the current schema applied.
Future<Database> openTestDatabase() async {
  final db = await databaseFactory.openDatabase(uniqueTestDbPath());
  await applySchema(db);
  return db;
}
