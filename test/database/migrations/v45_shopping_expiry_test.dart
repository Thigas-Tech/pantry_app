import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/column_existence.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Unique in-memory path per call so sqflite does not share state across
/// tests (mirrors oncreate_schema_parity_test.dart).
String _uniqueDbPath() =>
    '$inMemoryDatabasePath'
    '${DateTime.now().microsecondsSinceEpoch}${_counter++}';
int _counter = 0;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v45 shopping expiry', () {
    /// Builds a database at schema version 44 (pre-v45) with a shopping item
    /// row, mirroring the state of existing installs upgrading to v45.
    Future<Database> buildPreV45Db() async {
      final db = await databaseFactory.openDatabase(_uniqueDbPath());
      final runner = MigrationRunner(allMigrations());
      await runner.run(db, 0, 44);

      await db.insert('inventories', {'name': 'Home', 'created_at': 1});
      await db.insert('products', {
        'barcode': '123',
        'name': 'Milk',
        'source': 'manual',
      });
      await db.insert('shopping_list', {
        'barcode': '123',
        'name': 'Milk',
        'quantity': 1.0,
        'unit': 'pieces',
        'is_purchased': 0,
        'inventory_id': 1,
        'date_added': DateTime.now().millisecondsSinceEpoch,
        'sort_order': 0,
      });
      return db;
    }

    test('adds the expiry_date column to shopping_list', () async {
      final db = await buildPreV45Db();
      await MigrationRunner(allMigrations()).run(db, 44, 45);

      expect(await columnExists(db, 'shopping_list', 'expiry_date'), isTrue);

      await db.close();
    });

    test('existing rows remain readable and expiry is null', () async {
      final db = await buildPreV45Db();
      await MigrationRunner(allMigrations()).run(db, 44, 45);

      final rows = await db.rawQuery(
        "SELECT * FROM shopping_list WHERE barcode = '123'",
      );
      expect(rows, hasLength(1));
      expect(rows.first['expiry_date'], isNull);

      await db.close();
    });

    test('an expiry date can be stored after the migration', () async {
      final db = await buildPreV45Db();
      await MigrationRunner(allMigrations()).run(db, 44, 45);

      const dao = ShoppingListDao();
      final rows = await db.rawQuery(
        "SELECT id FROM shopping_list WHERE barcode = '123'",
      );
      final id = rows.first['id'] as int?;
      await dao.updateExpiryFields(db, id!, expiryDate: '2026-12-31');

      final items = await dao.listAll(db);
      expect(items.single.expiryDate, '2026-12-31');

      await db.close();
    });
  });
}
