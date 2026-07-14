import 'package:flutter/material.dart';

/// Maps produce names to Material Icons for the quick-add carousel.
///
/// Provides a visual icon for each produce item. Falls back to
/// [Icons.eco] for unrecognized names.
class ProduceIconService {
  ProduceIconService._();

  static const _iconMap = <String, IconData>{
    'apple': Icons.apple,
    'asparagus': Icons.eco,
    'avocado': Icons.eco,
    'banana': Icons.local_dining,
    'broccoli': Icons.eco,
    'cabbage': Icons.eco,
    'carrot': Icons.eco,
    'cauliflower': Icons.eco,
    'celery': Icons.eco,
    'corn': Icons.grain,
    'cucumber': Icons.eco,
    'eggplant': Icons.eco,
    'garlic': Icons.eco,
    'ginger': Icons.eco,
    'grapefruit': Icons.eco,
    'kale': Icons.eco,
    'kiwi': Icons.eco,
    'lemon': Icons.eco,
    'lettuce': Icons.eco,
    'lime': Icons.eco,
    'mango': Icons.eco,
    'mushroom': Icons.eco,
    'onion': Icons.circle,
    'orange': Icons.circle,
    'peach': Icons.eco,
    'pear': Icons.eco,
    'plum': Icons.eco,
    'potato': Icons.egg,
    'spinach': Icons.eco,
    'tomato': Icons.eco,
    'zucchini': Icons.eco,
  };

  /// Returns the Material [IconData] for [produceName].
  ///
  /// Lookup is case-insensitive and whitespace-trimmed. Returns
  /// [Icons.eco] (a generic leaf icon) for unrecognized names.
  static IconData forName(String produceName) {
    final key = produceName.toLowerCase().trim();
    return _iconMap[key] ?? Icons.eco;
  }
}
