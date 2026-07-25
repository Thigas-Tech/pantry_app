import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Version 27 was intentionally skipped.
///
/// It was originally meant to add `servings` and `image_path` columns to the
/// recipes table, but those columns already existed (added in the v25 CREATE
/// TABLE statement). The version number is skipped to avoid confusion with
/// published database versions. Migration v28 jumps directly from v26 to v28.
class MigrationV27 extends Migration {
  @override
  int get version => 27;

  @override
  Future<void> up(Database db) async {
    // Intentionally empty — see class doc comment.
  }
}
