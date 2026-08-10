/// Tests for the [OffUnitCatalog] unit catalog.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/utils/off_units.dart';

void main() {
  group('OffUnitCatalog.sdkUnitToCanonical', () {
    test('covers every member of the OFF Unit enum', () {
      expect(
        OffUnitCatalog.sdkUnitToCanonical.keys.toSet(),
        off.Unit.values.toSet(),
      );
    });

    test('maps weight and volume units to their app spellings', () {
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.G], 'g');
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.MILLI_G], 'mg');
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.MICRO_G], 'mcg');
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.MILLI_L], 'ml');
    });

    test('normalizes the SDK liter and percent tags', () {
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.L], 'L');
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.PERCENT], '%');
    });

    test('maps nutrition-only units to their raw tags', () {
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.KCAL], 'kcal');
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.KJ], 'kj');
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.G_PER_KG], 'g/kg');
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.PERCENT_DV], '% DV');
      expect(OffUnitCatalog.sdkUnitToCanonical[off.Unit.IU], 'IU');
    });

    test('has no duplicate or empty values', () {
      final values = OffUnitCatalog.sdkUnitToCanonical.values.toList();
      expect(values.toSet().length, values.length);
      expect(values.any((v) => v.isEmpty), isFalse);
    });
  });

  group('OffUnitCatalog.canonicalToSdkUnit', () {
    test('resolves canonical weight and volume units', () {
      expect(OffUnitCatalog.canonicalToSdkUnit('g'), off.Unit.G);
      expect(OffUnitCatalog.canonicalToSdkUnit('mg'), off.Unit.MILLI_G);
      expect(OffUnitCatalog.canonicalToSdkUnit('mcg'), off.Unit.MICRO_G);
      expect(OffUnitCatalog.canonicalToSdkUnit('L'), off.Unit.L);
      expect(OffUnitCatalog.canonicalToSdkUnit('ml'), off.Unit.MILLI_L);
    });

    test('resolves nutrition-only units', () {
      expect(OffUnitCatalog.canonicalToSdkUnit('kcal'), off.Unit.KCAL);
      expect(OffUnitCatalog.canonicalToSdkUnit('kj'), off.Unit.KJ);
      expect(OffUnitCatalog.canonicalToSdkUnit('%'), off.Unit.PERCENT);
    });

    test('round-trips every canonical spelling through the map', () {
      for (final entry in OffUnitCatalog.sdkUnitToCanonical.entries) {
        expect(
          OffUnitCatalog.canonicalToSdkUnit(entry.value),
          entry.key,
          reason: '${entry.value} must resolve back to ${entry.key}',
        );
      }
    });

    test('returns null for units outside the SDK enum', () {
      expect(OffUnitCatalog.canonicalToSdkUnit('kg'), isNull);
      expect(OffUnitCatalog.canonicalToSdkUnit('pieces'), isNull);
      expect(OffUnitCatalog.canonicalToSdkUnit(''), isNull);
    });
  });

  group('OffUnitCatalog nutrient unit sets', () {
    test('nutrientWeightUnits offers g, mg, mcg', () {
      expect(OffUnitCatalog.nutrientWeightUnits, ['g', 'mg', 'mcg']);
    });

    test('energyUnits offers kcal and kj', () {
      expect(OffUnitCatalog.energyUnits, ['kcal', 'kj']);
    });

    test('percentUnits offers only the percent unit', () {
      expect(OffUnitCatalog.percentUnits, ['%']);
    });
  });

  group('OffUnitCatalog.sdkQuantityUnits', () {
    test('contains only OFF quantity units in canonical order', () {
      expect(
        OffUnitCatalog.sdkQuantityUnits,
        ['g', 'mg', 'mcg', 'ml', 'L'],
      );
    });

    test('excludes nutrition-only units', () {
      for (final unit in ['kcal', 'kj', '%', 'g/kg', '% DV', 'IU']) {
        expect(
          OffUnitCatalog.sdkQuantityUnits,
          isNot(contains(unit)),
          reason: 'sdkQuantityUnits must not offer $unit',
        );
      }
    });

    test('excludes app-invented units outside the enum', () {
      expect(OffUnitCatalog.sdkQuantityUnits, isNot(contains('kg')));
      expect(OffUnitCatalog.sdkQuantityUnits, isNot(contains('pieces')));
    });
  });

  group('OffUnitCatalog.quantityUnits', () {
    test('adds mg and mcg to the metric inventory units', () {
      expect(
        OffUnitCatalog.quantityUnits,
        ['pieces', 'g', 'kg', 'mg', 'mcg', 'ml', 'L'],
      );
    });
  });

  group('OffUnitCatalog.imperialUnits', () {
    test('is unchanged', () {
      expect(
        OffUnitCatalog.imperialUnits,
        ['pieces', 'oz', 'lb', 'fl oz', 'cup', 'tbsp', 'tsp'],
      );
    });
  });
}
