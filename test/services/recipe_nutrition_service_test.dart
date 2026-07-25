import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/recipe_nutrition.dart';
import 'package:pantry_app/services/recipe_nutrition_service.dart';

void main() {
  late RecipeNutritionService service;

  setUp(() {
    service = RecipeNutritionService();
  });

  const milk = Product(
    barcode: '001',
    name: 'Milk',
    energyKcal: 42,
    proteinG: 3.4,
    carbsG: 5,
    fatG: 1,
    fiberG: 0,
    saltG: 0.1,
  );

  const egg = Product(
    barcode: '002',
    name: 'Egg',
    energyKcal: 155,
    proteinG: 13,
    carbsG: 1.1,
    fatG: 11,
    fiberG: 0,
    saltG: 0.3,
  );

  group('RecipeNutritionService', () {
    test('aggregate returns zeros for empty ingredients', () {
      final result = service.aggregate([], {});
      expect(result.totalWeightG, 0);
      expect(result.totalEnergyKcal, 0);
    });

    test('aggregate returns zeros for free-text ingredients (no barcode)', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Salt',
          quantity: 10,
          unit: 'g',
        ),
      ];
      final result = service.aggregate(ingredients, {});
      expect(result.totalWeightG, 0);
      expect(result.totalEnergyKcal, 0);
    });

    test('aggregate single ingredient by weight', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          quantity: 200,
          unit: 'g',
        ),
      ];
      final result = service.aggregate(ingredients, {'001': milk});
      // 200g = 2 * 100g portions
      expect(result.totalWeightG, 200);
      expect(result.totalEnergyKcal, closeTo(84, 0.01)); // 42 * 2
      expect(result.totalProteinG, closeTo(6.8, 0.01)); // 3.4 * 2
      expect(result.per100gEnergyKcal, closeTo(42, 0.01)); // same as product
    });

    test('aggregate multiple ingredients sums correctly', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          quantity: 100,
          unit: 'g',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Egg',
          barcode: '002',
          quantity: 50,
          unit: 'g',
        ),
      ];
      final result = service.aggregate(
        ingredients,
        {'001': milk, '002': egg},
      );
      expect(result.totalWeightG, 150);
      // Milk: 100g -> factor 1.0 -> 42 kcal
      // Egg: 50g -> factor 0.5 -> 77.5 kcal
      expect(result.totalEnergyKcal, closeTo(119.5, 0.01));
      // Per 100g: 119.5 / 150 * 100
      expect(result.per100gEnergyKcal, closeTo(79.67, 0.01));
    });

    test('aggregate handles volume units (ml, L, tbsp, tsp, cup)', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          quantity: 100,
          unit: 'ml',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          unit: 'L',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          quantity: 2,
          unit: 'tbsp',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          quantity: 3,
          unit: 'tsp',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          unit: 'cup',
        ),
      ];
      final result = service.aggregate(ingredients, {'001': milk});
      // 100ml + 1000ml + 30ml + 15ml + 240ml = 1385g
      expect(result.totalWeightG, closeTo(1385, 0.01));
      // 1385 / 100 * 42 = 581.7 kcal
      expect(result.totalEnergyKcal, closeTo(581.7, 0.01));
    });

    test('aggregate skips piece-based ingredients', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Egg',
          barcode: '002',
          quantity: 2,
        ),
      ];
      // pieces cannot be converted to grams -> weight stays 0
      final result = service.aggregate(ingredients, {'002': egg});
      expect(result.totalWeightG, 0);
      expect(result.totalEnergyKcal, 0);
    });

    test('aggregate per-serving normalization', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          quantity: 400,
          unit: 'g',
        ),
      ];
      final result = service.aggregate(
        ingredients,
        {'001': milk},
        servings: 4,
      );
      // 400g total, 4 servings
      expect(result.servings, 4);
      // Total: 400/100 * 42 = 168 kcal
      expect(result.totalEnergyKcal, closeTo(168, 0.01));
      // Per serving: 168 / 4 = 42 kcal
      expect(result.perServingEnergyKcal, closeTo(42, 0.01));
      // Per 100g: 168 / 400 * 100 = 42 kcal (matches product)
      expect(result.per100gEnergyKcal, closeTo(42, 0.01));
    });

    test('aggregate handles unknown units gracefully', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          quantity: 100,
          unit: 'unknown',
        ),
      ];
      final result = service.aggregate(ingredients, {'001': milk});
      expect(result.totalWeightG, 0);
      expect(result.totalEnergyKcal, 0);
    });

    test('aggregate handles missing products gracefully', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          quantity: 100,
          unit: 'g',
        ),
      ];
      // barcode '001' not in products map
      final result = service.aggregate(ingredients, {});
      expect(result.totalWeightG, 0);
      expect(result.totalEnergyKcal, 0);
    });

    test('aggregate handles kg unit correctly', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Milk',
          barcode: '001',
          unit: 'kg',
        ),
      ];
      final result = service.aggregate(ingredients, {'001': milk});
      expect(result.totalWeightG, 1000);
      expect(result.totalEnergyKcal, closeTo(420, 0.01)); // 1000/100 * 42
    });

    test('RecipeNutrition equality and hashCode', () {
      const a = RecipeNutrition(
        totalWeightG: 100,
        totalEnergyKcal: 50,
        totalProteinG: 5,
        totalCarbsG: 10,
        totalFatG: 2,
        totalFiberG: 1,
        totalSaltG: 0.5,
      );
      const b = RecipeNutrition(
        totalWeightG: 100,
        totalEnergyKcal: 50,
        totalProteinG: 5,
        totalCarbsG: 10,
        totalFatG: 2,
        totalFiberG: 1,
        totalSaltG: 0.5,
      );
      const c = RecipeNutrition(
        totalWeightG: 200,
        totalEnergyKcal: 50,
        totalProteinG: 5,
        totalCarbsG: 10,
        totalFatG: 2,
        totalFiberG: 1,
        totalSaltG: 0.5,
      );
      expect(a.totalWeightG, equals(b.totalWeightG));
      expect(a.totalEnergyKcal, equals(b.totalEnergyKcal));
      expect(a.totalWeightG, isNot(equals(c.totalWeightG)));
    });
  });
}
