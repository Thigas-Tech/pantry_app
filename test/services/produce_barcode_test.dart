import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/produce_barcode.dart';

void main() {
  group('produceBarcode', () {
    test('returns canonical barcode for simple name', () {
      expect(produceBarcode('Apple'), 'produce-apple');
    });

    test('lowercases mixed-case name', () {
      expect(produceBarcode('Organic Banana'), 'produce-organic_banana');
    });

    test('trims leading and trailing whitespace', () {
      expect(produceBarcode('  Apple  '), 'produce-apple');
    });

    test('collapses internal whitespace to underscore', () {
      expect(produceBarcode('Bell Pepper'), 'produce-bell_pepper');
    });

    test('handles already-lowercase name', () {
      expect(produceBarcode('apple'), 'produce-apple');
    });

    test('handles empty string', () {
      expect(produceBarcode(''), 'produce-');
    });

    test('handles name with only whitespace', () {
      expect(produceBarcode('   '), 'produce-');
    });

    test('collapses multiple consecutive spaces to single underscore', () {
      expect(
        produceBarcode('Sweet   Potato'),
        'produce-sweet_potato',
      );
    });
  });

  group('normalizeProduceName', () {
    test('lowercases and trims', () {
      expect(normalizeProduceName('  Apple  '), 'apple');
    });

    test('replaces spaces with underscore', () {
      expect(normalizeProduceName('Organic Banana'), 'organic_banana');
    });

    test('handles empty string', () {
      expect(normalizeProduceName(''), '');
    });
  });

  group('normalizeProduceBarcode', () {
    test('normalizes produce- barcode', () {
      expect(
        normalizeProduceBarcode('produce-Organic Banana'),
        'produce-organic_banana',
      );
    });

    test('returns non-produce barcode unchanged', () {
      expect(normalizeProduceBarcode('0123456789012'), '0123456789012');
    });

    test('normalizes mixed-case produce- barcode', () {
      expect(
        normalizeProduceBarcode('produce-Apple'),
        'produce-apple',
      );
    });

    test('handles plu- prefix unchanged', () {
      expect(normalizeProduceBarcode('plu-12345'), 'plu-12345');
    });

    test('normalizes produce- with whitespace around name', () {
      expect(
        normalizeProduceBarcode('produce-  Apple  '),
        'produce-apple',
      );
    });

    test('handles produce- alone', () {
      expect(normalizeProduceBarcode('produce-'), 'produce-');
    });
  });
}
