import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the firebase_cache_meta table.
class MigrationV24 extends Migration {
  @override
  int get version => 24;

  @override
  Future<void> up(Database db) async {
    await const FirebaseCacheMetaDao().createTable(db);
  }
}
