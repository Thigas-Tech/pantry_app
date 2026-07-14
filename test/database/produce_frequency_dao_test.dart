import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/produce_frequency_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  final dao = ProduceFrequencyDao();

  setUp(() async {
    dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
    await dbHelper.database;
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.close();
  });

  group('ProduceFrequencyDao', () {
    test('increment inserts new key with count 1', () async {
      final db = await dbHelper.database;
      await dao.increment('apple', db);
      final all = await dao.getAll(db);
      expect(all['apple'], 1);
    });

    test('increment increases existing count', () async {
      final db = await dbHelper.database;
      await dao.increment('apple', db);
      await dao.increment('apple', db);
      await dao.increment('apple', db);
      final all = await dao.getAll(db);
      expect(all['apple'], 3);
    });

    test('decrement reduces count', () async {
      final db = await dbHelper.database;
      await dao.increment('apple', db);
      await dao.increment('apple', db);
      await dao.decrement('apple', db);
      final all = await dao.getAll(db);
      expect(all['apple'], 1);
    });

    test('decrement does not go below zero', () async {
      final db = await dbHelper.database;
      await dao.increment('apple', db);
      await dao.decrement('apple', db);
      await dao.decrement('apple', db);
      await dao.decrement('apple', db);
      final all = await dao.getAll(db);
      expect(all['apple'], 0);
    });

    test('getTopPurchases returns items ordered by count desc', () async {
      final db = await dbHelper.database;
      await dao.increment('apple', db);
      await dao.increment('apple', db);
      await dao.increment('banana', db);
      await dao.increment('carrot', db);
      await dao.increment('carrot', db);
      await dao.increment('carrot', db);
      final top = await dao.getTopPurchases(db, limit: 3);
      expect(top.length, 3);
      expect(top[0]['produce_key'], 'carrot');
      expect(top[0]['count'], 3);
      expect(top[1]['produce_key'], 'apple');
      expect(top[1]['count'], 2);
      expect(top[2]['produce_key'], 'banana');
      expect(top[2]['count'], 1);
    });

    test('getTopPurchases respects limit', () async {
      final db = await dbHelper.database;
      await dao.increment('apple', db);
      await dao.increment('banana', db);
      await dao.increment('carrot', db);
      final top = await dao.getTopPurchases(db, limit: 2);
      expect(top.length, 2);
    });

    test('getAll returns empty map when no purchases', () async {
      final db = await dbHelper.database;
      final all = await dao.getAll(db);
      expect(all, isEmpty);
    });
  });
}
