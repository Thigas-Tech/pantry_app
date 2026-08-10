import 'package:flutter_test/flutter_test.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/utils/nutrient_catalog.dart';

/// Tests for the [NutrientCatalog] curated nutrient set.
void main() {
  group('NutrientCatalog.nutrients', () {
    test('is non-empty', () {
      expect(NutrientCatalog.nutrients, isNotEmpty);
    });

    test('has unique offTags', () {
      final tags = NutrientCatalog.nutrients.map((n) => n.offTag).toList();
      expect(tags.toSet().length, tags.length);
    });

    test('excludes the six core nutrients', () {
      for (final core in NutrientCatalog.coreNutrients) {
        expect(
          NutrientCatalog.nutrients,
          isNot(contains(core)),
          reason: '${core.offTag} is a core nutrient',
        );
      }
    });

    test('excludes pet-food nutrients', () {
      for (final nutrient in NutrientCatalog.nutrients) {
        expect(
          nutrient.probablyPetFood,
          isFalse,
          reason: '${nutrient.offTag} is pet-food specific',
        );
      }
    });

    test('excludes read-only or computed tags', () {
      final tags = NutrientCatalog.nutrients.map((n) => n.offTag).toSet();
      for (final excluded in [
        'nutrition-score-fr',
        'nutrition-score-uk',
        'carbon-footprint',
        'glycemic-index',
        'water-hardness',
        'acidity',
        'ph',
        'energy-from-fat',
      ]) {
        expect(
          tags,
          isNot(contains(excluded)),
          reason: '$excluded is read-only/computed',
        );
      }
    });

    test('every nutrient resolves through Nutrient.fromOffTag', () {
      for (final nutrient in NutrientCatalog.nutrients) {
        expect(
          off.Nutrient.fromOffTag(nutrient.offTag),
          nutrient,
          reason: '${nutrient.offTag} must round-trip through fromOffTag',
        );
      }
    });

    test('every curated nutrient has editor units available', () {
      for (final nutrient in NutrientCatalog.nutrients) {
        expect(
          NutrientCatalog.allowedUnits(nutrient),
          isNotEmpty,
          reason: '${nutrient.offTag} has no editor units',
        );
      }
    });
  });

  group('NutrientCatalog.allowedUnits', () {
    test('weight nutrients offer g, mg, mcg', () {
      expect(
        NutrientCatalog.allowedUnits(off.Nutrient.vitaminC),
        ['g', 'mg', 'mcg'],
      );
      expect(
        NutrientCatalog.allowedUnits(off.Nutrient.sodium),
        ['g', 'mg', 'mcg'],
      );
    });

    test('energy nutrients offer kcal and kj', () {
      expect(
        NutrientCatalog.allowedUnits(off.Nutrient.energyKCal),
        ['kcal', 'kj'],
      );
    });

    test('percent nutrients offer only the percent unit', () {
      expect(NutrientCatalog.allowedUnits(off.Nutrient.alcohol), ['%']);
      expect(NutrientCatalog.allowedUnits(off.Nutrient.cocoa), ['%']);
    });

    test('unknown-unit nutrients offer nothing', () {
      expect(
        NutrientCatalog.allowedUnits(off.Nutrient.nutritionScoreFR),
        isEmpty,
      );
    });
  });

  group('NutrientCatalog.canonicalUnitFor', () {
    test('uses the typical unit canonical spelling', () {
      expect(NutrientCatalog.canonicalUnitFor(off.Nutrient.vitaminC), 'mg');
      expect(NutrientCatalog.canonicalUnitFor(off.Nutrient.sodium), 'g');
      expect(NutrientCatalog.canonicalUnitFor(off.Nutrient.selenium), 'mcg');
      expect(NutrientCatalog.canonicalUnitFor(off.Nutrient.alcohol), '%');
    });
  });

  group('NutrientCatalog.nutrientFromOffTag', () {
    test('resolves curated tags', () {
      expect(
        NutrientCatalog.nutrientFromOffTag('vitamin-c'),
        off.Nutrient.vitaminC,
      );
      expect(NutrientCatalog.nutrientFromOffTag('sodium'), off.Nutrient.sodium);
    });

    test('rejects the SDK energy special case', () {
      expect(NutrientCatalog.nutrientFromOffTag('energy'), isNull);
    });

    test('rejects core nutrient tags', () {
      expect(NutrientCatalog.nutrientFromOffTag('proteins'), isNull);
      expect(NutrientCatalog.nutrientFromOffTag('salt'), isNull);
      expect(NutrientCatalog.nutrientFromOffTag('energy-kcal'), isNull);
    });

    test('rejects unknown or uncurated tags', () {
      expect(NutrientCatalog.nutrientFromOffTag('not-a-nutrient'), isNull);
      expect(NutrientCatalog.nutrientFromOffTag('nutrition-score-fr'), isNull);
    });
  });
}
