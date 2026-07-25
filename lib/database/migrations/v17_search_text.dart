import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/utils/search_utils.dart';
import 'package:sqflite/sqflite.dart';

/// Adds search_text column to products, backfills existing rows, and
/// creates an index.
class MigrationV17 extends Migration {
  @override
  int get version => 17;

  @override
  Future<void> up(Database db) async {
    if (!await columnExists(db, 'products', 'search_text')) {
      await db.execute('ALTER TABLE products ADD COLUMN search_text TEXT');
    }

    final allProducts = await const ProductDao().all(db);
    if (allProducts.isNotEmpty) {
      await db.transaction((txn) async {
        for (final product in allProducts) {
          await txn.update(
            'products',
            {'search_text': buildSearchText(product)},
            where: 'barcode = ?',
            whereArgs: [product.barcode],
          );
        }
      });
    }

    final existingIndex = await db.rawQuery(
      'SELECT name FROM sqlite_master'
      " WHERE type='index' AND name='idx_search_text'",
    );
    if (existingIndex.isEmpty) {
      await db.execute(
        'CREATE INDEX idx_search_text ON products(search_text)',
      );
    }
  }
}
