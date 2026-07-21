import 'package:pantry_app/services/github_issue_service.dart';
import 'package:sqflite/sqflite.dart';

/// DAO for the feedback_queue table.
///
/// Stores issues that could not be submitted immediately (e.g. because the
/// device was offline). When connectivity is restored, the pending rows are
/// flushed to the GitHub Issues API by [GithubIssueService.flushQueue].
class FeedbackQueueDao {
  /// Creates a [FeedbackQueueDao].
  const FeedbackQueueDao();

  /// Creates the feedback_queue table if it does not exist.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS feedback_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        label TEXT,
        screenshot_path TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        failed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Inserts a queued issue. Returns the row id.
  Future<int> insert(
    Database db, {
    required String title,
    required String body,
    String? label,
    String? screenshotPath,
  }) {
    return db.insert('feedback_queue', {
      'title': title,
      'body': body,
      'label': label,
      'screenshot_path': screenshotPath,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Returns all pending (non-failed) rows ordered by creation time.
  Future<List<Map<String, dynamic>>> getAllPending(Database db) {
    return db.query(
      'feedback_queue',
      where: 'failed = 0',
      orderBy: 'created_at ASC',
    );
  }

  /// Deletes a row by [id].
  Future<void> delete(Database db, int id) async {
    await db.delete('feedback_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Increments the retry count for a row.
  Future<void> incrementRetry(Database db, int id) async {
    await db.rawUpdate(
      'UPDATE feedback_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// Marks a row as permanently failed.
  Future<void> markFailed(Database db, int id) async {
    await db.update(
      'feedback_queue',
      {'failed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes failed rows older than [olderThanDays] days.
  Future<int> deleteStaleFailures(Database db, {int olderThanDays = 30}) {
    final cutoff = DateTime.now()
        .subtract(Duration(days: olderThanDays))
        .millisecondsSinceEpoch;
    return db.delete(
      'feedback_queue',
      where: 'failed = 1 AND created_at < ?',
      whereArgs: [cutoff],
    );
  }
}
