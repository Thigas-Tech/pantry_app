import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/inventories_dao.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late InventoriesDao dao;
  late InventoryDao inventoryDao;

  setUp(() async {
    dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
    await dbHelper.database;
    dao = const InventoriesDao();
    inventoryDao = const InventoryDao();
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.close();
  });

  test('create and list inventories', () async {
    final db = await dbHelper.database;
    await dao.create(db, 'Work');
    await dao.create(db, 'Camping');
    final list = await dao.list(db);
    expect(list.length, 3); // Home is seeded
    expect(
      list.map((e) => e['name']),
      containsAll(['Home', 'Work', 'Camping']),
    );
  });

  test('rename inventory', () async {
    final db = await dbHelper.database;
    final id = await dao.create(db, 'Old');
    await dao.rename(db, id, 'New');
    final list = await dao.list(db);
    final renamed = list.firstWhere((e) => e['id'] == id);
    expect(renamed['name'], 'New');
  });

  test('delete inventory removes items', () async {
    final db = await dbHelper.database;
    const productDao = ProductDao();
    await productDao.insert(db, const Product(barcode: '123', name: 'Temp'));

    final id = await dao.create(db, 'Temp');
    await inventoryDao.insert(
      db,
      InventoryItem(barcode: '123', inventoryId: id),
    );

    await dao.delete(db, id);

    final inventories = await dao.list(db);
    expect(inventories.any((e) => e['id'] == id), isFalse);

    final items = await inventoryDao.list(db, inventoryId: id);
    expect(items, isEmpty);
  });
}
