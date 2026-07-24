import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/recipe_nutrition.dart';
import 'package:pantry_app/widgets/recipe_nutrition_table.dart';
import '../helpers/pump_app.dart';

void main() {
  group('RecipeNutritionTable', () {
    testWidgets('displays per 100g values', (tester) async {
      const nutrition = RecipeNutrition(
        totalWeightG: 200,
        totalEnergyKcal: 100,
        totalProteinG: 10,
        totalCarbsG: 20,
        totalFatG: 5,
        totalFiberG: 2,
        totalSaltG: 1,
      );

      await pumpApp(
        tester,
        const SingleChildScrollView(
          child: RecipeNutritionTable(nutrition: nutrition),
        ),
      );

      // Per 100g: 100/200*100 = 50.0 kcal -> '50.0 g' appears
      expect(find.text('50.0 g'), findsOneWidget);
    });

    testWidgets('shows per-serving column when servings > 0', (tester) async {
      const nutrition = RecipeNutrition(
        totalWeightG: 400,
        totalEnergyKcal: 200,
        totalProteinG: 20,
        totalCarbsG: 40,
        totalFatG: 10,
        totalFiberG: 4,
        totalSaltG: 2,
        servings: 4,
      );

      await pumpApp(
        tester,
        const SingleChildScrollView(
          child: RecipeNutritionTable(nutrition: nutrition),
        ),
      );

      expect(find.text('Per serving'), findsOneWidget);
      // Per serving: 200/4 = 50.0 -> '50.0 g'
      expect(find.text('50.0 g'), findsWidgets);
    });
  });
}
