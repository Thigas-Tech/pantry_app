/// Tests for [QuantityParser].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/quantity_parser.dart';

void main() {
  group('QuantityParser.parse', () {
    test('uses productQuantity and productQuantityUnit when both present', () {
      final result = QuantityParser.parse(
        productQuantity: 500,
        productQuantityUnit: 'ml',
        quantity: '500 ml',
      );
      expect(result, isNotNull);
      expect(result!.amount, 500);
      expect(result.unit, 'ml');
    });

    test('parses multi-pack per-unit value from quantity string', () {
      final result = QuantityParser.parse(
        productQuantity: 450,
        productQuantityUnit: 'g',
        quantity: '3 x 150 g',
      );
      expect(result, isNotNull);
      expect(result!.amount, 150);
      expect(result.unit, 'g');
    });

    test('multi-pack with "x" works without spaces', () {
      final result = QuantityParser.parse(
        productQuantity: 400,
        productQuantityUnit: 'ml',
        quantity: '2x200 ml',
      );
      expect(result, isNotNull);
      expect(result!.amount, 200);
      expect(result.unit, 'ml');
    });

    test('parses quantity string when productQuantity is null', () {
      final result = QuantityParser.parse(quantity: '500 ml');
      expect(result, isNotNull);
      expect(result!.amount, 500);
      expect(result.unit, 'ml');
    });

    test('parses quantity string without space', () {
      final result = QuantityParser.parse(quantity: '750ml');
      expect(result, isNotNull);
      expect(result!.amount, 750);
      expect(result.unit, 'ml');
    });

    test('returns null for unparseable quantity with unrecognised unit', () {
      expect(QuantityParser.parse(quantity: '6 eggs'), isNull);
    });

    test('parses decimal quantity', () {
      final result = QuantityParser.parse(quantity: '0.75 L');
      expect(result, isNotNull);
      expect(result!.amount, closeTo(0.75, 0.001));
      expect(result.unit, 'L');
    });

    test('parses fl oz unit', () {
      final result = QuantityParser.parse(quantity: '33.8 fl oz');
      expect(result, isNotNull);
      expect(result!.amount, closeTo(33.8, 0.001));
      expect(result.unit, 'oz');
    });

    test('returns null for empty string', () {
      expect(QuantityParser.parse(quantity: ''), isNull);
    });

    test('returns null for null quantity', () {
      expect(QuantityParser.parse(), isNull);
    });

    test('returns null when quantity string has no number', () {
      expect(QuantityParser.parse(quantity: 'some text'), isNull);
    });

    test('parses multi-pack with decimal', () {
      final result = QuantityParser.parse(quantity: '2 x 0.5 kg');
      expect(result, isNotNull);
      expect(result!.amount, closeTo(0.5, 0.001));
      expect(result.unit, 'kg');
    });

    test('uses productQuantityUnit when quantity has no unit', () {
      final result = QuantityParser.parse(
        productQuantity: 6,
        productQuantityUnit: 'pieces',
        quantity: '6',
      );
      expect(result, isNotNull);
      expect(result!.amount, 6);
      expect(result.unit, 'pieces');
    });
  });

  group('QuantityParser.parseUsda', () {
    test('returns gramWeight and g when gramWeight is present', () {
      final result = QuantityParser.parseUsda(
        usdaGramWeight: 182,
        usdaServingAmount: 1,
      );
      expect(result, isNotNull);
      expect(result!.amount, 182);
      expect(result.unit, 'g');
    });

    test('ignores usdaServingAmount when gramWeight is present', () {
      final result = QuantityParser.parseUsda(
        usdaGramWeight: 150,
        usdaServingAmount: 99,
      );
      expect(result, isNotNull);
      expect(result!.amount, 150);
      expect(result.unit, 'g');
    });

    test('returns null when gramWeight is null', () {
      final result = QuantityParser.parseUsda(
        usdaServingAmount: 1,
        usdaServingUnit: 'fruit',
      );
      expect(result, isNull);
    });

    test('returns null when gramWeight is zero', () {
      final result = QuantityParser.parseUsda(usdaGramWeight: 0);
      expect(result, isNull);
    });

    test('returns null when gramWeight is negative', () {
      final result = QuantityParser.parseUsda(usdaGramWeight: -5);
      expect(result, isNull);
    });

    test('returns null when all fields are null', () {
      expect(QuantityParser.parseUsda(), isNull);
    });

    test('handles fractional gram weights', () {
      final result = QuantityParser.parseUsda(usdaGramWeight: 0.5);
      expect(result, isNotNull);
      expect(result!.amount, closeTo(0.5, 0.001));
      expect(result.unit, 'g');
    });

    test('handles large gram weights', () {
      final result = QuantityParser.parseUsda(usdaGramWeight: 3000);
      expect(result, isNotNull);
      expect(result!.amount, 3000);
      expect(result.unit, 'g');
    });
  });

  group('QuantityParser.parseServing', () {
    test(
      'uses servingQuantity as amount with unit from servingSize',
      () {
        final result = QuantityParser.parseServing(
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
        final result = QuantityParser.parseServing(
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
          QuantityParser.parseServing(
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
        final result = QuantityParser.parseServing(
          servingQuantity: 28,
          servingSize: '1 cookie (28g)',
        );
        expect(result, isNull);
      },
    );

    test(
      'fallback parses servingSize string when servingQuantity is null',
      () {
        final result = QuantityParser.parseServing(servingSize: '100g');
        expect(result, isNotNull);
        expect(result!.amount, 100);
        expect(result.unit, 'g');
      },
    );

    test(
      'fallback parses servingSize with ml when servingQuantity is null',
      () {
        final result = QuantityParser.parseServing(servingSize: '500ml');
        expect(result, isNotNull);
        expect(result!.amount, 500);
        expect(result.unit, 'ml');
      },
    );

    test(
      'returns null when both servingQuantity and servingSize are null',
      () => expect(QuantityParser.parseServing(), isNull),
    );

    test(
      'returns null when servingQuantity is null and servingSize is empty',
      () => expect(QuantityParser.parseServing(servingSize: ''), isNull),
    );

    test(
      'falls back to parsing servingSize when servingQuantity is zero',
      () {
        final result = QuantityParser.parseServing(
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
          QuantityParser.parseServing(
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
          QuantityParser.parseServing(servingSize: '1 cookie (28g)'),
          isNull,
        );
      },
    );
  });

  group('QuantityParser.normalizeUnit', () {
    test('normalizes g -> g', () {
      expect(QuantityParser.normalizeUnit('g'), 'g');
    });

    test('normalizes gram -> g', () {
      expect(QuantityParser.normalizeUnit('gram'), 'g');
    });

    test('normalizes grams -> g', () {
      expect(QuantityParser.normalizeUnit('grams'), 'g');
    });

    test('normalizes kilogram -> kg', () {
      expect(QuantityParser.normalizeUnit('kilogram'), 'kg');
    });

    test(
      'normalizes kilograms -> kg',
      () => expect(QuantityParser.normalizeUnit('kilograms'), 'kg'),
    );

    test('normalizes ml -> ml', () {
      expect(QuantityParser.normalizeUnit('ml'), 'ml');
    });

    test('normalizes milliliter -> ml', () {
      expect(QuantityParser.normalizeUnit('milliliter'), 'ml');
    });

    test('normalizes millilitre -> ml', () {
      expect(QuantityParser.normalizeUnit('millilitre'), 'ml');
    });

    test(
      'normalizes L -> L',
      () => expect(QuantityParser.normalizeUnit('L'), 'L'),
    );

    test(
      'normalizes l -> L',
      () => expect(QuantityParser.normalizeUnit('l'), 'L'),
    );

    test(
      'normalizes liter -> L',
      () => expect(QuantityParser.normalizeUnit('liter'), 'L'),
    );

    test(
      'normalizes litre -> L',
      () => expect(QuantityParser.normalizeUnit('litre'), 'L'),
    );

    test(
      'normalizes cl -> ml',
      () => expect(QuantityParser.normalizeUnit('cl'), 'ml'),
    );

    test('normalizes centiliter -> ml', () {
      expect(QuantityParser.normalizeUnit('centiliter'), 'ml');
    });

    test(
      'normalizes oz -> oz',
      () => expect(QuantityParser.normalizeUnit('oz'), 'oz'),
    );

    test(
      'normalizes ounce -> oz',
      () => expect(QuantityParser.normalizeUnit('ounce'), 'oz'),
    );

    test(
      'normalizes pounds -> lb',
      () => expect(QuantityParser.normalizeUnit('pounds'), 'lb'),
    );

    test(
      'normalizes lbs -> lb',
      () => expect(QuantityParser.normalizeUnit('lbs'), 'lb'),
    );

    test(
      'returns null for null',
      () => expect(QuantityParser.normalizeUnit(null), isNull),
    );

    test('returns null for unrecognised unit', () {
      expect(QuantityParser.normalizeUnit('unknown'), isNull);
    });

    test('returns null for empty string', () {
      expect(QuantityParser.normalizeUnit(''), isNull);
    });
  });
}
