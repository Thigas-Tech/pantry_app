import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/utils/nutriscore.dart';

/// Computes a Nutri-Score grade for a recipe based on its ingredients.
///
/// Uses a weighted average of each ingredient's individual Nutri-Score grade
/// (from the OFF data), weighted by ingredient quantity. Ingredients without
/// a barcode or without a known Nutri-Score grade contribute nothing and
/// reduce the confidence of the result.
class RecipeNutriScoreService {
  /// Computes a Nutri-Score grade for a recipe.
  ///
  /// Returns a grade letter ('a'–'e') or null when too few ingredients have
  /// known scores. The result is a weighted average across all scored
  /// ingredients: the ingredient with the largest quantity has the most
  /// influence.
  String? compute(
    List<RecipeIngredient> ingredients,
    Map<String, Product> productsByBarcode,
  ) {
    var totalScoreWeighted = 0.0;
    var totalWeight = 0.0;

    for (final ingredient in ingredients) {
      if (ingredient.barcode == null || ingredient.barcode!.isEmpty) continue;

      final product = productsByBarcode[ingredient.barcode];
      if (product == null) continue;

      final grade = product.nutriscoreGrade;
      if (grade == null || grade.isEmpty) continue;
      if (nutriscoreIsNotApplicable(grade)) continue;

      final numeric = nutriscoreGradeToNumeric(grade);
      if (numeric == null) continue;

      totalScoreWeighted += numeric * ingredient.quantity;
      totalWeight += ingredient.quantity;
    }

    if (totalWeight <= 0) return null;

    final average = totalScoreWeighted / totalWeight;
    return nutriscoreNumericToLetter(average);
  }
}
