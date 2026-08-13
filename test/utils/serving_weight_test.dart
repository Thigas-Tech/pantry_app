import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/serving_weight.dart';

void main() {
  group('ServingWeightResolver.resolve', () {
    test('prefers the inventory row serving weight', () {
      expect(
        ServingWeightResolver.resolve(
          rowServingWeightG: 250,
          produceName: 'Apple',
        ),
        250,
      );
    });

    test('falls back to presets when the row weight is absent', () {
      // Medium apple preset is 182 g.
      expect(
        ServingWeightResolver.resolve(produceName: 'Apple'),
        182,
      );
    });

    test('falls back to presets when the row weight is not positive', () {
      expect(
        ServingWeightResolver.resolve(
          rowServingWeightG: 0,
          produceName: 'Banana',
        ),
        isNot(null),
      );
    });

    test('returns null for unknown produce without a row weight', () {
      expect(
        ServingWeightResolver.resolve(produceName: 'UnknownProduce'),
        isNull,
      );
    });

    test('returns null when no source knows the weight', () {
      expect(
        ServingWeightResolver.resolve(produceName: ''),
        isNull,
      );
    });
  });
}
