import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/product_submission_queue_dao.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the product_submission_queue table.
class MigrationV16 extends Migration {
  @override
  int get version => 16;

  @override
  Future<void> up(Database db) async {
    await const ProductSubmissionQueueDao().createTable(db);
  }
}
