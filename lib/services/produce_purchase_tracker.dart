import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how often each produce item is purchased.
///
/// Stores frequency counts in [SharedPreferences] as a JSON-encoded map.
/// Used by the quick-add carousel to show the user's most frequent produce.
class ProducePurchaseTracker {
  /// Creates a [ProducePurchaseTracker].
  ///
  /// [prefs] can be injected for testing. When omitted, the default
  /// [SharedPreferences] instance is used.
  ProducePurchaseTracker({SharedPreferences? prefs})
    : _prefs = prefs != null
          ? Future<SharedPreferences>.value(prefs)
          : SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;

  static const _key = 'produce_purchase_frequency';

  /// Default produce list shown when the user has no purchase history.
  static List<String> getDefaultList() => const [
    'Apple',
    'Banana',
    'Orange',
    'Tomato',
    'Potato',
    'Carrot',
    'Onion',
    'Lettuce',
  ];

  /// Records a purchase of [produceName].
  Future<void> recordPurchase(String produceName) async {
    final prefs = await _prefs;
    final map = await _load();
    final key = produceName.toLowerCase().trim();
    map[key] = (map[key] ?? 0) + 1;
    await prefs.setString(_key, jsonEncode(map));
  }

  /// Returns the top [limit] most frequently purchased produce items.
  Future<List<String>> getTopPurchases({int limit = 8}) async {
    final map = await _load();
    if (map.isEmpty) return getDefaultList().take(limit).toList();

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = sorted
        .map((e) {
          // Capitalize first letter for display.
          final name = e.key;
          return name[0].toUpperCase() + name.substring(1);
        })
        .take(limit)
        .toList();

    // Pad with defaults if we don't have enough history.
    if (result.length < limit) {
      for (final d in getDefaultList()) {
        if (result.length >= limit) break;
        if (!result.any((r) => r.toLowerCase() == d.toLowerCase())) {
          result.add(d);
        }
      }
    }

    return result;
  }

  Future<Map<String, int>> _load() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } on Exception {
      return {};
    }
  }
}
