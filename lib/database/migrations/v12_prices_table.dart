import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/price_dao.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the prices table with indexes.
class MigrationV12 extends Migration {
  @override
  int get version => 12;

  @override
  Future<void> up(Database db) async {
    await const PriceDao().createTable(db);
  }
}
