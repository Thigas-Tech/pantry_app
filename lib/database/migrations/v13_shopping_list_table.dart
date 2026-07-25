import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the shopping_list table.
class MigrationV13 extends Migration {
  @override
  int get version => 13;

  @override
  Future<void> up(Database db) async {
    await const ShoppingListDao().createTable(db);
  }
}
