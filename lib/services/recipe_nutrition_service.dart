import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/recipe_nutrition.dart';
import 'package:pantry_app/utils/density_table.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/serving_weight.dart';

/// Converts ingredient quantities to grams.
///
/// Weight units map directly. Volume units (ml, L, tbsp, tsp, cup) use the
/// ingredient's density from [DensityTable], defaulting to 1.0 g/ml
/// (water-like) for unknown ingredients. Piece-based ingredients convert
/// with [perPieceWeightG] when known; otherwise they return 0 and are
/// skipped by the caller.
double _convertToGrams(
  double quantity,
  String unit, {
  double? perPieceWeightG,
  String ingredientName = '',
}) {
  final density = DensityTable.gramsPerMilliliter(ingredientName);
  switch (unit) {
    case 'g':
      return quantity;
    case 'kg':
      return quantity * 1000;
    case 'ml':
      return quantity * density;
    case 'L':
      return quantity * 1000 * density;
    case 'tbsp':
      return quantity * 15 * density;
    case 'tsp':
      return quantity * 5 * density;
    case 'cup':
      return quantity * 240 * density;
    case 'pieces':
      return perPieceWeightG != null ? quantity * perPieceWeightG : 0;
    default:
      return 0;
  }
}

/// Aggregates nutrition data from a list of [RecipeIngredient]s and their
/// corresponding [Product] data.
///
/// Ingredients without a barcode or whose product is not in the products map
/// are skipped (they contribute zero nutrients). Piece-based ingredients are
/// converted using the product's USDA gram weight or the produce serving
/// presets; when neither is known they are skipped.
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

      final perPieceWeightG = ingredient.unit == 'pieces'
          ? _resolvePerPieceWeight(product, ingredient.name)
          : null;
      final grams = _convertToGrams(
        ingredient.quantity,
        ingredient.unit,
        perPieceWeightG: perPieceWeightG,
        ingredientName: ingredient.name,
      );
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

  /// Resolves the grams per piece for [name], preferring the product's USDA
  /// gram weight.
  ///
  /// The produce serving presets are only consulted for produce-type
  /// products so a barcoded item like "Egg" is never matched against a
  /// loose preset key (e.g. "eggplant").
  double? _resolvePerPieceWeight(Product product, String name) {
    final usda = product.usdaGramWeight;
    if (usda != null && usda > 0) return usda;
    if (product.productType != ProductType.produce) return null;
    return ServingWeightResolver.resolve(produceName: name);
  }
}
