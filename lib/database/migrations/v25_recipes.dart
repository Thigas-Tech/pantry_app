import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/recipe_dao.dart';
import 'package:pantry_app/database/recipe_ingredient_dao.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the recipes and recipe_ingredients tables.
class MigrationV25 extends Migration {
  @override
  int get version => 25;

  @override
  Future<void> up(Database db) async {
    await const RecipeDao().createTable(db);
    await const RecipeIngredientDao().createTable(db);
  }
}
