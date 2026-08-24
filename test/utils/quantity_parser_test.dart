/// Tests for the quantity parser utilities.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/quantity_parser.dart';

void main() {
  group('parseQuantity', () {
    test('uses productQuantity and productQuantityUnit when both present', () {
      final result = parseQuantity(
        productQuantity: 500,
        productQuantityUnit: 'ml',
        quantity: '500 ml',
      );
      expect(result, isNotNull);
      expect(result!.amount, 500);
      expect(result.unit, 'ml');
    });

    test('parses multi-pack per-unit value from quantity string', () {
      final result = parseQuantity(
        productQuantity: 450,
        productQuantityUnit: 'g',
        quantity: '3 x 150 g',
      );
      expect(result, isNotNull);
      expect(result!.amount, 150);
      expect(result.unit, 'g');
    });

    test('multi-pack with "x" works without spaces', () {
      final result = parseQuantity(
        productQuantity: 400,
        productQuantityUnit: 'ml',
        quantity: '2x200 ml',
      );
      expect(result, isNotNull);
      expect(result!.amount, 200);
      expect(result.unit, 'ml');
    });

    test('parses quantity string when productQuantity is null', () {
      final result = parseQuantity(quantity: '500 ml');
      expect(result, isNotNull);
      expect(result!.amount, 500);
      expect(result.unit, 'ml');
    });

    test('parses quantity string without space', () {
      final result = parseQuantity(quantity: '750ml');
      expect(result, isNotNull);
      expect(result!.amount, 750);
      expect(result.unit, 'ml');
    });

    test('returns null for unparseable quantity with unrecognised unit', () {
      expect(parseQuantity(quantity: '6 eggs'), isNull);
    });

    test('parses decimal quantity', () {
      final result = parseQuantity(quantity: '0.75 L');
      expect(result, isNotNull);
      expect(result!.amount, closeTo(0.75, 0.001));
      expect(result.unit, 'L');
    });

    test('parses fl oz unit as volume, not weight oz', () {
      final result = parseQuantity(quantity: '33.8 fl oz');
      expect(result, isNotNull);
      expect(result!.amount, closeTo(33.8, 0.001));
      expect(result.unit, 'fl oz');
    });

    test('parses "floz" and "fluid ounce" as fl oz', () {
      expect(normalizeUnit('floz'), 'fl oz');
      expect(normalizeUnit('fluid ounce'), 'fl oz');
      expect(normalizeUnit('fluid ounces'), 'fl oz');
    });

    test('returns null for a serving-based quantity string', () {
      expect(parseQuantity(quantity: '12 serving'), isNull);
      expect(parseQuantity(quantity: '1 serving'), isNull);
    });

    test('parses mg quantity', () {
      final result = parseQuantity(quantity: '500 mg');
      expect(result, isNotNull);
      expect(result!.amount, 500);
      expect(result.unit, 'mg');
    });

    test('parses mcg quantity', () {
      final result = parseQuantity(quantity: '200 mcg');
      expect(result, isNotNull);
      expect(result!.amount, 200);
      expect(result.unit, 'mcg');
    });

    test('returns null for empty string', () {
      expect(parseQuantity(quantity: ''), isNull);
    });

    test('returns null for null quantity', () {
      expect(parseQuantity(), isNull);
    });

    test('returns null when quantity string has no number', () {
      expect(parseQuantity(quantity: 'some text'), isNull);
    });

    test('parses multi-pack with decimal', () {
      final result = parseQuantity(quantity: '2 x 0.5 kg');
      expect(result, isNotNull);
      expect(result!.amount, closeTo(0.5, 0.001));
      expect(result.unit, 'kg');
    });

    test('uses productQuantityUnit when quantity has no unit', () {
      final result = parseQuantity(
        productQuantity: 6,
        productQuantityUnit: 'pieces',
        quantity: '6',
      );
      expect(result, isNotNull);
      expect(result!.amount, 6);
      expect(result.unit, 'pieces');
    });
  });

  group('parseUsdaQuantity', () {
    test('returns gramWeight and g when gramWeight is present', () {
      final result = parseUsdaQuantity(
        usdaGramWeight: 182,
        usdaServingAmount: 1,
      );
      expect(result, isNotNull);
      expect(result!.amount, 182);
      expect(result.unit, 'g');
    });

    test('ignores usdaServingAmount when gramWeight is present', () {
      final result = parseUsdaQuantity(
        usdaGramWeight: 150,
        usdaServingAmount: 99,
      );
      expect(result, isNotNull);
      expect(result!.amount, 150);
      expect(result.unit, 'g');
    });

    test('returns null when gramWeight is null', () {
      final result = parseUsdaQuantity(
        usdaServingAmount: 1,
        usdaServingUnit: 'fruit',
      );
      expect(result, isNull);
    });

    test('returns null when gramWeight is zero', () {
      final result = parseUsdaQuantity(usdaGramWeight: 0);
      expect(result, isNull);
    });

    test('returns null when gramWeight is negative', () {
      final result = parseUsdaQuantity(usdaGramWeight: -5);
      expect(result, isNull);
    });

    test('returns null when all fields are null', () {
      expect(parseUsdaQuantity(), isNull);
    });

    test('handles fractional gram weights', () {
      final result = parseUsdaQuantity(usdaGramWeight: 0.5);
      expect(result, isNotNull);
      expect(result!.amount, closeTo(0.5, 0.001));
      expect(result.unit, 'g');
    });

    test('handles large gram weights', () {
      final result = parseUsdaQuantity(usdaGramWeight: 3000);
      expect(result, isNotNull);
      expect(result!.amount, 3000);
      expect(result.unit, 'g');
    });
  });

  group('parseServingQuantity', () {
    test(
      'uses servingQuantity as amount with unit from servingSize',
      () {
        final result = parseServingQuantity(
          servingQuantity: 30,
          servingSize: '30g',
        );
        expect(result, isNotNull);
        expect(result!.amount, 30);
        expect(result.unit, 'g');
      },
    );

    test(
      'servingQuantity with spaced servingSize extracts unit',
      () {
        final result = parseServingQuantity(
          servingQuantity: 100,
          servingSize: '100 g',
        );
        expect(result, isNotNull);
        expect(result!.amount, 100);
        expect(result.unit, 'g');
      },
    );

    test(
      'servingQuantity with complex servingSize that has'
      ' unrecognisable first-word unit returns null',
      () {
        expect(
          parseServingQuantity(
            servingQuantity: 240,
            servingSize: '1 cup (240ml)',
          ),
          isNull,
        );
      },
    );

    test(
      'servingQuantity with unrecognised servingSize unit returns null',
      () {
        final result = parseServingQuantity(
          servingQuantity: 28,
          servingSize: '1 cookie (28g)',
        );
        expect(result, isNull);
      },
    );

    test(
      'fallback parses servingSize string when servingQuantity is null',
      () {
        final result = parseServingQuantity(servingSize: '100g');
        expect(result, isNotNull);
        expect(result!.amount, 100);
        expect(result.unit, 'g');
      },
    );

    test(
      'fallback parses servingSize with ml when servingQuantity is null',
      () {
        final result = parseServingQuantity(servingSize: '500ml');
        expect(result, isNotNull);
        expect(result!.amount, 500);
        expect(result.unit, 'ml');
      },
    );

    test(
      'returns null when both servingQuantity and servingSize are null',
      () => expect(parseServingQuantity(), isNull),
    );

    test(
      'returns null when servingQuantity is null and servingSize is empty',
      () => expect(parseServingQuantity(servingSize: ''), isNull),
    );

    test(
      'falls back to parsing servingSize when servingQuantity is zero',
      () {
        final result = parseServingQuantity(
          servingQuantity: 0,
          servingSize: '30g',
        );
        expect(result, isNotNull);
        expect(result!.amount, 30);
        expect(result.unit, 'g');
      },
    );

    test(
      'returns null when servingQuantity is present but servingSize'
      ' has no recognisable unit',
      () {
        expect(
          parseServingQuantity(
            servingQuantity: 1,
            servingSize: '1 plate',
          ),
          isNull,
        );
      },
    );

    test(
      'returns null for complex servingSize with unrecognised unit'
      ' when servingQuantity is null',
      () {
        expect(
          parseServingQuantity(servingSize: '1 cookie (28g)'),
          isNull,
        );
      },
    );
  });

  group('normalizeUnit', () {
    test('normalizes g -> g', () {
      expect(normalizeUnit('g'), 'g');
    });

    test('normalizes gram -> g', () {
      expect(normalizeUnit('gram'), 'g');
    });

    test('normalizes grams -> g', () {
      expect(normalizeUnit('grams'), 'g');
    });

    test('normalizes mg -> mg', () {
      expect(normalizeUnit('mg'), 'mg');
    });

    test('normalizes milligram -> mg', () {
      expect(normalizeUnit('milligram'), 'mg');
    });

    test('normalizes milligrams -> mg', () {
      expect(normalizeUnit('milligrams'), 'mg');
    });

    test('normalizes mcg -> mcg', () {
      expect(normalizeUnit('mcg'), 'mcg');
    });

    test('normalizes microgram -> mcg', () {
      expect(normalizeUnit('microgram'), 'mcg');
    });

    test('normalizes micrograms -> mcg', () {
      expect(normalizeUnit('micrograms'), 'mcg');
    });

    test('normalizes µg -> mcg', () {
      expect(normalizeUnit('µg'), 'mcg');
    });

    test('normalizes kilogram -> kg', () {
      expect(normalizeUnit('kilogram'), 'kg');
    });

    test(
      'normalizes kilograms -> kg',
      () => expect(normalizeUnit('kilograms'), 'kg'),
    );

    test('normalizes ml -> ml', () {
      expect(normalizeUnit('ml'), 'ml');
    });

    test('normalizes milliliter -> ml', () {
      expect(normalizeUnit('milliliter'), 'ml');
    });

    test('normalizes millilitre -> ml', () {
      expect(normalizeUnit('millilitre'), 'ml');
    });

    test(
      'normalizes L -> L',
      () => expect(normalizeUnit('L'), 'L'),
    );

    test(
      'normalizes l -> L',
      () => expect(normalizeUnit('l'), 'L'),
    );

    test(
      'normalizes liter -> L',
      () => expect(normalizeUnit('liter'), 'L'),
    );

    test(
      'normalizes litre -> L',
      () => expect(normalizeUnit('litre'), 'L'),
    );

    test(
      'normalizes cl -> ml',
      () => expect(normalizeUnit('cl'), 'ml'),
    );

    test('normalizes centiliter -> ml', () {
      expect(normalizeUnit('centiliter'), 'ml');
    });

    test(
      'normalizes oz -> oz',
      () => expect(normalizeUnit('oz'), 'oz'),
    );

    test(
      'normalizes ounce -> oz',
      () => expect(normalizeUnit('ounce'), 'oz'),
    );

    test(
      'normalizes pounds -> lb',
      () => expect(normalizeUnit('pounds'), 'lb'),
    );

    test(
      'normalizes lbs -> lb',
      () => expect(normalizeUnit('lbs'), 'lb'),
    );

    test(
      'returns null for null',
      () => expect(normalizeUnit(null), isNull),
    );

    test(
      'normalizes fl oz -> fl oz',
      () => expect(normalizeUnit('fl oz'), 'fl oz'),
    );

    test(
      'returns null for serving (no valid unit)',
      () => expect(normalizeUnit('serving'), isNull),
    );

    test('returns null for unrecognised unit', () {
      expect(normalizeUnit('unknown'), isNull);
    });

    test('returns null for empty string', () {
      expect(normalizeUnit(''), isNull);
    });
  });

  group('parsePackageQuantity', () {
    test('parses a plain quantity string', () {
      final result = parsePackageQuantity(quantity: '500 ml');
      expect(result, isNotNull);
      expect(result!.amount, 500);
      expect(result.unit, 'ml');
    });

    test('resolves a multi-pack string to the total package size', () {
      final result = parsePackageQuantity(quantity: '3 x 150 g');
      expect(result, isNotNull);
      expect(result!.amount, 450);
      expect(result.unit, 'g');
    });

    test('resolves a multi-pack string with "x" without spaces', () {
      final result = parsePackageQuantity(quantity: '6x1.5 L');
      expect(result, isNotNull);
      expect(result!.amount, 9);
      expect(result.unit, 'L');
    });

    test('resolves a decimal multi-pack string', () {
      final result = parsePackageQuantity(quantity: '2 x 37.5 g');
      expect(result, isNotNull);
      expect(result!.amount, 75);
      expect(result.unit, 'g');
    });

    test('sums a bonus-pack string with matching units', () {
      final result = parsePackageQuantity(quantity: '2 x 300 g + 1 x 50 g');
      expect(result, isNotNull);
      expect(result!.amount, 650);
      expect(result.unit, 'g');
    });

    test('returns null for a bonus pack with mixed units', () {
      expect(
        parsePackageQuantity(quantity: '2 x 300 g + 1 x 100 ml'),
        isNull,
      );
    });

    test('falls back to productQuantity when the string is unparseable', () {
      final result = parsePackageQuantity(
        quantity: 'not a quantity',
        productQuantity: 450,
        productQuantityUnit: 'g',
      );
      expect(result, isNotNull);
      expect(result!.amount, 450);
      expect(result.unit, 'g');
    });

    test('returns null when the string is unparseable and no unit exists', () {
      expect(
        parsePackageQuantity(quantity: 'not a quantity', productQuantity: 450),
        isNull,
      );
    });

    test('returns null when nothing is parseable', () {
      expect(parsePackageQuantity(quantity: 'no numbers here'), isNull);
    });

    test('returns null for a null quantity with no productQuantity', () {
      expect(parsePackageQuantity(), isNull);
    });

    test('returns null for a zero productQuantity fallback', () {
      expect(
        parsePackageQuantity(quantity: 'nope', productQuantity: 0),
        isNull,
      );
    });

    test('parses a multi-pack with a weight unit and decimal multiplier'
        ' separately from the per-unit value', () {
      // Multiplier "6" x per-unit "1.5 L": the total is 9 L, not 1.5 L.
      final result = parsePackageQuantity(quantity: '6 x 1.5 L');
      expect(result!.amount, 9);
      expect(result.unit, 'L');
    });
  });
}
