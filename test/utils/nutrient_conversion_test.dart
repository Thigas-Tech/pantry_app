import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/nutrient_conversion.dart';

/// Tests for the [NutrientConverter] unit conversion helper.
void main() {
  group('NutrientConverter.convert weight units', () {
    test('g to mg', () {
      expect(NutrientConverter.convert(0.5, 'g', 'mg'), 500.0);
    });

    test('mg to g', () {
      expect(NutrientConverter.convert(500, 'mg', 'g'), 0.5);
    });

    test('g to mcg', () {
      expect(NutrientConverter.convert(0.00002, 'g', 'mcg'), 20.0);
    });

    test('mcg to g', () {
      expect(
        NutrientConverter.convert(20, 'mcg', 'g'),
        closeTo(0.00002, 1e-12),
      );
    });

    test('g/mg/mcg round-trips are exact inverses', () {
      expect(NutrientConverter.convert(0.5, 'g', 'mg'), 500.0);
      expect(NutrientConverter.convert(500, 'mg', 'g'), 0.5);
      expect(NutrientConverter.convert(0.5, 'g', 'mcg'), 500000.0);
      expect(NutrientConverter.convert(500000, 'mcg', 'g'), 0.5);
      expect(NutrientConverter.convert(500, 'mg', 'mcg'), 500000.0);
      expect(NutrientConverter.convert(500000, 'mcg', 'mg'), 500.0);
    });

    test('same unit returns the value unchanged', () {
      expect(NutrientConverter.convert(3, 'g', 'g'), 3.0);
      expect(NutrientConverter.convert(3, 'mg', 'mg'), 3.0);
    });
  });

  group('NutrientConverter.convert energy units', () {
    test('kj to kcal uses the OFF factor', () {
      expect(
        NutrientConverter.convert(100, 'kj', 'kcal'),
        closeTo(23.8845, 0.001),
      );
    });

    test('kcal to kj uses the OFF factor', () {
      expect(
        NutrientConverter.convert(23.8845, 'kcal', 'kj'),
        closeTo(100.0, 0.001),
      );
    });
  });

  group('NutrientConverter.convert percent and unknown units', () {
    test('percent passes through untouched', () {
      expect(NutrientConverter.convert(5, '%', 'g'), 5.0);
      expect(NutrientConverter.convert(5, 'g', '%'), 5.0);
      expect(NutrientConverter.convert(5, '%', '%'), 5.0);
    });

    test('unknown unit passes through untouched', () {
      expect(NutrientConverter.convert(5, 'IU', 'mg'), 5.0);
    });
  });
}
