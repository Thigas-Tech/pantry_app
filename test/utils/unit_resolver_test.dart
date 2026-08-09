import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/unit_resolver.dart';

void main() {
  group('UnitResolver', () {
    group('systemFor', () {
      test('returns global metric when no override', () {
        const settings = Settings();
        expect(
          UnitResolver.systemFor(
            settings: settings,
            context: UnitContext.servingSize,
          ),
          UnitSystem.metric,
        );
      });

      test('returns global imperial when no override', () {
        const settings = Settings(unitSystem: UnitSystem.imperial);
        expect(
          UnitResolver.systemFor(
            settings: settings,
            context: UnitContext.servingSize,
          ),
          UnitSystem.imperial,
        );
      });

      test('uses override when present for servingSize', () {
        const settings = Settings(
          unitSystemServingSize: UnitSystem.imperial,
        );
        expect(
          UnitResolver.systemFor(
            settings: settings,
            context: UnitContext.servingSize,
          ),
          UnitSystem.imperial,
        );
      });

      test('uses override when present for recipeIngredients', () {
        const settings = Settings(
          unitSystem: UnitSystem.imperial,
          unitSystemRecipeIngredients: UnitSystem.metric,
        );
        expect(
          UnitResolver.systemFor(
            settings: settings,
            context: UnitContext.recipeIngredients,
          ),
          UnitSystem.metric,
        );
      });

      test('uses override when present for inventory', () {
        const settings = Settings(
          unitSystemInventory: UnitSystem.imperial,
        );
        expect(
          UnitResolver.systemFor(
            settings: settings,
            context: UnitContext.inventory,
          ),
          UnitSystem.imperial,
        );
      });

      test('global metric when another context has override', () {
        const settings = Settings(
          unitSystemServingSize: UnitSystem.imperial,
        );
        // recipeIngredients has no override, should fall back to global
        expect(
          UnitResolver.systemFor(
            settings: settings,
            context: UnitContext.recipeIngredients,
          ),
          UnitSystem.metric,
        );
      });
    });

    group('unitsForSystem', () {
      test('returns metric units for metric', () {
        expect(
          UnitResolver.unitsForSystem(UnitSystem.metric),
          ['pieces', 'g', 'kg', 'mg', 'mcg', 'ml', 'L'],
        );
      });

      test('returns imperial units for imperial', () {
        expect(
          UnitResolver.unitsForSystem(UnitSystem.imperial),
          ['pieces', 'oz', 'lb', 'fl oz', 'cup', 'tbsp', 'tsp'],
        );
      });
    });

    group('isMetricUnit', () {
      test('g is metric', () {
        expect(UnitResolver.isMetricUnit('g'), isTrue);
      });

      test('kg is metric', () {
        expect(UnitResolver.isMetricUnit('kg'), isTrue);
      });

      test('mg is metric', () {
        expect(UnitResolver.isMetricUnit('mg'), isTrue);
      });

      test('mcg is metric', () {
        expect(UnitResolver.isMetricUnit('mcg'), isTrue);
      });

      test('ml is metric', () {
        expect(UnitResolver.isMetricUnit('ml'), isTrue);
      });

      test('L is metric', () {
        expect(UnitResolver.isMetricUnit('L'), isTrue);
      });

      test('oz is imperial', () {
        expect(UnitResolver.isMetricUnit('oz'), isFalse);
      });

      test('lb is imperial', () {
        expect(UnitResolver.isMetricUnit('lb'), isFalse);
      });

      test('fl oz is imperial', () {
        expect(UnitResolver.isMetricUnit('fl oz'), isFalse);
      });

      test('cup is imperial', () {
        expect(UnitResolver.isMetricUnit('cup'), isFalse);
      });

      test('tbsp is imperial', () {
        expect(UnitResolver.isMetricUnit('tbsp'), isFalse);
      });

      test('tsp is imperial', () {
        expect(UnitResolver.isMetricUnit('tsp'), isFalse);
      });

      test('pieces is metric (neutral)', () {
        expect(UnitResolver.isMetricUnit('pieces'), isTrue);
      });
    });
  });
}
