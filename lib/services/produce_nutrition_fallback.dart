import 'package:pantry_app/services/produce_serving_presets.dart';

/// Per-100g nutrition values for a produce item.
///
/// All values represent the nutrient amount per 100 grams of the edible
/// portion of the produce. Source: USDA FoodData Central (SR Legacy).
class ProduceNutrition {
  /// Creates a [ProduceNutrition] with per-100g values.
  const ProduceNutrition({
    required this.name,
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
  });

  /// The display name of the produce item (e.g. "Apple").
  final String name;

  /// Energy in kilocalories per 100g.
  final double? energyKcal;

  /// Protein in grams per 100g.
  final double? proteinG;

  /// Carbohydrates in grams per 100g.
  final double? carbsG;

  /// Fat in grams per 100g.
  final double? fatG;

  /// Fiber in grams per 100g.
  final double? fiberG;
}

/// Hardcoded per-100g nutrition data for common produce items.
///
/// Used as a local fallback when the USDA API is unavailable (no API key,
/// network error, or empty response). Data sourced from USDA FoodData
/// Central SR Legacy.
///
/// See also: [ProduceServingPresets] for serving-size-to-gram mappings.
///
/// {@category Fallback}
class ProduceNutritionFallback {
  ProduceNutritionFallback._();

  static const _data = <String, ProduceNutrition>{
    'apple': ProduceNutrition(
      name: 'Apple',
      energyKcal: 52,
      proteinG: 0.3,
      carbsG: 13.8,
      fatG: 0.2,
      fiberG: 2.4,
    ),
    'avocado': ProduceNutrition(
      name: 'Avocado',
      energyKcal: 160,
      proteinG: 2,
      carbsG: 8.5,
      fatG: 14.7,
      fiberG: 6.7,
    ),
    'banana': ProduceNutrition(
      name: 'Banana',
      energyKcal: 89,
      proteinG: 1.1,
      carbsG: 22.8,
      fatG: 0.3,
      fiberG: 2.6,
    ),
    'bell pepper': ProduceNutrition(
      name: 'Bell Pepper',
      energyKcal: 31,
      proteinG: 1,
      carbsG: 6,
      fatG: 0.3,
      fiberG: 2.1,
    ),
    'bell pepper red': ProduceNutrition(
      name: 'Bell Pepper Red',
      energyKcal: 31,
      proteinG: 1,
      carbsG: 6,
      fatG: 0.3,
      fiberG: 2.1,
    ),
    'broccoli': ProduceNutrition(
      name: 'Broccoli',
      energyKcal: 34,
      proteinG: 2.8,
      carbsG: 6.6,
      fatG: 0.4,
      fiberG: 2.6,
    ),
    'cabbage': ProduceNutrition(
      name: 'Cabbage',
      energyKcal: 25,
      proteinG: 1.3,
      carbsG: 5.8,
      fatG: 0.1,
      fiberG: 2.5,
    ),
    'carrot': ProduceNutrition(
      name: 'Carrot',
      energyKcal: 41,
      proteinG: 0.9,
      carbsG: 9.6,
      fatG: 0.2,
      fiberG: 2.8,
    ),
    'cauliflower': ProduceNutrition(
      name: 'Cauliflower',
      energyKcal: 25,
      proteinG: 1.9,
      carbsG: 5,
      fatG: 0.3,
      fiberG: 2,
    ),
    'celery': ProduceNutrition(
      name: 'Celery',
      energyKcal: 16,
      proteinG: 0.7,
      carbsG: 3,
      fatG: 0.2,
      fiberG: 1.6,
    ),
    'corn': ProduceNutrition(
      name: 'Corn',
      energyKcal: 86,
      proteinG: 3.3,
      carbsG: 19,
      fatG: 1.4,
      fiberG: 2.7,
    ),
    'cucumber': ProduceNutrition(
      name: 'Cucumber',
      energyKcal: 15,
      proteinG: 0.7,
      carbsG: 3.6,
      fatG: 0.1,
      fiberG: 0.5,
    ),
    'eggplant': ProduceNutrition(
      name: 'Eggplant',
      energyKcal: 25,
      proteinG: 1,
      carbsG: 5.9,
      fatG: 0.2,
      fiberG: 3,
    ),
    'garlic': ProduceNutrition(
      name: 'Garlic',
      energyKcal: 149,
      proteinG: 6.4,
      carbsG: 33.1,
      fatG: 0.5,
      fiberG: 2.1,
    ),
    'ginger': ProduceNutrition(
      name: 'Ginger',
      energyKcal: 80,
      proteinG: 1.8,
      carbsG: 17.8,
      fatG: 0.8,
      fiberG: 2,
    ),
    'grapefruit': ProduceNutrition(
      name: 'Grapefruit',
      energyKcal: 42,
      proteinG: 0.8,
      carbsG: 10.7,
      fatG: 0.1,
      fiberG: 1.6,
    ),
    'green beans': ProduceNutrition(
      name: 'Green Beans',
      energyKcal: 31,
      proteinG: 1.8,
      carbsG: 7,
      fatG: 0.2,
      fiberG: 2.7,
    ),
    'kale': ProduceNutrition(
      name: 'Kale',
      energyKcal: 49,
      proteinG: 4.3,
      carbsG: 8.8,
      fatG: 0.9,
      fiberG: 3.6,
    ),
    'kiwi': ProduceNutrition(
      name: 'Kiwi',
      energyKcal: 61,
      proteinG: 1.1,
      carbsG: 14.7,
      fatG: 0.5,
      fiberG: 3,
    ),
    'lemon': ProduceNutrition(
      name: 'Lemon',
      energyKcal: 29,
      proteinG: 1.1,
      carbsG: 9.3,
      fatG: 0.3,
      fiberG: 2.8,
    ),
    'lettuce': ProduceNutrition(
      name: 'Lettuce',
      energyKcal: 15,
      proteinG: 1.4,
      carbsG: 2.9,
      fatG: 0.2,
      fiberG: 1.3,
    ),
    'lime': ProduceNutrition(
      name: 'Lime',
      energyKcal: 30,
      proteinG: 0.7,
      carbsG: 10.5,
      fatG: 0.2,
      fiberG: 2.8,
    ),
    'mango': ProduceNutrition(
      name: 'Mango',
      energyKcal: 60,
      proteinG: 0.8,
      carbsG: 15,
      fatG: 0.4,
      fiberG: 1.6,
    ),
    'mushroom': ProduceNutrition(
      name: 'Mushroom',
      energyKcal: 22,
      proteinG: 3.1,
      carbsG: 3.3,
      fatG: 0.3,
      fiberG: 1,
    ),
    'onion': ProduceNutrition(
      name: 'Onion',
      energyKcal: 40,
      proteinG: 1.1,
      carbsG: 9.3,
      fatG: 0.1,
      fiberG: 1.7,
    ),
    'orange': ProduceNutrition(
      name: 'Orange',
      energyKcal: 47,
      proteinG: 0.9,
      carbsG: 11.8,
      fatG: 0.1,
      fiberG: 2.4,
    ),
    'peach': ProduceNutrition(
      name: 'Peach',
      energyKcal: 39,
      proteinG: 0.9,
      carbsG: 9.5,
      fatG: 0.3,
      fiberG: 1.5,
    ),
    'pear': ProduceNutrition(
      name: 'Pear',
      energyKcal: 57,
      proteinG: 0.4,
      carbsG: 15.2,
      fatG: 0.1,
      fiberG: 3.1,
    ),
    'plum': ProduceNutrition(
      name: 'Plum',
      energyKcal: 46,
      proteinG: 0.7,
      carbsG: 11.4,
      fatG: 0.3,
      fiberG: 1.4,
    ),
    'potato': ProduceNutrition(
      name: 'Potato',
      energyKcal: 77,
      proteinG: 2,
      carbsG: 17.5,
      fatG: 0.1,
      fiberG: 2.2,
    ),
    'romaine lettuce': ProduceNutrition(
      name: 'Romaine Lettuce',
      energyKcal: 17,
      proteinG: 1.2,
      carbsG: 3.3,
      fatG: 0.3,
      fiberG: 2.1,
    ),
    'spinach': ProduceNutrition(
      name: 'Spinach',
      energyKcal: 23,
      proteinG: 2.9,
      carbsG: 3.6,
      fatG: 0.4,
      fiberG: 2.2,
    ),
    'sweet potato': ProduceNutrition(
      name: 'Sweet Potato',
      energyKcal: 86,
      proteinG: 1.6,
      carbsG: 20.1,
      fatG: 0.1,
      fiberG: 3,
    ),
    'tomato': ProduceNutrition(
      name: 'Tomato',
      energyKcal: 18,
      proteinG: 0.9,
      carbsG: 3.9,
      fatG: 0.2,
      fiberG: 1.2,
    ),
    'zucchini': ProduceNutrition(
      name: 'Zucchini',
      energyKcal: 17,
      proteinG: 1.2,
      carbsG: 3.1,
      fatG: 0.3,
      fiberG: 1,
    ),
  };

  /// Returns per-100g nutrition data for [name], case-insensitive.
  ///
  /// Matching logic (same as [ProduceServingPresets.forName]):
  /// 1. Exact match on lowercase name.
  /// 2. Strip "organic " prefix and retry.
  /// 3. Substring match against preset keys.
  /// Returns `null` when no match is found.
  static ProduceNutrition? forName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return null;

    if (_data.containsKey(lower)) return _data[lower];

    final noOrganic = lower.replaceFirst('organic ', '').trim();
    if (_data.containsKey(noOrganic)) return _data[noOrganic];

    for (final entry in _data.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    return null;
  }
}
