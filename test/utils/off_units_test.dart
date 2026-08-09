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
