import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pantry_app/services/currency_service.dart';

void main() {
  group('currencySymbolFor', () {
    test(r'returns R$ for BRL', () {
      expect(currencySymbolFor('BRL'), r'R$');
    });

    test(r'returns $ for USD', () {
      expect(currencySymbolFor('USD'), r'$');
    });

    test(r'returns $ for ARS, CLP, COP', () {
      expect(currencySymbolFor('ARS'), r'$');
      expect(currencySymbolFor('CLP'), r'$');
      expect(currencySymbolFor('COP'), r'$');
    });

    test('returns euro sign for EUR', () {
      expect(currencySymbolFor('EUR'), '\u20AC');
    });

    test('returns pound sign for GBP', () {
      expect(currencySymbolFor('GBP'), '\u00A3');
    });

    test('returns yen sign for JPY and CNY', () {
      expect(currencySymbolFor('JPY'), '\u00A5');
      expect(currencySymbolFor('CNY'), '\u00A5');
    });

    test(r'returns CA$ for CAD', () {
      expect(currencySymbolFor('CAD'), r'CA$');
    });

    test(r'returns AU$ for AUD', () {
      expect(currencySymbolFor('AUD'), r'AU$');
    });

    test('returns uppercase code for unknown currencies', () {
      expect(currencySymbolFor('XYZ'), 'XYZ');
      expect(currencySymbolFor('MXN'), 'MXN');
      expect(currencySymbolFor('KRW'), 'KRW');
    });

    test('is case-insensitive', () {
      expect(currencySymbolFor('brl'), r'R$');
      expect(currencySymbolFor('Usd'), r'$');
      expect(currencySymbolFor('jpy'), '\u00A5');
    });
  });

  group('decimalDigitsFor', () {
    test('returns 0 for JPY and KRW', () {
      expect(decimalDigitsFor('JPY'), 0);
      expect(decimalDigitsFor('KRW'), 0);
    });

    test('returns 2 for typical currencies', () {
      expect(decimalDigitsFor('USD'), 2);
      expect(decimalDigitsFor('BRL'), 2);
      expect(decimalDigitsFor('EUR'), 2);
      expect(decimalDigitsFor('GBP'), 2);
    });

    test('is case-insensitive', () {
      expect(decimalDigitsFor('jpy'), 0);
      expect(decimalDigitsFor('usd'), 2);
    });
  });

  group('decimalSeparatorFor', () {
    test('returns comma for BRL, ARS, CLP, COP', () {
      expect(decimalSeparatorFor('BRL'), ',');
      expect(decimalSeparatorFor('ARS'), ',');
      expect(decimalSeparatorFor('CLP'), ',');
      expect(decimalSeparatorFor('COP'), ',');
    });

    test('returns dot for all others', () {
      expect(decimalSeparatorFor('USD'), '.');
      expect(decimalSeparatorFor('EUR'), '.');
    });
  });

  group('NumberFormat.currency with custom symbol', () {
    test(r'BRL formats with R$ symbol and 2 decimals', () {
      final result = NumberFormat.currency(
        name: 'BRL',
        symbol: currencySymbolFor('BRL'),
        decimalDigits: decimalDigitsFor('BRL'),
      ).format(15.9);
      expect(result, contains(r'R$'));
      expect(result, contains('15'));
    });

    test(r'USD formats with $ symbol and 2 decimals', () {
      final result = NumberFormat.currency(
        name: 'USD',
        symbol: currencySymbolFor('USD'),
        decimalDigits: decimalDigitsFor('USD'),
      ).format(15.9);
      expect(result, contains(r'$'));
      expect(result, contains('15'));
    });

    test('JPY formats with yen symbol and 0 decimals', () {
      final result = NumberFormat.currency(
        name: 'JPY',
        symbol: currencySymbolFor('JPY'),
        decimalDigits: decimalDigitsFor('JPY'),
      ).format(500);
      expect(result, contains('\u00A5'));
      expect(result, contains('500'));
      expect(result, isNot(contains('.')));
    });
  });
}
