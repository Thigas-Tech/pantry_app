/// Maps produce names to category strings compatible with OFF category
/// localization in [AppLocalizationsX.localizeCategory].
///
/// Uses the same matching strategy as [ProduceServingPresets.forName]:
/// exact match, strip "organic" prefix, then substring match.
class ProduceCategoryMapper {
  ProduceCategoryMapper._();

  static const _fruits = {
    'apple',
    'banana',
    'orange',
    'pear',
    'peach',
    'plum',
    'mango',
    'kiwi',
    'grapefruit',
    'lemon',
    'lime',
    'grapes',
    'grape',
    'strawberry',
    'blueberry',
    'raspberry',
    'blackberry',
    'cranberry',
    'cherry',
    'apricot',
    'nectarine',
    'fig',
    'date',
    'pomegranate',
    'cantaloupe',
    'watermelon',
    'melon',
    'pineapple',
    'avocado',
    'coconut',
    'plantain',
    'tangerine',
    'clementine',
    'mandarin',
    'persimmon',
    'rhubarb',
    'breadfruit',
    'passion fruit',
    'guava',
    'papaya',
    'lychee',
    'dragon fruit',
    'star fruit',
  };

  static const _vegetables = {
    'tomato',
    'potato',
    'carrot',
    'broccoli',
    'cauliflower',
    'zucchini',
    'eggplant',
    'aubergine',
    'sweet potato',
    'yam',
    'cucumber',
    'bell pepper',
    'capsicum',
    'onion',
    'garlic',
    'ginger',
    'lettuce',
    'spinach',
    'kale',
    'cabbage',
    'celery',
    'asparagus',
    'green beans',
    'string beans',
    'mushroom',
    'corn',
    'maize',
    'radish',
    'beet',
    'beetroot',
    'squash',
    'pumpkin',
    'turnip',
    'parsnip',
    'okra',
    'artichoke',
    'leek',
    'scallion',
    'shallot',
    'fennel',
    'watercress',
    'arugula',
    'rocket',
    'endive',
    'chicory',
    'brussels sprout',
    'kohlrabi',
    'rutabaga',
    'jicama',
    'taro',
    'cassava',
    'manioc',
    'pea',
    'peas',
    'snow pea',
    'sugar snap pea',
  };

  static const _nuts = {
    'almond',
    'walnut',
    'peanut',
    'cashew',
    'pecan',
    'macadamia',
    'hazelnut',
    'filbert',
    'pistachio',
    'chestnut',
    'brazil nut',
    'pine nut',
    'pinenut',
  };

  static const _herbs = {
    'basil',
    'cilantro',
    'coriander',
    'parsley',
    'mint',
    'rosemary',
    'thyme',
    'oregano',
    'dill',
    'sage',
    'chives',
    'tarragon',
    'bay leaf',
    'bay leaves',
    'marjoram',
    'turmeric',
    'saffron',
    'vanilla bean',
    'lemongrass',
    'lavender',
  };

  static const _legumes = {
    'chickpea',
    'garbanzo',
    'lentil',
    'black bean',
    'kidney bean',
    'pinto bean',
    'navy bean',
    'soybean',
    'edamame',
    'fava bean',
    'broad bean',
    'mung bean',
    'adzuki bean',
    'lupin',
    'chickpeas',
    'lentils',
    'beans',
  };

  static Map<String, String> get _allKeys => _buildAllKeys();

  static Map<String, String> _buildAllKeys() {
    final map = <String, String>{};
    for (final k in _fruits) map[k] = 'Fruit';
    for (final k in _vegetables) map[k] = 'Vegetables';
    for (final k in _nuts) map[k] = 'Nuts and their products';
    for (final k in _herbs) map[k] = 'Spices and herbs';
    for (final k in _legumes) map[k] = 'Legumes and their products';
    return map;
  }

  /// Maps [produceName] to an OFF-compatible category string.
  ///
  /// Matching strategy (same as [ProduceServingPresets.forName]):
  /// 1. Exact match (case-insensitive)
  /// 2. Strip "organic " prefix and retry
  /// 3. Substring match
  ///
  /// Returns the fallback `'Fruits and vegetables based foods'` when no
  /// match is found. Returns `null` for empty names.
  static String? forName(String produceName) {
    final lower = produceName.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // Exact match.
    if (_allKeys.containsKey(lower)) return _allKeys[lower];

    // Strip "Organic" prefix.
    final noOrganic = lower.replaceFirst('organic ', '').trim();
    if (_allKeys.containsKey(noOrganic)) return _allKeys[noOrganic];

    // Substring match.
    for (final entry in _allKeys.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    return 'Fruits and vegetables based foods';
  }
}
