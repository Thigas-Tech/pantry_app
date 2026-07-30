import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/unit_conversion.dart';

void main() {
  group('normalizeToGrams', () {
    test('passes grams through', () {
      expect(UnitConverter.normalizeToGrams(100, 'g'), 100.0);
    });

    test('converts kg to g', () {
      expect(UnitConverter.normalizeToGrams(1, 'kg'), 1000.0);
    });

    test('converts oz to g', () {
      expect(UnitConverter.normalizeToGrams(16, 'oz'), closeTo(453.592, 0.001));
    });

    test('converts lb to g', () {
      expect(UnitConverter.normalizeToGrams(2, 'lb'), closeTo(907.184, 0.001));
    });

    test('handles zero', () {
      expect(UnitConverter.normalizeToGrams(0, 'g'), 0.0);
    });

    test('returns 0 for unsupported unit', () {
      expect(UnitConverter.normalizeToGrams(10, 'pieces'), 0.0);
    });
  });

  group('normalizeToMilliliters', () {
    test('passes ml through', () {
      expect(UnitConverter.normalizeToMilliliters(500, 'ml'), 500.0);
    });

    test('converts L to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'L'), 1000.0);
    });

    test('converts fl oz to ml', () {
      expect(
        UnitConverter.normalizeToMilliliters(1, 'fl oz'),
        closeTo(29.5735, 0.0001),
      );
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

    test('oz and g are compatible', () {
      expect(UnitConverter.areUnitsCompatible('oz', 'g'), isTrue);
    });

    test('oz and lb are compatible', () {
      expect(UnitConverter.areUnitsCompatible('oz', 'lb'), isTrue);
    });

    test('ml and L are compatible', () {
      expect(UnitConverter.areUnitsCompatible('ml', 'L'), isTrue);
    });

    test('fl oz and ml are compatible', () {
      expect(UnitConverter.areUnitsCompatible('fl oz', 'ml'), isTrue);
    });

    test('fl oz and cup are compatible', () {
      expect(UnitConverter.areUnitsCompatible('fl oz', 'cup'), isTrue);
    });

    test('pieces and pieces are compatible', () {
      expect(UnitConverter.areUnitsCompatible('pieces', 'pieces'), isTrue);
    });

    test('g and ml are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('g', 'ml'), isFalse);
    });

    test('oz and ml are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('oz', 'ml'), isFalse);
    });

    test('fl oz and g are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('fl oz', 'g'), isFalse);
    });

    test('pieces and oz are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('pieces', 'oz'), isFalse);
    });
  });

  group('convertBack', () {
    test('converts g back to kg', () {
      expect(UnitConverter.convertBack(1000, 'kg'), 1.0);
    });

    test('converts ml back to L', () {
      expect(UnitConverter.convertBack(2000, 'L'), 2.0);
    });

    test('converts g back to oz', () {
      expect(UnitConverter.convertBack(28.3495, 'oz'), closeTo(1.0, 0.0001));
    });

    test('converts g back to lb', () {
      expect(UnitConverter.convertBack(453.592, 'lb'), closeTo(1.0, 0.0001));
    });

    test('converts ml back to fl oz', () {
      expect(
        UnitConverter.convertBack(29.5735, 'fl oz'),
        closeTo(1.0, 0.0001),
      );
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

    test('handles near-zero quantity', () {
      expect(UnitConverter.convert(0.001, 'kg', 'g'), 1.0);
    });

    test('handles negative quantity', () {
      expect(UnitConverter.convert(-2, 'kg', 'g'), -2000.0);
    });

    test('handles very large quantity', () {
      expect(
        UnitConverter.convert(1000000, 'g', 'kg'),
        1000.0,
      );
    });

    test('converts 500 ml to 0.5 L', () {
      expect(UnitConverter.convert(500, 'ml', 'L'), 0.5);
    });

    test('converts 16 oz to g', () {
      expect(
        UnitConverter.convert(16, 'oz', 'g'),
        closeTo(453.592, 0.001),
      );
    });

    test('converts 2 lb to kg', () {
      expect(UnitConverter.convert(2, 'lb', 'kg'), closeTo(0.907184, 0.0001));
    });

    test('converts 1 lb to oz', () {
      expect(UnitConverter.convert(1, 'lb', 'oz'), 16.0);
    });

    test('converts 1 kg to lb', () {
      expect(UnitConverter.convert(1, 'kg', 'lb'), closeTo(2.20462, 0.0001));
    });

    test('converts 8 fl oz to ml', () {
      expect(
        UnitConverter.convert(8, 'fl oz', 'ml'),
        closeTo(236.588, 0.001),
      );
    });

    test('converts 240 ml to cup', () {
      expect(UnitConverter.convert(240, 'ml', 'cup'), 1.0);
    });

    test('converts 500 ml to fl oz', () {
      expect(
        UnitConverter.convert(500, 'ml', 'fl oz'),
        closeTo(16.907, 0.001),
      );
    });

    test('leaves pieces unchanged', () {
      expect(UnitConverter.convert(3, 'pieces', 'pieces'), 3.0);
    });

    test('returns original for incompatible units', () {
      expect(UnitConverter.convert(100, 'g', 'ml'), 100.0);
    });
  });

  group('autoScale', () {
    test('handles zero', () {
      final result = UnitConverter.autoScale(0, 'g');
      expect(result.quantity, 0.0);
      expect(result.unit, 'g');
    });

    test('scales g to kg above threshold', () {
      final result = UnitConverter.autoScale(1500, 'g');
      expect(result.quantity, 1.5);
      expect(result.unit, 'kg');
    });

    test('keeps g as g under threshold', () {
      final result = UnitConverter.autoScale(500, 'g');
      expect(result.quantity, 500.0);
      expect(result.unit, 'g');
    });

    test('scales ml to L above threshold', () {
      final result = UnitConverter.autoScale(2000, 'ml');
      expect(result.quantity, 2.0);
      expect(result.unit, 'L');
    });

    test('keeps ml as ml under threshold', () {
      final result = UnitConverter.autoScale(500, 'ml');
      expect(result.quantity, 500.0);
      expect(result.unit, 'ml');
    });

    test('scales oz to lb above threshold', () {
      final result = UnitConverter.autoScale(32, 'oz');
      expect(result.quantity, 2.0);
      expect(result.unit, 'lb');
    });

    test('keeps oz as oz under threshold', () {
      final result = UnitConverter.autoScale(8, 'oz');
      expect(result.quantity, 8.0);
      expect(result.unit, 'oz');
    });

    test('passes pieces through unchanged', () {
      final result = UnitConverter.autoScale(3, 'pieces');
      expect(result.quantity, 3.0);
      expect(result.unit, 'pieces');
    });

    test('scales fl oz to cups above threshold', () {
      final result = UnitConverter.autoScale(16, 'fl oz');
      expect(result.quantity, closeTo(2.0, 0.01));
      expect(result.unit, 'cup');
    });

    test('keeps fl oz as fl oz under threshold', () {
      final result = UnitConverter.autoScale(1, 'fl oz');
      expect(result.quantity, 1.0);
      expect(result.unit, 'fl oz');
    });

    test('handles near-zero g', () {
      final result = UnitConverter.autoScale(0.001, 'g');
      expect(result.quantity, 0.0);
      expect(result.unit, 'g');
    });

    test('handles very large value g -> kg', () {
      final result = UnitConverter.autoScale(1e9, 'g');
      expect(result.quantity, 1e6);
      expect(result.unit, 'kg');
    });
  });

  group('displayUnit', () {
    test('returns scaled metric for metric system (g to kg)', () {
      final result = UnitConverter.displayUnit(
        1500,
        'g',
        UnitSystem.metric,
      );
      expect(result.quantity, 1.5);
      expect(result.unit, 'kg');
    });

    test('returns as-is for metric system under threshold', () {
      final result = UnitConverter.displayUnit(
        500,
        'g',
        UnitSystem.metric,
      );
      expect(result.quantity, 500.0);
      expect(result.unit, 'g');
    });

    test('converts g to oz with weightPref=ounces', () {
      final result = UnitConverter.displayUnit(
        100,
        'g',
        UnitSystem.imperial,
        weightPref: WeightUnitPreference.ounces,
      );
      expect(result.quantity, closeTo(3.5, 0.1));
      expect(result.unit, 'oz');
    });

    test('converts g to lb with weightPref=pounds', () {
      final result = UnitConverter.displayUnit(
        500,
        'g',
        UnitSystem.imperial,
        weightPref: WeightUnitPreference.pounds,
      );
      expect(result.quantity, closeTo(1.0, 0.1));
      expect(result.unit, 'lb');
    });

    test(
      'auto-scales weight in imperial with weightPref=auto (large -> lb)',
      () {
        final result = UnitConverter.displayUnit(
          1000,
          'g',
          UnitSystem.imperial,
          weightPref: WeightUnitPreference.auto,
        );
        expect(result.quantity, closeTo(2.0, 0.1));
        expect(result.unit, 'lb');
      },
    );

    test(
      'auto-scales weight in imperial with weightPref=auto (small -> oz)',
      () {
        final result = UnitConverter.displayUnit(
          100,
          'g',
          UnitSystem.imperial,
          weightPref: WeightUnitPreference.auto,
        );
        expect(result.quantity, closeTo(3.5, 0.1));
        expect(result.unit, 'oz');
      },
    );

    test('converts ml to fl oz with volumePref=fluidOunces', () {
      final result = UnitConverter.displayUnit(
        240,
        'ml',
        UnitSystem.imperial,
        volumePref: VolumeUnitPreference.fluidOunces,
      );
      expect(result.quantity, closeTo(8.1, 0.1));
      expect(result.unit, 'fl oz');
    });

    test('converts ml to cup with volumePref=cups', () {
      final result = UnitConverter.displayUnit(
        500,
        'ml',
        UnitSystem.imperial,
        volumePref: VolumeUnitPreference.cups,
      );
      expect(result.quantity, closeTo(2.0, 0.1));
      expect(result.unit, 'cup');
    });

    test('converts ml to tbsp with volumePref=tablespoons', () {
      final result = UnitConverter.displayUnit(
        30,
        'ml',
        UnitSystem.imperial,
        volumePref: VolumeUnitPreference.tablespoons,
      );
      expect(result.quantity, closeTo(2.0, 0.1));
      expect(result.unit, 'tbsp');
    });

    test('converts ml to tsp with volumePref=teaspoons', () {
      final result = UnitConverter.displayUnit(
        10,
        'ml',
        UnitSystem.imperial,
        volumePref: VolumeUnitPreference.teaspoons,
      );
      expect(result.quantity, closeTo(2.0, 0.1));
      expect(result.unit, 'tsp');
    });

    test(
      'auto-scales volume in imperial with volumePref=auto (large -> cup)',
      () {
        final result = UnitConverter.displayUnit(
          500,
          'ml',
          UnitSystem.imperial,
          volumePref: VolumeUnitPreference.auto,
        );
        expect(result.quantity, closeTo(2.0, 0.1));
        expect(result.unit, 'cup');
      },
    );

    test(
      'auto-scales volume in imperial with volumePref=auto (medium -> fl oz)',
      () {
        final result = UnitConverter.displayUnit(
          100,
          'ml',
          UnitSystem.imperial,
          volumePref: VolumeUnitPreference.auto,
        );
        expect(result.quantity, closeTo(3.4, 0.1));
        expect(result.unit, 'fl oz');
      },
    );

    test(
      'auto-scales volume in imperial with volumePref=auto (small -> tbsp)',
      () {
        final result = UnitConverter.displayUnit(
          15,
          'ml',
          UnitSystem.imperial,
          volumePref: VolumeUnitPreference.auto,
        );
        expect(result.quantity, closeTo(1.0, 0.1));
        expect(result.unit, 'tbsp');
      },
    );

    test(
      'auto-scales volume in imperial with volumePref=auto (tiny -> tsp)',
      () {
        final result = UnitConverter.displayUnit(
          5,
          'ml',
          UnitSystem.imperial,
          volumePref: VolumeUnitPreference.auto,
        );
        expect(result.quantity, closeTo(1.0, 0.1));
        expect(result.unit, 'tsp');
      },
    );

    test('pieces never convert regardless of system', () {
      final result = UnitConverter.displayUnit(
        3,
        'pieces',
        UnitSystem.imperial,
      );
      expect(result.quantity, 3.0);
      expect(result.unit, 'pieces');
    });

    test('pcs (unknown) passes through unchanged', () {
      final result = UnitConverter.displayUnit(
        1,
        'pcs',
        UnitSystem.imperial,
      );
      expect(result.quantity, 1.0);
      expect(result.unit, 'pcs');
    });

    test('handles small quantity grams in imperial', () {
      final result = UnitConverter.displayUnit(
        28,
        'g',
        UnitSystem.imperial,
        weightPref: WeightUnitPreference.ounces,
      );
      expect(result.quantity, closeTo(1.0, 0.1));
      expect(result.unit, 'oz');
    });

    test('handles near-zero grams in metric', () {
      final result = UnitConverter.displayUnit(
        0.001,
        'g',
        UnitSystem.metric,
      );
      expect(result.quantity, 0.0);
      expect(result.unit, 'g');
    });

    test('converts imperial unit to metric when system is metric', () {
      final result = UnitConverter.displayUnit(
        16,
        'oz',
        UnitSystem.metric,
      );
      expect(result.quantity, closeTo(454.0, 0.1));
      expect(result.unit, 'g');
    });
  });

  group('allUnitsForSystem', () {
    test('returns metric units for metric system', () {
      expect(UnitConverter.allUnitsForSystem(UnitSystem.metric), [
        'pieces',
        'g',
        'kg',
        'ml',
        'L',
      ]);
    });

    test('returns imperial units for imperial system', () {
      expect(UnitConverter.allUnitsForSystem(UnitSystem.imperial), [
        'pieces',
        'oz',
        'lb',
        'fl oz',
        'cup',
        'tbsp',
        'tsp',
      ]);
    });
  });
}
