import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/produce_nutrition_fallback.dart';

void main() {
  group('ProduceNutritionFallback.forName', () {
    test('returns nutrition for Apple', () {
      final result = ProduceNutritionFallback.forName('Apple');
      expect(result, isNotNull);
      final n = result!;
      expect(n.name, 'Apple');
      expect(n.energyKcal, closeTo(52, 1));
      expect(n.proteinG, closeTo(0.3, 0.1));
      expect(n.carbsG, closeTo(13.8, 1));
      expect(n.fatG, closeTo(0.2, 0.1));
      expect(n.fiberG, closeTo(2.4, 0.1));
    });

    test('returns nutrition for Banana', () {
      final result = ProduceNutritionFallback.forName('Banana');
      expect(result, isNotNull);
      final n = result!;
      expect(n.energyKcal, closeTo(89, 1));
      expect(n.proteinG, closeTo(1.1, 0.1));
      expect(n.carbsG, closeTo(22.8, 1));
      expect(n.fatG, closeTo(0.3, 0.1));
      expect(n.fiberG, closeTo(2.6, 0.1));
    });

    test('returns nutrition for Orange', () {
      final result = ProduceNutritionFallback.forName('Orange');
      expect(result, isNotNull);
      expect(result!.energyKcal, closeTo(47, 1));
    });

    test('returns nutrition for Tomato', () {
      final result = ProduceNutritionFallback.forName('Tomato');
      expect(result, isNotNull);
      expect(result!.energyKcal, closeTo(18, 1));
    });

    test('returns nutrition for Potato', () {
      final result = ProduceNutritionFallback.forName('Potato');
      expect(result, isNotNull);
      expect(result!.energyKcal, closeTo(77, 1));
    });

    test('returns nutrition for Carrot', () {
      final result = ProduceNutritionFallback.forName('Carrot');
      expect(result, isNotNull);
      expect(result!.energyKcal, closeTo(41, 1));
    });

    test('returns nutrition for Onion', () {
      final result = ProduceNutritionFallback.forName('Onion');
      expect(result, isNotNull);
      expect(result!.energyKcal, closeTo(40, 1));
    });

    test('returns nutrition for Lettuce', () {
      final result = ProduceNutritionFallback.forName('Lettuce');
      expect(result, isNotNull);
      expect(result!.energyKcal, closeTo(15, 1));
    });

    test('is case-insensitive', () {
      final lower = ProduceNutritionFallback.forName('apple');
      final upper = ProduceNutritionFallback.forName('APPLE');
      final mixed = ProduceNutritionFallback.forName('ApPlE');
      expect(lower, isNotNull);
      expect(upper, isNotNull);
      expect(mixed, isNotNull);
      expect(lower!.energyKcal, upper!.energyKcal);
      expect(lower.energyKcal, mixed!.energyKcal);
    });

    test('strips "Organic " prefix', () {
      final result = ProduceNutritionFallback.forName('Organic Apple');
      expect(result, isNotNull);
      expect(result!.energyKcal, closeTo(52, 1));
    });

    test('returns null for unknown produce', () {
      expect(ProduceNutritionFallback.forName('UnknownFruit123'), isNull);
    });

    test('returns null for empty name', () {
      expect(ProduceNutritionFallback.forName(''), isNull);
    });

    test('returns nutrition for all items in default quick-add list', () {
      const defaults = [
        'Apple',
        'Banana',
        'Orange',
        'Tomato',
        'Potato',
        'Carrot',
        'Onion',
        'Lettuce',
      ];
      for (final name in defaults) {
        expect(
          ProduceNutritionFallback.forName(name),
          isNotNull,
          reason: 'Missing fallback for "$name"',
        );
      }
    });
  });
}
