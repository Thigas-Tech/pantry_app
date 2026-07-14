import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/produce_purchase_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('ProducePurchaseTracker', () {
    late MockSharedPreferences prefs;
    late ProducePurchaseTracker tracker;

    setUp(() {
      prefs = MockSharedPreferences();
      tracker = ProducePurchaseTracker(prefs: prefs);
    });

    test('getTopPurchases returns defaults when no history', () async {
      when(() => prefs.getString(any())).thenReturn(null);

      final items = await tracker.getTopPurchases(limit: 3);

      expect(items, isNotEmpty);
      expect(items.length, lessThanOrEqualTo(3));
    });

    test('records and retrieves purchases', () async {
      String? stored;
      when(() => prefs.getString(any())).thenReturn(null);
      when(() => prefs.setString(any(), any())).thenAnswer((inv) async {
        stored = inv.positionalArguments[1] as String;
        return true;
      });

      await tracker.recordPurchase('Apple');
      await tracker.recordPurchase('Banana');
      await tracker.recordPurchase('Banana');

      // After recording, subsequent getTopPurchases should use the stored data
      when(() => prefs.getString(any())).thenReturn(stored);
      final top = await tracker.getTopPurchases(limit: 2);
      expect(top, contains('Banana'));
    });

    test('getDefaultList returns common produce', () {
      final items = ProducePurchaseTracker.getDefaultList();

      expect(items, contains('Apple'));
      expect(items, contains('Banana'));
      expect(items.length, greaterThanOrEqualTo(8));
    });
  });
}
