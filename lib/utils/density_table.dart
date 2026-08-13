/// Densities for converting volume ingredient amounts to grams.
///
/// Nutrition is stored per 100 g, so volume-based recipe ingredients must be
/// converted to grams before aggregation. Assumes water-like density
/// (1.0 g/ml) for ingredients without a known entry, which is a reasonable
/// default for most liquids; entries here cover common ingredients whose
/// density differs meaningfully from water (oil, flour, sugar, honey, ...).
class DensityTable {
  /// Prevents instantiation of this static helper.
  DensityTable._();

  static const Map<String, double> _densitiesGPerMl = {
    'olive oil': 0.91,
    'oil': 0.92,
    'honey': 1.42,
    'syrup': 1.32,
    'flour': 0.59,
    'sugar': 0.85,
    'salt': 1.22,
    'butter': 0.92,
    'margarine': 0.92,
    'peanut butter': 1.09,
    'soy sauce': 1.2,
    'vinegar': 1.01,
    'cream': 1.01,
    'yogurt': 1.03,
  };

  /// Returns the grams per milliliter for [ingredientName].
  ///
  /// The name is matched case-insensitively by whole words so longer
  /// ingredient strings like "unsalted butter" resolve correctly without
  /// false positives ("salt" inside "unsalted"). Returns 1.0 (water-like)
  /// when no entry matches.
  static double gramsPerMilliliter(String ingredientName) {
    final lower = ingredientName.toLowerCase().trim();
    final words = lower.split(RegExp('[^a-z0-9]+'));
    for (final entry in _densitiesGPerMl.entries) {
      final keyWords = entry.key.split(' ');
      if (keyWords.every(words.contains)) return entry.value;
    }
    return 1;
  }
}
