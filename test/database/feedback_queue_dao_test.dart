/// @file FeedbackQueueDao unit tests.
///
/// Tests all 7 DAO methods using an in-memory SQLite database via
/// [sqfliteFfiInit].  Verifies CRUD, filtering, retry, and
/// stale-cleanup operations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/feedback_queue_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late FeedbackQueueDao dao;

  setUp(() async {
    dao = const FeedbackQueueDao();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await dao.createTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('FeedbackQueueDao', () {
    /// Verifies [createTable] creates the table so inserts can succeed.
    test('createTable creates the table', () async {
      final id = await dao.insert(
        db,
        title: 'Test',
        body: 'Body',
      );
      expect(id, isNonNegative);
    });

    /// Verifies [insert] stores the row and returns a non-null id.
    test('insert stores a row and returns id', () async {
      final id = await dao.insert(
        db,
        title: 'Bug report',
        body: 'Description of bug',
        label: 'bug',
        screenshotPath: '/tmp/shot.png',
      );
      expect(id, isNonNegative);

      final rows = await db.query('feedback_queue');
      expect(rows.length, 1);
      expect(rows.first['title'], 'Bug report');
      expect(rows.first['label'], 'bug');
      expect(rows.first['screenshot_path'], '/tmp/shot.png');
      expect(rows.first['retry_count'], 0);
      expect(rows.first['failed'], 0);
    });

    /// Verifies [getAllPending] returns only non-failed rows, ordered by
    /// creation time.
    test('getAllPending returns only non-failed rows', () async {
      await dao.insert(db, title: 'Pending 1', body: 'B1');
      await dao.insert(db, title: 'Pending 2', body: 'B2');

      final id3 = await dao.insert(db, title: 'Failed', body: 'B3');
      await dao.markFailed(db, id3);

      final pending = await dao.getAllPending(db);
      expect(pending.length, 2);
      expect(pending[0]['title'], 'Pending 1');
      expect(pending[1]['title'], 'Pending 2');
    });

    /// Verifies [delete] removes a row by id.
    test('delete removes a row', () async {
      final id = await dao.insert(db, title: 'To Delete', body: 'B');
      await dao.delete(db, id);

      final rows = await db.query('feedback_queue');
      expect(rows, isEmpty);
    });

    /// Verifies [incrementRetry] increases the retry count by 1.
    test('incrementRetry increases retry count', () async {
      final id = await dao.insert(db, title: 'Retry Test', body: 'B');

      await dao.incrementRetry(db, id);
      final rows1 = await db.query(
        'feedback_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows1.first['retry_count'], 1);

      await dao.incrementRetry(db, id);
      final rows2 = await db.query(
        'feedback_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows2.first['retry_count'], 2);
    });

    /// Verifies [markFailed] sets the failed flag to 1.
    test('markFailed sets failed flag', () async {
      final id = await dao.insert(db, title: 'Fail Test', body: 'B');
      await dao.markFailed(db, id);

      final rows = await db.query(
        'feedback_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows.first['failed'], 1);
    });

    /// Verifies [deleteStaleFailures] removes failed rows older than
    /// the specified number of days.
    test('deleteStaleFailures removes old failed rows', () async {
      final id = await dao.insert(db, title: 'Old', body: 'B');
      await dao.markFailed(db, id);

      // Manipulate the created_at to be older than 30 days.
      final oldTimestamp = DateTime.now()
          .subtract(const Duration(days: 31))
          .millisecondsSinceEpoch;
      await db.update(
        'feedback_queue',
        {'created_at': oldTimestamp},
        where: 'id = ?',
        whereArgs: [id],
      );

      final deleted = await dao.deleteStaleFailures(db);
      expect(deleted, 1);

      final rows = await db.query('feedback_queue');
      expect(rows, isEmpty);
    });

    /// Verifies [deleteStaleFailures] does not delete recent failures.
    test('deleteStaleFailures keeps recent failed rows', () async {
      final id = await dao.insert(db, title: 'Recent', body: 'B');
      await dao.markFailed(db, id);

      final deleted = await dao.deleteStaleFailures(db);
      expect(deleted, 0);

      final rows = await db.query('feedback_queue');
      expect(rows, isNotEmpty);
    });
  });
}
