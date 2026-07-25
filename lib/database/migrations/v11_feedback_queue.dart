import 'package:pantry_app/database/feedback_queue_dao.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the feedback_queue table.
class MigrationV11 extends Migration {
  @override
  int get version => 11;

  @override
  Future<void> up(Database db) async {
    await const FeedbackQueueDao().createTable(db);
  }
}
