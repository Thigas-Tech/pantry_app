import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/recipe_nutrition.dart';
import 'package:pantry_app/utils/logger.dart';

/// Converts ingredient quantities to grams.
///
/// For volume units (ml, L, tbsp, tsp, cup) a density of 1.0 g/ml is assumed
/// (i.e. water-like density). For piece-based ingredients the conversion
/// returns 0 — the caller should provide a per-piece weight or skip them.
double _convertToGrams(double quantity, String unit) {
  switch (unit) {
    case 'g':
      return quantity;
    case 'kg':
      return quantity * 1000;
    case 'ml':
      return quantity;
    case 'L':
      return quantity * 1000;
    case 'tbsp':
      return quantity * 15;
    case 'tsp':
      return quantity * 5;
    case 'cup':
      return quantity * 240;
    default:
      return 0;
  }
}

/// Aggregates nutrition data from a list of [RecipeIngredient]s and their
/// corresponding [Product] data.
///
/// Ingredients without a barcode or whose product is not in the products map
/// are skipped (they contribute zero nutrients). Piece-based ingredients
/// without a known per-piece weight are also skipped.
class RecipeNutritionService {
  /// Aggregates all ingredients into a [RecipeNutrition] summary.
  ///
  /// [productsByBarcode] maps product barcodes to [Product] objects.
  /// Ingredients whose barcode is null or not present in the map are skipped.
  /// [servings] is passed through for per-serving computations.
  RecipeNutrition aggregate(
    List<RecipeIngredient> ingredients,
    Map<String, Product> productsByBarcode, {
    int servings = 0,
  }) {
    var totalWeight = 0.0;
    var energyKcal = 0.0;
    var proteinG = 0.0;
    var carbsG = 0.0;
    var fatG = 0.0;
    var fiberG = 0.0;
    var saltG = 0.0;

    for (final ingredient in ingredients) {
      if (ingredient.barcode == null || ingredient.barcode!.isEmpty) continue;

      final product = productsByBarcode[ingredient.barcode];
      if (product == null) continue;

      final grams = _convertToGrams(ingredient.quantity, ingredient.unit);
      if (grams <= 0) continue;

      final factor = grams / 100;
      totalWeight += grams;
      energyKcal += (product.energyKcal ?? 0) * factor;
      proteinG += (product.proteinG ?? 0) * factor;
      carbsG += (product.carbsG ?? 0) * factor;
      fatG += (product.fatG ?? 0) * factor;
      fiberG += (product.fiberG ?? 0) * factor;
      saltG += (product.saltG ?? 0) * factor;
    }

    final nutrition = RecipeNutrition(
      totalWeightG: totalWeight,
      totalEnergyKcal: energyKcal,
      totalProteinG: proteinG,
      totalCarbsG: carbsG,
      totalFatG: fatG,
      totalFiberG: fiberG,
      totalSaltG: saltG,
      servings: servings,
    );

    logInfo(
      'Aggregated nutrition for ${ingredients.length} ingredients: '
      '${nutrition.totalEnergyKcal.toStringAsFixed(0)} kcal total, '
      '${nutrition.per100gEnergyKcal.toStringAsFixed(0)} kcal/100g',
    );

    return nutrition;
  }
}
