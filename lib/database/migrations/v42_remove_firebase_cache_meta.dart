import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Drops the firebase_cache_meta table.
///
/// The table tracked per-entry refresh metadata for the Firebase cache.
/// That intermediate cache has been removed, so the table is no longer
/// needed. The drop is idempotent: fresh installs never create the table
/// (v24 is no longer registered), while upgraded installs lose it here.
class MigrationV42 extends Migration {
  @override
  int get version => 42;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('DROP TABLE IF EXISTS firebase_cache_meta');
      logInfo('Migration v42 completed (firebase_cache_meta dropped)');
    } on Exception catch (e) {
      logWarning('Migration v42 failed: $e');
      rethrow;
    }
  }
}
