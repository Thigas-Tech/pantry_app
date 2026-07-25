import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/store_dao.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the stores table and backfills from prices and shopping_list.
class MigrationV19 extends Migration {
  @override
  int get version => 19;

  @override
  Future<void> up(Database db) async {
    await const StoreDao().createTable(db);

    await db.execute(
      'INSERT OR IGNORE INTO stores (name)'
      ' SELECT DISTINCT TRIM(store) FROM prices'
      " WHERE store IS NOT NULL AND TRIM(store) != ''",
    );
    await db.execute(
      'INSERT OR IGNORE INTO stores (name)'
      ' SELECT DISTINCT TRIM(price_store) FROM shopping_list'
      " WHERE price_store IS NOT NULL AND TRIM(price_store) != ''",
    );
  }
}
