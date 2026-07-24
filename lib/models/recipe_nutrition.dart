/// Aggregated nutrition data for a recipe.
///
/// Contains total, per-100g, and (when servings > 0) per-serving nutrient
/// values computed from the recipe's ingredient list.
class RecipeNutrition {
  /// Creates a [RecipeNutrition].
  const RecipeNutrition({
    required this.totalWeightG,
    required this.totalEnergyKcal,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalFiberG,
    required this.totalSaltG,
    this.totalSugarsG = 0,
    this.totalSaturatedFatG = 0,
    this.servings = 0,
  });

  /// Total weight of all ingredients in grams.
  final double totalWeightG;

  /// Total energy in kcal.
  final double totalEnergyKcal;

  /// Total protein in grams.
  final double totalProteinG;

  /// Total carbohydrates in grams.
  final double totalCarbsG;

  /// Total sugars in grams (0 if not available from products).
  final double totalSugarsG;

  /// Total fat in grams.
  final double totalFatG;

  /// Total saturated fat in grams (0 if not available from products).
  final double totalSaturatedFatG;

  /// Total fibre in grams.
  final double totalFiberG;

  /// Total salt in grams.
  final double totalSaltG;

  /// Number of servings (0 = unknown).
  final int servings;

  /// Energy per 100 g.
  double get per100gEnergyKcal =>
      totalWeightG > 0 ? totalEnergyKcal / totalWeightG * 100 : 0;

  /// Protein per 100 g.
  double get per100gProteinG =>
      totalWeightG > 0 ? totalProteinG / totalWeightG * 100 : 0;

  /// Carbohydrates per 100 g.
  double get per100gCarbsG =>
      totalWeightG > 0 ? totalCarbsG / totalWeightG * 100 : 0;

  /// Sugars per 100 g.
  double get per100gSugarsG =>
      totalWeightG > 0 ? totalSugarsG / totalWeightG * 100 : 0;

  /// Fat per 100 g.
  double get per100gFatG =>
      totalWeightG > 0 ? totalFatG / totalWeightG * 100 : 0;

  /// Saturated fat per 100 g.
  double get per100gSaturatedFatG =>
      totalWeightG > 0 ? totalSaturatedFatG / totalWeightG * 100 : 0;

  /// Fibre per 100 g.
  double get per100gFiberG =>
      totalWeightG > 0 ? totalFiberG / totalWeightG * 100 : 0;

  /// Salt per 100 g.
  double get per100gSaltG =>
      totalWeightG > 0 ? totalSaltG / totalWeightG * 100 : 0;

  /// Energy per serving (0 if servings unknown).
  double get perServingEnergyKcal =>
      servings > 0 ? totalEnergyKcal / servings : 0;

  /// Protein per serving (0 if servings unknown).
  double get perServingProteinG => servings > 0 ? totalProteinG / servings : 0;

  /// Carbohydrates per serving (0 if servings unknown).
  double get perServingCarbsG => servings > 0 ? totalCarbsG / servings : 0;

  /// Sugars per serving (0 if servings unknown).
  double get perServingSugarsG => servings > 0 ? totalSugarsG / servings : 0;

  /// Fat per serving (0 if servings unknown).
  double get perServingFatG => servings > 0 ? totalFatG / servings : 0;

  /// Saturated fat per serving (0 if servings unknown).
  double get perServingSaturatedFatG =>
      servings > 0 ? totalSaturatedFatG / servings : 0;

  /// Fibre per serving (0 if servings unknown).
  double get perServingFiberG => servings > 0 ? totalFiberG / servings : 0;

  /// Salt per serving (0 if servings unknown).
  double get perServingSaltG => servings > 0 ? totalSaltG / servings : 0;
}
