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
