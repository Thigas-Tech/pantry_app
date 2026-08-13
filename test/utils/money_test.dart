import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/money.dart';

void main() {
  group('roundToCents', () {
    test('rounds half up at the cent boundary', () {
      expect(Money.roundToCents(1.665), 1.67);
      expect(Money.roundToCents(9.99 * 2 / 12), 1.67);
    });

    test('rounds down below the cent boundary', () {
      expect(Money.roundToCents(1.664), 1.66);
    });

    test('rounds the hundredths digit', () {
      expect(Money.roundToCents(123.456), 123.46);
      expect(Money.roundToCents(0.999), 1.0);
    });

    test('keeps exact cent values unchanged', () {
      expect(Money.roundToCents(2.5), 2.5);
      expect(Money.roundToCents(0), 0);
      expect(Money.roundToCents(10), 10);
    });

    test('handles fractional cents near zero', () {
      expect(Money.roundToCents(0.004), 0.0);
      expect(Money.roundToCents(0.005), 0.01);
    });
  });
}
