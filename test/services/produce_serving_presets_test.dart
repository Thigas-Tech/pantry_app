import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/produce_serving_presets.dart';

void main() {
  group('ProduceServingPresets', () {
    group('forName', () {
      test('returns serving sizes for Apple (exact match)', () {
        final sizes = ProduceServingPresets.forName('Apple');
        expect(sizes, isNotNull);
        expect(sizes!['Small'], 149);
        expect(sizes['Medium'], 182);
        expect(sizes['Large'], 223);
      });

      test('is case-insensitive', () {
        final sizes = ProduceServingPresets.forName('apple');
        expect(sizes, isNotNull);
        expect(sizes!['Medium'], 182);
      });

      test('matches by contains for OFF-style names', () {
        final sizes = ProduceServingPresets.forName(
          'Apple, raw, with skin',
        );
        expect(sizes, isNotNull);
        expect(sizes!['Medium'], 182);
      });

      test('strips "Organic" prefix before lookup', () {
        final sizes = ProduceServingPresets.forName('Organic Banana');
        expect(sizes, isNotNull);
        expect(sizes!['Medium'], 118);
      });

      test('returns null for unknown produce', () {
        final sizes = ProduceServingPresets.forName('Gala');
        expect(sizes, isNull);
      });

      test('returns null for non-produce', () {
        final sizes = ProduceServingPresets.forName('Canned Soup');
        expect(sizes, isNull);
      });
    });

    group('totalWeight', () {
      test('2 medium apples = 364g', () {
        final weight = ProduceServingPresets.totalWeight(
          'Apple',
          'Medium',
          quantity: 2,
        );
        expect(weight, 364);
      });

      test('default quantity is 1', () {
        final weight = ProduceServingPresets.totalWeight(
          'Apple',
          'Medium',
        );
        expect(weight, 182);
      });

      test('returns null for unknown produce', () {
        final weight = ProduceServingPresets.totalWeight(
          'Unknown',
          'Medium',
        );
        expect(weight, isNull);
      });

      test('returns null for unknown size', () {
        final weight = ProduceServingPresets.totalWeight(
          'Apple',
          'ExtraLarge',
        );
        expect(weight, isNull);
      });
    });

    group('nutrition', () {
      test('1 medium apple (182g) at 52 kcal/100g = 94.6 kcal', () {
        final kcal = ProduceServingPresets.nutrition(
          'Apple',
          'Medium',
          52,
        );
        expect(kcal, closeTo(94.64, 0.01));
      });

      test('2 medium bananas (118g each) at 89 kcal/100g = 210.0 kcal', () {
        final kcal = ProduceServingPresets.nutrition(
          'Banana',
          'Medium',
          89,
          quantity: 2,
        );
        expect(kcal, closeTo(210.04, 0.01));
      });

      test('returns null for unknown produce', () {
        final kcal = ProduceServingPresets.nutrition('Unknown', 'Medium', 100);
        expect(kcal, isNull);
      });
    });

    group('sizeLabels', () {
      test('returns size labels for known produce', () {
        final labels = ProduceServingPresets.sizeLabels('Apple');
        expect(labels, ['Small', 'Medium', 'Large']);
      });

      test('returns generic sizes for unknown produce', () {
        final labels = ProduceServingPresets.sizeLabels('Unknown');
        expect(labels, ['Small', 'Medium', 'Large']);
      });
    });
  });
}
