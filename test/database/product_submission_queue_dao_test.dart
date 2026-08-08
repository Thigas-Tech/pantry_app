/// @file ProductSubmissionQueueDao unit tests.
///
/// Tests the product submission queue table with an injected clock so
/// backoff scheduling is deterministic and tests never wait for real
/// minutes. Covers insert, pending filtering, exponential backoff,
/// retry exhaustion, counts, and persistence across instances.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/product_submission_queue_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DateTime currentTime;
  late ProductSubmissionQueueDao dao;

  DateTime fakeNow() => currentTime;

  setUp(() async {
    currentTime = DateTime(2026, 1, 1, 12);
    dao = ProductSubmissionQueueDao(now: fakeNow);
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await dao.createTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductSubmissionQueueDao', () {
    test('insert stamps timestamps from the injected clock', () async {
      await dao.insert(db, '123');

      final rows = await db.query('product_submission_queue');
      expect(rows.single['barcode'], '123');
      expect(rows.single['retry_count'], 0);
      expect(
        rows.single['created_at'],
        currentTime.millisecondsSinceEpoch,
      );
      expect(
        rows.single['next_retry_at'],
        currentTime.millisecondsSinceEpoch,
      );
    });

    test('insert is a no-op for an already queued barcode', () async {
      await dao.insert(db, '123');
      await dao.insert(db, '123');

      final rows = await db.query('product_submission_queue');
      expect(rows.length, 1);
    });

    test('getPending returns only entries due at the injected now', () async {
      final now = currentTime.millisecondsSinceEpoch;
      final future = currentTime
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      await db.insert('product_submission_queue', {
        'barcode': 'due',
        'retry_count': 0,
        'max_retries': 5,
        'next_retry_at': now,
        'created_at': now,
      });
      await db.insert('product_submission_queue', {
        'barcode': 'future',
        'retry_count': 0,
        'max_retries': 5,
        'next_retry_at': future,
        'created_at': now,
      });

      final pending = await dao.getPending(db);
      expect(pending.map((r) => r['barcode']), ['due']);
    });

    test(
      'incrementRetry schedules exponential backoff from the clock',
      () async {
        await dao.insert(db, '123');
        final id =
            (await db.query('product_submission_queue')).single['id']! as int;

        await dao.incrementRetry(db, id);
        var row = (await db.query(
          'product_submission_queue',
          where: 'id = ?',
          whereArgs: [id],
        )).single;
        expect(row['retry_count'], 1);
        expect(
          row['next_retry_at'],
          currentTime.add(const Duration(minutes: 2)).millisecondsSinceEpoch,
        );

        await dao.incrementRetry(db, id);
        row = (await db.query(
          'product_submission_queue',
          where: 'id = ?',
          whereArgs: [id],
        )).single;
        expect(row['retry_count'], 2);
        expect(
          row['next_retry_at'],
          currentTime.add(const Duration(minutes: 4)).millisecondsSinceEpoch,
        );
      },
    );

    test(
      'incrementRetry removes the entry once retries are exhausted',
      () async {
        await db.insert('product_submission_queue', {
          'barcode': '123',
          'retry_count': 1,
          'max_retries': 2,
          'next_retry_at': currentTime.millisecondsSinceEpoch,
          'created_at': currentTime.millisecondsSinceEpoch,
        });
        final id =
            (await db.query('product_submission_queue')).single['id']! as int;

        await dao.incrementRetry(db, id);

        final rows = await db.query('product_submission_queue');
        expect(rows, isEmpty);
      },
    );

    test('countPending counts only entries due at the injected now', () async {
      final now = currentTime.millisecondsSinceEpoch;
      final future = currentTime
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      await db.insert('product_submission_queue', {
        'barcode': 'due',
        'retry_count': 0,
        'max_retries': 5,
        'next_retry_at': now,
        'created_at': now,
      });
      await db.insert('product_submission_queue', {
        'barcode': 'future',
        'retry_count': 0,
        'max_retries': 5,
        'next_retry_at': future,
        'created_at': now,
      });

      expect(await dao.countPending(db), 1);
    });

    test('queue entries persist across DAO instances and reopens', () async {
      final dir = Directory.systemTemp.createTempSync('pantry_queue_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/queue.db';

      final first = await databaseFactory.openDatabase(path);
      await dao.createTable(first);
      await dao.insert(first, '123');
      await first.close();

      final second = await databaseFactory.openDatabase(path);
      final reopened = ProductSubmissionQueueDao(now: fakeNow);
      final pending = await reopened.getPending(second);
      expect(pending.length, 1);
      expect(pending.single['barcode'], '123');
      await second.close();
    });
  });
}
