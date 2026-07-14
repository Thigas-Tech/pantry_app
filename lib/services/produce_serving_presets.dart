/// Serving size presets for common produce items.
///
/// Maps produce names to standard serving sizes (Small, Medium, Large) in
/// grams. Used by the weight/unit toggle to provide natural unit options
/// like "1 medium apple (182g)" instead of raw gram input.
///
/// When a produce name has no entry, generic sizes are returned:
/// Small=100g, Medium=150g, Large=200g.
class ProduceServingPresets {
  ProduceServingPresets._();

  /// The preset database, keyed by lowercase produce name.
  static const _presets = <String, Map<String, double>>{
    'apple': {'Small': 149, 'Medium': 182, 'Large': 223},
    'banana': {'Small': 101, 'Medium': 118, 'Large': 136},
    'orange': {'Small': 131, 'Medium': 184, 'Large': 248},
    'tomato': {'Small': 91, 'Medium': 123, 'Large': 182},
    'potato': {'Small': 148, 'Medium': 213, 'Large': 298},
    'avocado': {'Small': 100, 'Medium': 170, 'Large': 250},
    'carrot': {'Small': 50, 'Medium': 72, 'Large': 100},
    'cucumber': {'Small': 150, 'Medium': 250, 'Large': 350},
    'onion': {'Small': 90, 'Medium': 150, 'Large': 220},
    'bell pepper': {'Small': 100, 'Medium': 160, 'Large': 220},
    'bell pepper red': {'Small': 100, 'Medium': 160, 'Large': 220},
    'lemon': {'Small': 50, 'Medium': 85, 'Large': 120},
    'lime': {'Small': 40, 'Medium': 67, 'Large': 100},
    'pear': {'Small': 140, 'Medium': 178, 'Large': 230},
    'peach': {'Small': 130, 'Medium': 175, 'Large': 220},
    'plum': {'Small': 50, 'Medium': 66, 'Large': 85},
    'mango': {'Small': 200, 'Medium': 300, 'Large': 400},
    'kiwi': {'Small': 60, 'Medium': 76, 'Large': 100},
    'grapefruit': {'Small': 230, 'Medium': 300, 'Large': 400},
    'broccoli': {'Small': 200, 'Medium': 300, 'Large': 450},
    'cauliflower': {'Small': 300, 'Medium': 500, 'Large': 700},
    'zucchini': {'Small': 150, 'Medium': 250, 'Large': 350},
    'eggplant': {'Small': 250, 'Medium': 400, 'Large': 550},
    'sweet potato': {'Small': 130, 'Medium': 200, 'Large': 280},
    'garlic': {'Small': 3, 'Medium': 5, 'Large': 8},
    'ginger': {'Small': 10, 'Medium': 25, 'Large': 50},
    'corn': {'Small': 150, 'Medium': 200, 'Large': 275},
    'lettuce': {'Small': 200, 'Medium': 350, 'Large': 500},
    'romaine lettuce': {'Small': 200, 'Medium': 350, 'Large': 500},
    'spinach': {'Small': 85, 'Medium': 142, 'Large': 200},
    'kale': {'Small': 67, 'Medium': 100, 'Large': 150},
    'cabbage': {'Small': 500, 'Medium': 900, 'Large': 1400},
    'celery': {'Small': 200, 'Medium': 350, 'Large': 500},
    'asparagus': {'Small': 100, 'Medium': 200, 'Large': 300},
    'green beans': {'Small': 85, 'Medium': 150, 'Large': 225},
    'mushroom': {'Small': 100, 'Medium': 200, 'Large': 300},
  };

  /// Generic sizes used when a produce name has no entry.
  static const _generic = <String, double>{
    'Small': 100,
    'Medium': 150,
    'Large': 200,
  };

  /// Returns serving sizes for [produceName], case-insensitive.
  ///
  /// First tries exact match, then strips "Organic" prefix if present,
  /// then tries substring match against preset keys. Returns `null` only
  /// if no match is found at all.
  static Map<String, double>? forName(String produceName) {
    final lower = produceName.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // Exact match.
    if (_presets.containsKey(lower)) return _presets[lower];

    // Strip "Organic" prefix.
    final noOrganic = lower.replaceFirst('organic ', '').trim();
    if (_presets.containsKey(noOrganic)) return _presets[noOrganic];

    // Substring match: check if any preset key is contained in the name
    // or the name is contained in a preset key.
    for (final entry in _presets.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Total grams for [size] × [quantity].
  ///
  /// Returns `null` if [produceName] or [size] is not found.
  static double? totalWeight(
    String produceName,
    String size, {
    double quantity = 1,
  }) {
    final sizes = forName(produceName);
    if (sizes == null) return null;
    final weight = sizes[size];
    if (weight == null) return null;
    return weight * quantity;
  }

  /// Total nutrition value for [size] × [quantity].
  ///
  /// [per100g] is the nutrient value per 100g (e.g., 52 kcal).
  /// Returns `null` if [produceName] or [size] is not found.
  static double? nutrition(
    String produceName,
    String size,
    double per100g, {
    double quantity = 1,
  }) {
    final tw = totalWeight(produceName, size, quantity: quantity);
    if (tw == null) return null;
    return tw / 100 * per100g;
  }

  /// Returns the size labels for [produceName].
  ///
  /// Returns the preset sizes if found, otherwise generic labels.
  static List<String> sizeLabels(String produceName) {
    final sizes = forName(produceName);
    return sizes?.keys.toList() ?? _generic.keys.toList();
  }
}
