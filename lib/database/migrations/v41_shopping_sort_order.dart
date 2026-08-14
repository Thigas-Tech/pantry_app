import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds a sort_order column to the shopping_list table.
///
/// Stores the manual drag-to-reorder position for pending items. Existing
/// rows are backfilled so pending items keep their current date-added
/// ordering (newest first) and purchased items keep zero, so nothing moves
/// visually after upgrade.
class MigrationV41 extends Migration {
  @override
  int get version => 41;

  @override
  Future<void> up(Database db) async {
    try {
      if (!await columnExists(db, 'shopping_list', 'sort_order')) {
        await db.execute(
          'ALTER TABLE shopping_list ADD COLUMN sort_order REAL'
          ' NOT NULL DEFAULT 0',
        );
      }
      final pending = await db.rawQuery(
        'SELECT id FROM shopping_list WHERE is_purchased = 0'
        ' ORDER BY inventory_id ASC, date_added DESC',
      );
      for (var i = 0; i < pending.length; i++) {
        await db.update(
          'shopping_list',
          {'sort_order': i + 1},
          where: 'id = ?',
          whereArgs: [pending[i]['id']],
        );
      }
      logInfo('Migration v41 completed (shopping_list.sort_order)');
    } on Exception catch (e) {
      logWarning('Migration v41 failed: $e');
      rethrow;
    }
  }
}
