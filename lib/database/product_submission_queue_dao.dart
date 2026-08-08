import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the product_submission_queue table.
///
/// This table holds barcodes of products that the user attempted to submit
/// to Open Food Facts while offline. Rows are inserted when a submission
/// fails (network error) and removed when the submission succeeds. A
/// startup task and connectivity-change listener process the queue.
class ProductSubmissionQueueDao {
  /// Creates a [ProductSubmissionQueueDao].
  ///
  /// [now] is the clock used for all timestamps and due-date comparisons;
  /// tests inject a fake clock so backoff scheduling never waits for real
  /// minutes. Defaults to [DateTime.now].
  ProductSubmissionQueueDao({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Creates the product_submission_queue table.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE product_submission_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL UNIQUE,
        retry_count INTEGER NOT NULL DEFAULT 0,
        max_retries INTEGER NOT NULL DEFAULT 5,
        next_retry_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_submission_queue_retry'
      ' ON product_submission_queue(next_retry_at)',
    );
  }

  /// Queues a barcode for submission. If the barcode is already queued,
  /// this is a no-op due to the UNIQUE constraint.
  Future<void> insert(Database db, String barcode) async {
    logInfo('Queuing submission for barcode $barcode');
    try {
      final now = _now().millisecondsSinceEpoch;
      await db.insert(
        'product_submission_queue',
        {
          'barcode': barcode,
          'retry_count': 0,
          'max_retries': 5,
          'next_retry_at': now,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      logInfo('Submission queued for barcode $barcode');
    } on Exception catch (e) {
      logError('Failed to queue submission for $barcode: $e');
      rethrow;
    }
  }

  /// Returns all queue entries that are ready for retry (next_retry_at
  /// is in the past or null).
  Future<List<Map<String, dynamic>>> getPending(Database db) async {
    try {
      final now = _now().millisecondsSinceEpoch;
      final result = await db.query(
        'product_submission_queue',
        where: 'next_retry_at IS NULL OR next_retry_at <= ?',
        whereArgs: [now],
        orderBy: 'created_at ASC',
      );
      return result;
    } on Exception catch (e) {
      logError('Failed to get pending submission queue: $e');
      rethrow;
    }
  }

  /// Increments the retry count and sets next_retry_at with exponential
  /// backoff: 2^retry * 1 minute, capped at 24 hours.
  Future<void> incrementRetry(Database db, int id) async {
    logInfo('Incrementing retry for queue entry $id');
    try {
      final row = await db.query(
        'product_submission_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (row.isEmpty) return;

      final retryCount = (row.first['retry_count'] as int? ?? 0) + 1;
      final maxRetries = row.first['max_retries'] as int? ?? 5;

      if (retryCount >= maxRetries) {
        await db.delete(
          'product_submission_queue',
          where: 'id = ?',
          whereArgs: [id],
        );
        logWarning(
          'Queue entry $id exhausted after $retryCount retries — removed',
        );
        return;
      }

      // Exponential backoff: 2^retry minutes, capped at 1440 (24h).
      final delayMinutes = (1 << retryCount).clamp(1, 1440);
      final nextRetry = _now()
          .add(Duration(minutes: delayMinutes))
          .millisecondsSinceEpoch;

      await db.update(
        'product_submission_queue',
        {
          'retry_count': retryCount,
          'next_retry_at': nextRetry,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      logInfo(
        'Queue entry $id retry $retryCount, next retry in $delayMinutes min',
      );
    } on Exception catch (e) {
      logError('Failed to increment retry for queue entry $id: $e');
      rethrow;
    }
  }

  /// Removes a queue entry after successful submission.
  Future<void> delete(Database db, int id) async {
    logInfo('Removing queue entry $id');
    try {
      await db.delete(
        'product_submission_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
    } on Exception catch (e) {
      logError('Failed to delete queue entry $id: $e');
      rethrow;
    }
  }

  /// Removes all queue entries for a given barcode (e.g. after successful
  /// submission).
  Future<void> deleteByBarcode(Database db, String barcode) async {
    logInfo('Removing queue entries for barcode $barcode');
    try {
      await db.delete(
        'product_submission_queue',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    } on Exception catch (e) {
      logError('Failed to delete queue entries for $barcode: $e');
      rethrow;
    }
  }

  /// Returns the count of pending (not yet maxed out) queue entries.
  Future<int> countPending(Database db) async {
    final now = _now().millisecondsSinceEpoch;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM product_submission_queue'
            ' WHERE next_retry_at <= ?',
            [now],
          ),
        ) ??
        0;
  }

  /// Returns true when the given [barcode] already has a queue entry.
  Future<bool> isQueued(Database db, String barcode) async {
    final result = await db.query(
      'product_submission_queue',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
