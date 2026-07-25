import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/unit_conversion.dart';

void main() {
  group('normalizeToGrams', () {
    test('passes grams through', () {
      expect(UnitConverter.normalizeToGrams(100, 'g'), 100.0);
    });

    test('converts kg to g', () {
      expect(UnitConverter.normalizeToGrams(1, 'kg'), 1000.0);
    });

    test('handles zero', () {
      expect(UnitConverter.normalizeToGrams(0, 'g'), 0.0);
    });
  });

  group('normalizeToMilliliters', () {
    test('passes ml through', () {
      expect(UnitConverter.normalizeToMilliliters(500, 'ml'), 500.0);
    });

    test('converts L to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'L'), 1000.0);
    });

    test('converts tbsp to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'tbsp'), 15.0);
    });

    test('converts tsp to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'tsp'), 5.0);
    });

    test('converts cup to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'cup'), 240.0);
    });
  });

  group('areUnitsCompatible', () {
    test('g and kg are compatible', () {
      expect(UnitConverter.areUnitsCompatible('g', 'kg'), isTrue);
    });

    test('ml and L are compatible', () {
      expect(UnitConverter.areUnitsCompatible('ml', 'L'), isTrue);
    });

    test('pieces and pieces are compatible', () {
      expect(UnitConverter.areUnitsCompatible('pieces', 'pieces'), isTrue);
    });

    test('g and ml are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('g', 'ml'), isFalse);
    });

    test('kg and tsp are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('kg', 'tsp'), isFalse);
    });

    test('pieces and g are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('pieces', 'g'), isFalse);
    });
  });

  group('convertBack', () {
    test('converts g back to kg', () {
      expect(UnitConverter.convertBack(1000, 'kg'), 1.0);
    });

    test('converts ml back to L', () {
      expect(UnitConverter.convertBack(2000, 'L'), 2.0);
    });

    test('passes g through unchanged', () {
      expect(UnitConverter.convertBack(500, 'g'), 500.0);
    });

    test('passes ml through unchanged', () {
      expect(UnitConverter.convertBack(300, 'ml'), 300.0);
    });
  });

  group('convert', () {
    test('converts 2 kg to 2000 g', () {
      expect(UnitConverter.convert(2, 'kg', 'g'), 2000.0);
    });

    test('converts 500 ml to 0.5 L', () {
      expect(UnitConverter.convert(500, 'ml', 'L'), 0.5);
    });

    test('leaves pieces unchanged', () {
      expect(UnitConverter.convert(3, 'pieces', 'pieces'), 3.0);
    });
  });
}
