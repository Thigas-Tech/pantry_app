import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product_nutrient.dart';

/// Tests for the [ProductNutrient] model.
void main() {
  group('ProductNutrient', () {
    test('stores offTag, value, and unit', () {
      const nutrient = ProductNutrient(
        offTag: 'vitamin-c',
        value: 20,
        unit: 'mg',
      );
      expect(nutrient.offTag, 'vitamin-c');
      expect(nutrient.value, 20.0);
      expect(nutrient.unit, 'mg');
    });

    test('value is stored as a double', () {
      const nutrient = ProductNutrient(offTag: 'sodium', value: 0.5, unit: 'g');
      expect(nutrient.value, isA<double>());
    });

    test('supports copyWith', () {
      const nutrient = ProductNutrient(
        offTag: 'vitamin-c',
        value: 20,
        unit: 'mg',
      );
      final updated = nutrient.copyWith(value: 30);
      expect(updated.value, 30.0);
      expect(updated.offTag, 'vitamin-c');
      expect(updated.unit, 'mg');
    });

    test('value equality compares all fields', () {
      const a = ProductNutrient(offTag: 'sodium', value: 0.5, unit: 'g');
      const b = ProductNutrient(offTag: 'sodium', value: 0.5, unit: 'g');
      const c = ProductNutrient(offTag: 'sodium', value: 0.6, unit: 'g');
      expect(a, b);
      expect(a == c, isFalse);
    });

    test('toJson produces the expected map', () {
      const nutrient = ProductNutrient(
        offTag: 'vitamin-c',
        value: 20,
        unit: 'mg',
      );
      expect(nutrient.toJson(), {
        'offTag': 'vitamin-c',
        'value': 20.0,
        'unit': 'mg',
      });
    });

    test('fromJson restores a nutrient from a map', () {
      final nutrient = ProductNutrient.fromJson({
        'offTag': 'vitamin-c',
        'value': 20.0,
        'unit': 'mg',
      });
      expect(
        nutrient,
        const ProductNutrient(offTag: 'vitamin-c', value: 20, unit: 'mg'),
      );
    });

    test('fromJson/toJson round-trip', () {
      const original = ProductNutrient(
        offTag: 'selenium',
        value: 20,
        unit: 'mcg',
      );
      final restored = ProductNutrient.fromJson(original.toJson());
      expect(restored, original);
    });

    test('toJson round-trips through an integer-valued double', () {
      const nutrient = ProductNutrient(offTag: 'alcohol', value: 5, unit: '%');
      final restored = ProductNutrient.fromJson(nutrient.toJson());
      expect(restored.value, 5.0);
    });
  });
}
