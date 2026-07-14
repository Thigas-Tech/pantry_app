import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/formatters/price_calculator_formatter.dart';

void main() {
  group('PriceCalculatorFormatter with dot separator', () {
    final formatter = PriceCalculatorFormatter('.');

    TextEditingValue update(String old, String newText) {
      return formatter.formatEditUpdate(
        TextEditingValue(text: old),
        TextEditingValue(text: newText),
      );
    }

    test('empty input returns 0.00', () {
      final result = update('0.00', '');
      expect(result.text, '0.00');
      expect(result.selection.baseOffset, 4);
    });

    test('single digit 5 returns 0.05', () {
      final result = update('0.00', '5');
      expect(result.text, '0.05');
      expect(result.selection.baseOffset, 4);
    });

    test('two digits 50 returns 0.50', () {
      final result = update('0.00', '50');
      expect(result.text, '0.50');
      expect(result.selection.baseOffset, 4);
    });

    test('three digits 500 returns 5.00', () {
      final result = update('0.00', '500');
      expect(result.text, '5.00');
      expect(result.selection.baseOffset, 4);
    });

    test('four digits 5000 returns 50.00', () {
      final result = update('0.00', '5000');
      expect(result.text, '50.00');
      expect(result.selection.baseOffset, 5);
    });

    test('five digits 50000 returns 500.00', () {
      final result = update('0.00', '50000');
      expect(result.text, '500.00');
      expect(result.selection.baseOffset, 6);
    });

    test('leader zeros from accumulated edits 0005 returns 0.05', () {
      final result = update('0.00', '0.005');
      expect(result.text, '0.05');
      expect(result.selection.baseOffset, 4);
    });

    test('leader zeros 0500 returns 5.00', () {
      final result = update('0.00', '0.0500');
      expect(result.text, '5.00');
      expect(result.selection.baseOffset, 4);
    });

    test('single zero returns 0.00', () {
      final result = update('0.00', '0');
      expect(result.text, '0.00');
      expect(result.selection.baseOffset, 4);
    });

    test('large number 9999999 returns 99999.99', () {
      final result = update('0.00', '9999999');
      expect(result.text, '99999.99');
      expect(result.selection.baseOffset, 8);
    });

    test('backspace from 500 to 50 returns 0.50', () {
      final result = update('5.00', '5.0');
      expect(result.text, '0.50');
      expect(result.selection.baseOffset, 4);
    });

    test('backspace to empty returns 0.00', () {
      final result = update('0.05', '');
      expect(result.text, '0.00');
      expect(result.selection.baseOffset, 4);
    });

    test('all zeros 000 returns 0.00', () {
      final result = update('0.00', '000');
      expect(result.text, '0.00');
      expect(result.selection.baseOffset, 4);
    });
  });

  group('PriceCalculatorFormatter with comma separator', () {
    final formatter = PriceCalculatorFormatter(',');

    test('empty input returns 0,00', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '0,00'),
        TextEditingValue.empty,
      );
      expect(result.text, '0,00');
      expect(result.selection.baseOffset, 4);
    });

    test('single digit 5 returns 0,05', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '0,00'),
        const TextEditingValue(text: '5'),
      );
      expect(result.text, '0,05');
    });

    test('three digits 500 returns 5,00', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '0,00'),
        const TextEditingValue(text: '500'),
      );
      expect(result.text, '5,00');
    });

    test('leader zeros 0005 returns 0,05', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '0,00'),
        const TextEditingValue(text: '0,005'),
      );
      expect(result.text, '0,05');
    });
  });
}
