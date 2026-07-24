import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/services/recipe_nutri_score_service.dart';

void main() {
  late RecipeNutriScoreService service;

  setUp(() {
    service = RecipeNutriScoreService();
  });

  const productA = Product(
    barcode: '001',
    name: 'Healthy',
    nutriscoreGrade: 'a',
  );

  const productC = Product(
    barcode: '002',
    name: 'Medium',
    nutriscoreGrade: 'c',
  );

  const productE = Product(
    barcode: '003',
    name: 'Unhealthy',
    nutriscoreGrade: 'e',
  );

  const productNoScore = Product(
    barcode: '004',
    name: 'No Score',
  );

  group('RecipeNutriScoreService', () {
    test('returns null for empty ingredients', () {
      expect(service.compute([], {}), isNull);
    });

    test('returns null for free-text ingredients without barcode', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Salt',
          quantity: 10,
          unit: 'g',
        ),
      ];
      expect(service.compute(ingredients, {}), isNull);
    });

    test('returns grade for a single ingredient', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Healthy',
          barcode: '001',
          quantity: 100,
          unit: 'g',
        ),
      ];
      expect(service.compute(ingredients, {'001': productA}), 'A');
    });

    test('returns weighted average for multiple ingredients', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Healthy',
          barcode: '001',
          quantity: 100,
          unit: 'g',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Unhealthy',
          barcode: '003',
          quantity: 100,
          unit: 'g',
        ),
      ];
      // (5*100 + 1*100) / 200 = 3.0 -> 'C'
      expect(
        service.compute(ingredients, {'001': productA, '003': productE}),
        'C',
      );
    });

    test('weighted average favors larger quantities', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Healthy',
          barcode: '001',
          quantity: 400,
          unit: 'g',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Unhealthy',
          barcode: '003',
          quantity: 100,
          unit: 'g',
        ),
      ];
      // (5*400 + 1*100) / 500 = 4.2 -> 'B'
      expect(
        service.compute(ingredients, {'001': productA, '003': productE}),
        'B',
      );
    });

    test('returns null when no products have Nutri-Score', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'No Score',
          barcode: '004',
          quantity: 100,
          unit: 'g',
        ),
      ];
      expect(service.compute(ingredients, {'004': productNoScore}), isNull);
    });

    test('skips ingredients without score, uses remaining', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'No Score',
          barcode: '004',
          quantity: 100,
          unit: 'g',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Healthy',
          barcode: '001',
          quantity: 100,
          unit: 'g',
        ),
      ];
      // Only 'Healthy' contributes: 5.0 -> 'A'
      expect(
        service.compute(ingredients, {'001': productA, '004': productNoScore}),
        'A',
      );
    });

    test('handles scenario with three different grades', () {
      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'A',
          barcode: '001',
          quantity: 50,
          unit: 'g',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'C',
          barcode: '002',
          quantity: 50,
          unit: 'g',
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'E',
          barcode: '003',
          quantity: 100,
          unit: 'g',
        ),
      ];
      // (5*50 + 3*50 + 1*100) / 200 = 2.5 -> clamp(2.5, 1, 5) -> round(2.5) -> 3 -> 'C'
      expect(
        service.compute(ingredients, {
          '001': productA,
          '002': productC,
          '003': productE,
        }),
        'C',
      );
    });
  });
}
