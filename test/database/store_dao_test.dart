import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/store_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late StoreDao dao;

  setUp(() async {
    dao = const StoreDao();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await dao.createTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('StoreDao', () {
    test('createTable creates the table', () async {
      final id = await dao.insert(db, 'Test Store');
      expect(id, isNonNegative);
    });

    test('insert and getAll', () async {
      await dao.insert(db, 'Walmart');
      await dao.insert(db, 'Costco');

      final stores = await dao.getAll(db);
      expect(stores.length, 2);
      expect(stores.map((s) => s.name), containsAll(['Walmart', 'Costco']));
    });

    test('getAll returns stores ordered by name', () async {
      await dao.insert(db, 'Zara');
      await dao.insert(db, 'Aldi');
      await dao.insert(db, 'Target');

      final stores = await dao.getAll(db);
      expect(stores.map((s) => s.name), ['Aldi', 'Target', 'Zara']);
    });

    test('insert trims whitespace', () async {
      final id = await dao.insert(db, '  Walmart  ');
      expect(id, isNonNegative);

      final store = await dao.getByName(db, 'Walmart');
      expect(store, isNotNull);
      expect(store!.name, 'Walmart');
    });

    test('insert rejects empty string', () async {
      final id = await dao.insert(db, '');
      expect(id, -1);
    });

    test('insert rejects whitespace-only name', () async {
      final id = await dao.insert(db, '   ');
      expect(id, -1);
    });

    test('insert case-insensitive duplicate returns existing id', () async {
      final id1 = await dao.insert(db, 'Walmart');
      final id2 = await dao.insert(db, 'walmart');

      expect(id1, id2);
      final stores = await dao.getAll(db);
      expect(stores.length, 1);
    });

    test('getByName returns store for exact match', () async {
      await dao.insert(db, 'Costco');
      final store = await dao.getByName(db, 'Costco');
      expect(store, isNotNull);
      expect(store!.name, 'Costco');
    });

    test('getByName is case-insensitive', () async {
      await dao.insert(db, 'Walmart');
      final store = await dao.getByName(db, 'WALMART');
      expect(store, isNotNull);
      expect(store!.name, 'Walmart');
    });

    test('getByName returns null for non-existent store', () async {
      final store = await dao.getByName(db, 'Nonexistent');
      expect(store, isNull);
    });

    test('getByName returns null for empty input', () async {
      await dao.insert(db, 'Walmart');
      final store = await dao.getByName(db, '');
      expect(store, isNull);
    });

    test('delete removes store', () async {
      final id = await dao.insert(db, 'Walmart');
      await dao.delete(db, id);

      final stores = await dao.getAll(db);
      expect(stores, isEmpty);
    });

    test('truncates names longer than 100 characters', () async {
      final longName = 'A' * 150;
      final id = await dao.insert(db, longName);
      expect(id, isNonNegative);

      final stores = await dao.getAll(db);
      expect(stores.length, 1);
      expect(stores[0].name.length, 100);
    });
  });
}
