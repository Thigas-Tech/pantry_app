import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v37 prices package', () {
    /// Builds a database at schema version 36 (pre-v37) with a price and a
    /// product row. Mirrors the state of existing installs upgrading to v37.
    Future<Database> buildPreV37Db() async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 36);

      await db.insert('inventories', {'name': 'Home', 'created_at': 1});
      await db.insert('products', {
        'barcode': '123',
        'name': 'Eggs',
        'source': 'manual',
      });
      await db.insert('prices', {
        'barcode': '123',
        'price': 9.99,
        'currency': 'USD',
        'inventory_id': 1,
        'date_added': DateTime.now().millisecondsSinceEpoch,
        'date_purchased': 1000,
      });
      return db;
    }

    test('adds package columns to prices', () async {
      final db = await buildPreV37Db();
      await MigrationRunner(allMigrations()).run(db, 36, 37);

      expect(await columnExists(db, 'prices', 'package_quantity'), isTrue);
      expect(await columnExists(db, 'prices', 'package_unit'), isTrue);

      await db.close();
    });

    test('adds packaging columns to products', () async {
      final db = await buildPreV37Db();
      await MigrationRunner(allMigrations()).run(db, 36, 37);

      expect(await columnExists(db, 'products', 'quantity'), isTrue);
      expect(await columnExists(db, 'products', 'product_quantity'), isTrue);

      await db.close();
    });

    test('preserves existing rows', () async {
      final db = await buildPreV37Db();
      await MigrationRunner(allMigrations()).run(db, 36, 37);

      final priceRows = await db.rawQuery(
        'SELECT price, package_quantity, package_unit FROM prices'
        " WHERE barcode = '123'",
      );
      expect(priceRows, isNotEmpty);
      expect(priceRows.first['price'], 9.99);
      expect(priceRows.first['package_quantity'], isNull);
      expect(priceRows.first['package_unit'], isNull);

      final productRows = await db.rawQuery(
        'SELECT barcode, quantity, product_quantity FROM products'
        " WHERE barcode = '123'",
      );
      expect(productRows, isNotEmpty);
      expect(productRows.first['quantity'], isNull);
      expect(productRows.first['product_quantity'], isNull);

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await buildPreV37Db();
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 36, 37);
      await runner.run(db, 36, 37);

      expect(await columnExists(db, 'prices', 'package_quantity'), isTrue);
      expect(await columnExists(db, 'prices', 'package_unit'), isTrue);
      expect(await columnExists(db, 'products', 'quantity'), isTrue);
      expect(await columnExists(db, 'products', 'product_quantity'), isTrue);

      await db.close();
    });
  });
}
