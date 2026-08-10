import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/models/product_nutrient.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Adds an additional_nutrients column to the products table.
///
/// The column stores the extra nutrients (beyond the six core nutrition
/// fields) as a JSON-encoded list of [ProductNutrient] entries.
class MigrationV35 extends Migration {
  @override
  int get version => 35;

  @override
  Future<void> up(Database db) async {
    try {
      if (!await columnExists(db, 'products', 'additional_nutrients')) {
        await db.execute(
          'ALTER TABLE products ADD COLUMN additional_nutrients TEXT',
        );
      }
      logInfo('Migration v35 completed (products additional_nutrients)');
    } on Exception catch (e) {
      logWarning('Migration v35 failed: $e');
      rethrow;
    }
  }
}
