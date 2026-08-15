import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds an optional expiry date to shopping list items so a market trip can
/// carry expiry dates captured at scan time into the pantry on finish.
///
/// The column mirrors the canonical ISO 8601 (YYYY-MM-DD) format used by the
/// inventory expiry_date column. The [columnExists] guard keeps the migration
/// idempotent when the fresh-install path (v13) already created the column.
class MigrationV45 extends Migration {
  @override
  int get version => 45;

  @override
  Future<void> up(Database db) async {
    try {
      if (!await columnExists(db, 'shopping_list', 'expiry_date')) {
        await db.execute(
          'ALTER TABLE shopping_list ADD COLUMN expiry_date TEXT',
        );
      }
      logInfo('Migration v45 completed (shopping_list expiry_date)');
    } on Exception catch (e) {
      logWarning('Migration v45 failed: $e');
      rethrow;
    }
  }
}
