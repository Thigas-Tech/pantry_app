import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/services/produce_purchase_tracker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ProducePurchaseTracker', () {
    late DatabaseHelper dbHelper;
    late ProducePurchaseTracker tracker;

    setUp(() async {
      dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
      await dbHelper.database;
      tracker = ProducePurchaseTracker(dbHelper: dbHelper);
    });

    tearDown(() async {
      final db = await dbHelper.database;
      await db.close();
    });

    test('getTopPurchases returns empty when no history', () async {
      final items = await tracker.getTopPurchases(limit: 3);
      expect(items, isEmpty);
    });

    test('records and retrieves purchases by frequency', () async {
      await tracker.recordPurchase('Apple');
      await tracker.recordPurchase('Banana');
      await tracker.recordPurchase('Banana');

      final top = await tracker.getTopPurchases(limit: 3);
      expect(top.first, 'Banana');
      expect(top, contains('Apple'));
      expect(top.length, 2);
    });

    test('undoPurchase decrements count', () async {
      await tracker.recordPurchase('Apple');
      await tracker.recordPurchase('Apple');
      await tracker.undoPurchase('Apple');

      final top = await tracker.getTopPurchases(limit: 8);
      expect(top.length, 1);
      expect(top.first, 'Apple');
    });

    test('undoPurchase keeps count at zero, Apple appears but '
        'Orange disappears after full undo', () async {
      await tracker.recordPurchase('Orange');
      await tracker.recordPurchase('Apple');
      await tracker.undoPurchase('Orange');

      final top = await tracker.getTopPurchases(limit: 8);
      expect(top, contains('Apple'));
      // Orange count is 0, not included
      expect(
        top.any((t) => t.toLowerCase() == 'orange'),
        isFalse,
      );
    });

    test('getTopPurchases does not pad with defaults', () async {
      await tracker.recordPurchase('Apple');

      final top = await tracker.getTopPurchases(limit: 5);
      expect(top.length, 1);
      expect(top.first, 'Apple');
    });

    test('case insensitive recording', () async {
      await tracker.recordPurchase('apple');
      await tracker.recordPurchase('APPLE');
      await tracker.recordPurchase('Apple');

      final top = await tracker.getTopPurchases(limit: 3);
      expect(top.length, 1);
      expect(top.first, 'Apple');
    });

    test('getDefaultList returns common produce', () {
      final items = ProducePurchaseTracker.getDefaultList();
      expect(items, contains('Apple'));
      expect(items, contains('Banana'));
      expect(items.length, greaterThanOrEqualTo(8));
    });
  });
}
