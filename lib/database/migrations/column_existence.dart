import 'package:sqflite/sqflite.dart';

/// Returns true when [column] exists in [table] in the given SQLite database.
///
/// Uses `PRAGMA table_info` to introspect the schema. Works for any table
/// regardless of whether it was created via `CREATE TABLE` or
/// `CREATE TABLE IF NOT EXISTS`.
Future<bool> columnExists(Database db, String table, String column) async {
  final columns = await db.rawQuery("PRAGMA table_info('$table')");
  for (final col in columns) {
    final name = col['name'];
    if (name != null && name == column) return true;
  }
  return false;
}

/// Returns the list of column names for [table].
///
/// Each entry is the bare column name as returned by `PRAGMA table_info`.
Future<List<String>> tableColumns(Database db, String table) async {
  final columns = await db.rawQuery("PRAGMA table_info('$table')");
  return columns.map((c) => c['name'] as String? ?? '').toList();
}
