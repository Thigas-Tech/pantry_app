import 'package:flutter/foundation.dart';

/// A single entry in the PLU (Price Look-Up) code database.
///
/// Maps a numeric produce code to a human-readable name and category.
/// Nutritional information is not included — it is fetched from the
/// Open Food Facts API at lookup time.
@immutable
class PluEntry {
  /// Creates a [PluEntry].
  const PluEntry({
    required this.code,
    required this.name,
    required this.category,
  });

  /// The PLU code as a string (e.g. `'4011'`, `'94011'`).
  final String code;

  /// The common name of the produce item (e.g. `'Banana'`).
  final String name;

  /// The produce category (e.g. `'Fruits'`, `'Vegetables'`).
  final String category;
}

/// Provides local lookup of PLU (Price Look-Up) codes to produce names.
///
/// PLU codes are 4-5 digit stickers found on fresh produce. This service
/// maps them to human-readable names so the app can search for nutritional
/// data on Open Food Facts.
///
/// The database covers the most common ~100 produce items. Organic variants
/// use 5-digit codes prefixed with `'9'` (e.g. `'94011'` for Organic Banana
/// vs `'4011'` for conventional Banana).
///
/// [lookup] resolves a PLU code to a [PluEntry]. [search] does a fuzzy
/// match by name or category. All lookups are synchronous — the data is
/// embedded in the code and requires no I/O.
class PluService {
  /// Creates a [PluService].
  const PluService();

  /// The complete PLU→name mapping.
  ///
  /// Each key is a PLU code (4 or 5 digits as string). Values are
  /// the common name and category of the produce item.
  static const _pluMap = <String, PluEntry>{
    // Fruits
    '4011': PluEntry(code: '4011', name: 'Banana', category: 'Fruits'),
    '94011': PluEntry(
      code: '94011',
      name: 'Organic Banana',
      category: 'Fruits',
    ),
    '4032': PluEntry(code: '4032', name: 'Apple', category: 'Fruits'),
    '94032': PluEntry(
      code: '94032',
      name: 'Organic Apple',
      category: 'Fruits',
    ),
    '4012': PluEntry(code: '4012', name: 'Orange', category: 'Fruits'),
    '94012': PluEntry(
      code: '94012',
      name: 'Organic Orange',
      category: 'Fruits',
    ),
    '4022': PluEntry(code: '4022', name: 'Grapes', category: 'Fruits'),
    '4036': PluEntry(code: '4036', name: 'Lemon', category: 'Fruits'),
    '94036': PluEntry(
      code: '94036',
      name: 'Organic Lemon',
      category: 'Fruits',
    ),
    '4034': PluEntry(code: '4034', name: 'Pear', category: 'Fruits'),
    '4042': PluEntry(code: '4042', name: 'Peach', category: 'Fruits'),
    '4044': PluEntry(code: '4044', name: 'Plum', category: 'Fruits'),
    '4046': PluEntry(code: '4046', name: 'Mango', category: 'Fruits'),
    '4050': PluEntry(code: '4050', name: 'Pineapple', category: 'Fruits'),
    '4066': PluEntry(code: '4066', name: 'Strawberry', category: 'Fruits'),
    '4088': PluEntry(code: '4088', name: 'Blueberry', category: 'Fruits'),
    '4090': PluEntry(code: '4090', name: 'Raspberry', category: 'Fruits'),
    '4315': PluEntry(code: '4315', name: 'Watermelon', category: 'Fruits'),
    '4119': PluEntry(code: '4119', name: 'Cantaloupe', category: 'Fruits'),
    '4174': PluEntry(code: '4174', name: 'Avocado', category: 'Fruits'),
    '94229': PluEntry(
      code: '94229',
      name: 'Organic Avocado',
      category: 'Fruits',
    ),
    '4197': PluEntry(code: '4197', name: 'Cherry', category: 'Fruits'),
    '4427': PluEntry(code: '4427', name: 'Lime', category: 'Fruits'),
    '94427': PluEntry(
      code: '94427',
      name: 'Organic Lime',
      category: 'Fruits',
    ),
    '4274': PluEntry(code: '4274', name: 'Kiwi', category: 'Fruits'),
    '94274': PluEntry(
      code: '94274',
      name: 'Organic Kiwi',
      category: 'Fruits',
    ),
    '4281': PluEntry(code: '4281', name: 'Pomegranate', category: 'Fruits'),
    '4353': PluEntry(code: '4353', name: 'Grapefruit', category: 'Fruits'),

    // Vegetables
    '4664': PluEntry(code: '4664', name: 'Tomato', category: 'Vegetables'),
    '94664': PluEntry(
      code: '94664',
      name: 'Organic Tomato',
      category: 'Vegetables',
    ),
    '4065': PluEntry(code: '4065', name: 'Bell Pepper', category: 'Vegetables'),
    '4688': PluEntry(
      code: '4688',
      name: 'Bell Pepper Red',
      category: 'Vegetables',
    ),
    '4070': PluEntry(code: '4070', name: 'Cucumber', category: 'Vegetables'),
    '94070': PluEntry(
      code: '94070',
      name: 'Organic Cucumber',
      category: 'Vegetables',
    ),
    '4082': PluEntry(code: '4082', name: 'Carrot', category: 'Vegetables'),
    '94082': PluEntry(
      code: '94082',
      name: 'Organic Carrot',
      category: 'Vegetables',
    ),
    '4072': PluEntry(code: '4072', name: 'Celery', category: 'Vegetables'),
    '4609': PluEntry(code: '4609', name: 'Broccoli', category: 'Vegetables'),
    '94609': PluEntry(
      code: '94609',
      name: 'Organic Broccoli',
      category: 'Vegetables',
    ),
    '4575': PluEntry(
      code: '4575',
      name: 'Cauliflower',
      category: 'Vegetables',
    ),
    '4103': PluEntry(code: '4103', name: 'Cabbage', category: 'Vegetables'),
    '4607': PluEntry(
      code: '4607',
      name: 'Brussels Sprouts',
      category: 'Vegetables',
    ),
    '4163': PluEntry(code: '4163', name: 'Spinach', category: 'Vegetables'),
    '94163': PluEntry(
      code: '94163',
      name: 'Organic Spinach',
      category: 'Vegetables',
    ),
    '4181': PluEntry(code: '4181', name: 'Lettuce', category: 'Vegetables'),
    '4127': PluEntry(
      code: '4127',
      name: 'Romaine Lettuce',
      category: 'Vegetables',
    ),
    '4101': PluEntry(code: '4101', name: 'Kale', category: 'Vegetables'),
    '94101': PluEntry(
      code: '94101',
      name: 'Organic Kale',
      category: 'Vegetables',
    ),
    '4141': PluEntry(code: '4141', name: 'Zucchini', category: 'Vegetables'),
    '4191': PluEntry(
      code: '4191',
      name: 'Eggplant',
      category: 'Vegetables',
    ),
    '4081': PluEntry(code: '4081', name: 'Onion', category: 'Vegetables'),
    '4165': PluEntry(code: '4165', name: 'Garlic', category: 'Vegetables'),
    '94081': PluEntry(
      code: '94081',
      name: 'Organic Onion',
      category: 'Vegetables',
    ),
    '4087': PluEntry(
      code: '4087',
      name: 'Sweet Potato',
      category: 'Vegetables',
    ),
    '4812': PluEntry(code: '4812', name: 'Asparagus', category: 'Vegetables'),
    '4821': PluEntry(
      code: '4821',
      name: 'Green Beans',
      category: 'Vegetables',
    ),
    '4936': PluEntry(code: '4936', name: 'Mushroom', category: 'Vegetables'),
    '4608': PluEntry(code: '4608', name: 'Corn', category: 'Vegetables'),
    '4091': PluEntry(code: '4091', name: 'Potato', category: 'Vegetables'),
    '94091': PluEntry(
      code: '94091',
      name: 'Organic Potato',
      category: 'Vegetables',
    ),
    '4124': PluEntry(code: '4124', name: 'Ginger', category: 'Vegetables'),
  };

  /// Looks up a PLU code and returns the corresponding [PluEntry].
  ///
  /// The [code] may include leading zeros or whitespace — it is trimmed and
  /// normalized before lookup. Returns `null` for codes not in the database.
  ///
  /// Supports both 4-digit standard PLU codes and 5-digit organic codes
  /// (prefixed with `'9'`).
  PluEntry? lookup(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    // Strip leading zeros for lookup but keep the original code.
    final stripped = trimmed.replaceAll(RegExp('^0+'), '');
    if (stripped.isEmpty) return null;
    return _pluMap[stripped];
  }

  /// Searches the PLU database by name or category.
  ///
  /// The search is case-insensitive and matches against both the produce
  /// name and its category. Returns an empty list when no entries match.
  List<PluEntry> search(String query) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return [];
    return _pluMap.values
        .where(
          (e) =>
              e.name.toLowerCase().contains(lower) ||
              e.category.toLowerCase().contains(lower),
        )
        .toList();
  }

  /// Returns all PLU entries in the database.
  @visibleForTesting
  List<PluEntry> get allEntries => _pluMap.values.toList();
}
