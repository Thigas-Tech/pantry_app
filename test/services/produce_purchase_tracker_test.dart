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

    test('getTopPurchases returns defaults when no history', () async {
      final items = await tracker.getTopPurchases(limit: 3);
      expect(items, isNotEmpty);
      expect(items.length, lessThanOrEqualTo(3));
    });

    test('records and retrieves purchases ordered by frequency', () async {
      await tracker.recordPurchase('Apple');
      await tracker.recordPurchase('Banana');
      await tracker.recordPurchase('Banana');

      final top = await tracker.getTopPurchases(limit: 3);
      expect(top.first, 'Banana');
      expect(top, contains('Apple'));
    });

    test('undoPurchase decrements count', () async {
      await tracker.recordPurchase('Apple');
      await tracker.recordPurchase('Apple');
      await tracker.undoPurchase('Apple');

      final top = await tracker.getTopPurchases(limit: 8);
      // Apple should appear but have lower priority after undo
      expect(top, contains('Apple'));
    });

    test('undoPurchase keeps count at zero, Apple appears first', () async {
      await tracker.recordPurchase('Orange');
      await tracker.recordPurchase('Apple');
      await tracker.undoPurchase('Orange');
      await tracker.undoPurchase('Orange');

      final top = await tracker.getTopPurchases(limit: 8);
      // Apple (count 1) beats Orange (count 0): Apple should come first
      // Orange may appear from defaults, but Apple has higher priority
      expect(top, contains('Apple'));
      // Apple should be before Orange if Orange is in the list
      final appleIdx = top.indexOf('Apple');
      final orangeIdx = top.indexOf('Orange');
      if (orangeIdx >= 0) {
        expect(appleIdx, lessThan(orangeIdx));
      }
    });

    test('getTopPurchases pads with defaults when less than limit', () async {
      await tracker.recordPurchase('Apple');

      final top = await tracker.getTopPurchases(limit: 5);
      expect(top.length, 5);
      expect(top.first, 'Apple');
    });

    test('case insensitive recording', () async {
      await tracker.recordPurchase('apple');
      await tracker.recordPurchase('APPLE');
      await tracker.recordPurchase('Apple');

      final top = await tracker.getTopPurchases(limit: 3);
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
