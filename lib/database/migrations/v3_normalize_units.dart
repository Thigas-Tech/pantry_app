import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Normalizes 'pcs' to 'pieces' in the inventory unit column.
class MigrationV3 extends Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(Database db) async {
    await db.rawUpdate(
      "UPDATE inventory SET unit = 'pieces' WHERE unit = 'pcs'",
    );
  }
}
