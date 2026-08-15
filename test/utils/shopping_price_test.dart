import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/shopping_price.dart';

void main() {
  group('groupShoppingPrices', () {
    test('returns empty totals for empty input', () {
      final total = groupShoppingPrices(const <ShoppingPrice>[]);
      expect(total.byCurrency, isEmpty);
      expect(total.estimatedAmount, 0);
    });

    test('sums entered prices per currency', () {
      const prices = [
        ShoppingPrice(amount: 4.99, currency: 'USD', isEstimate: false),
        ShoppingPrice(amount: 2.50, currency: 'USD', isEstimate: false),
        ShoppingPrice(amount: 10, currency: 'BRL', isEstimate: false),
      ];
      final total = groupShoppingPrices(prices);
      expect(total.byCurrency, {'USD': 7.49, 'BRL': 10.0});
      expect(total.estimatedAmount, 0);
    });

    test('tracks estimated amounts separately', () {
      const prices = [
        ShoppingPrice(amount: 4.99, currency: 'USD', isEstimate: true),
        ShoppingPrice(amount: 1, currency: 'USD', isEstimate: false),
      ];
      final total = groupShoppingPrices(prices);
      expect(total.byCurrency, {'USD': 5.99});
      expect(total.estimatedAmount, 4.99);
    });

    test('mixes currencies with estimates', () {
      const prices = [
        ShoppingPrice(amount: 2, currency: 'USD', isEstimate: true),
        ShoppingPrice(amount: 5, currency: 'BRL', isEstimate: true),
        ShoppingPrice(amount: 3, currency: 'BRL', isEstimate: false),
      ];
      final total = groupShoppingPrices(prices);
      expect(total.byCurrency, {'USD': 2.0, 'BRL': 8.0});
      expect(total.estimatedAmount, 7.0);
    });
  });
}
