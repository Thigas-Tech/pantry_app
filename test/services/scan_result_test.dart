import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/scan_result.dart';

void main() {
  group('BarcodeResult', () {
    test('stores barcode string', () {
      const result = BarcodeResult('5901234123457');
      expect(result.barcode, '5901234123457');
    });

    test('equality works by value', () {
      const a = BarcodeResult('123');
      const b = BarcodeResult('123');
      const c = BarcodeResult('456');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('PluResult', () {
    test('stores pluCode and produceName', () {
      const result = PluResult(pluCode: '4011', produceName: 'Banana');
      expect(result.pluCode, '4011');
      expect(result.produceName, 'Banana');
    });

    test('equality works by value', () {
      const a = PluResult(pluCode: '4011', produceName: 'Banana');
      const b = PluResult(pluCode: '4011', produceName: 'Banana');
      const c = PluResult(pluCode: '4032', produceName: 'Apple');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ScanResult', () {
    test('sealed class pattern matching works', () {
      const ScanResult barcode = BarcodeResult('123');
      const ScanResult plu = PluResult(pluCode: '4011', produceName: 'Banana');

      expect(barcode, isA<BarcodeResult>());
      expect(plu, isA<PluResult>());

      switch (barcode) {
        case BarcodeResult(barcode: final b):
          expect(b, '123');
        default:
          fail('Expected BarcodeResult');
      }

      switch (plu) {
        case PluResult(pluCode: final c, produceName: final n):
          expect(c, '4011');
          expect(n, 'Banana');
        default:
          fail('Expected PluResult');
      }
    });
  });
}
