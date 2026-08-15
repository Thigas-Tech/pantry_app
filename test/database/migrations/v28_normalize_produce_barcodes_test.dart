import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Regression test for the v28 produce-barcode migration running under
/// foreign-key enforcement.
///
/// sqflite runs onUpgrade inside a transaction with PRAGMA foreign_keys
/// already enabled (set in onConfigure before the upgrade). v28 normalizes
/// the parent products.barcode first; without deferring the FK checks this
/// violates the child FKs the moment the parent key changes. The test builds
/// a real v27 file database with produce rows across parent and child
/// tables, then opens it at the current version through the real open path
/// so the migration runs exactly as it does in production.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'normalizes produce barcodes in all tables with FK enabled',
    () async {
      final tempDir = Directory.systemTemp.createTempSync('pantry_v28_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final dbPath = '${tempDir.path}/pantry.db';

      // Build a v27 database with unnormalized produce barcodes.
      final v27 = await databaseFactory.openDatabase(dbPath);
      final runner = MigrationRunner(allMigrations());
      await runner.run(v27, 0, 27);

      await v27.insert('products', {
        'barcode': 'produce-Apple',
        'name': 'Apple',
        'source': 'manual',
        'product_type': 'produce',
        'language_code': 'en',
        'submission_status': 'not_submitted',
      });
      await v27.insert('inventory', {
        'barcode': 'produce-Apple',
        'quantity': 2.0,
        'unit': 'pieces',
        'inventory_id': 1,
        'date_added': 100,
      });
      await v27.insert('prices', {
        'barcode': 'produce-Apple',
        'price': 1.99,
        'currency': 'USD',
        'date_added': 100,
        'date_purchased': 100,
        'sync_status': 'local_only',
      });
      await v27.insert('shopping_list', {
        'barcode': 'produce-Apple',
        'name': 'Apple',
        'date_added': 100,
      });
      await v27.setVersion(27);
      await v27.close();

      // Reopen through the real upgrade path (onConfigure sets FK ON, then
      // onUpgrade runs all pending migrations inside a transaction).
      final upgraded = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 43,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            await MigrationRunner(
              allMigrations(),
            ).run(db, oldVersion, newVersion);
          },
        ),
      );
      addTearDown(upgraded.close);

      for (final table in [
        'products',
        'inventory',
        'prices',
        'shopping_list',
      ]) {
        final rows = await upgraded.rawQuery(
          "SELECT barcode FROM $table WHERE barcode LIKE 'produce-%'",
        );
        expect(
          rows.every((r) => r['barcode'] == 'produce-apple'),
          isTrue,
          reason: 'unnormalized barcode left in $table',
        );
      }
    },
  );
}
