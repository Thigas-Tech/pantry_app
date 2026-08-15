import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/cache_config.dart';

void main() {
  group('cache_config', () {
    test('product cache max age is two months', () {
      expect(productCacheMaxAge, const Duration(days: 60));
    });

    test('inventory refresh overdue period is five days', () {
      expect(inventoryRefreshOverdueDays, 5);
    });
  });
}
