import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/recipe_history_dao.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the recipe_history table.
class MigrationV26 extends Migration {
  @override
  int get version => 26;

  @override
  Future<void> up(Database db) async {
    await const RecipeHistoryDao().createTable(db);
  }
}
