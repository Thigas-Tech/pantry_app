import 'package:pantry_app/models/hemisphere.dart';
import 'package:pantry_app/models/season.dart';

/// Provides seasonal produce suggestions based on hemisphere and date.
///
/// Hardcoded lists of common in-season produce for each meteorological
/// season and hemisphere. Southern hemisphere seasons use the opposite
/// northern hemisphere lists (same climate, opposite calendar).
class SeasonalProduceService {
  SeasonalProduceService._();

  static const _northernSpring = [
    'asparagus',
    'mango',
    'spinach',
    'carrot',
    'lettuce',
    'avocado',
    'broccoli',
    'cucumber',
    'mushroom',
    'onion',
  ];

  static const _northernSummer = [
    'tomato',
    'corn',
    'peach',
    'zucchini',
    'eggplant',
    'broccoli',
    'carrot',
    'lettuce',
    'celery',
    'cucumber',
    'onion',
    'garlic',
  ];

  static const _northernAutumn = [
    'potato',
    'mushroom',
    'cauliflower',
    'pear',
    'cabbage',
    'kale',
    'garlic',
    'ginger',
    'onion',
    'broccoli',
    'carrot',
    'celery',
  ];

  static const _northernWinter = [
    'orange',
    'grapefruit',
    'lemon',
    'lime',
    'kiwi',
    'kale',
    'cabbage',
    'carrot',
    'potato',
    'onion',
    'ginger',
    'garlic',
  ];

  static const _seasonMap = <Hemisphere, Map<Season, List<String>>>{
    Hemisphere.northern: {
      Season.spring: _northernSpring,
      Season.summer: _northernSummer,
      Season.autumn: _northernAutumn,
      Season.winter: _northernWinter,
    },
    Hemisphere.southern: {
      Season.spring: _northernAutumn,
      Season.summer: _northernWinter,
      Season.autumn: _northernSpring,
      Season.winter: _northernSummer,
    },
  };

  /// Returns a list of produce names that are in season for the given
  /// [date] and [hemisphere].
  ///
  /// Names in [excludeNames] are filtered out (case-insensitive match).
  /// Results are sorted alphabetically.
  static List<String> getSeasonalProduce(
    DateTime date,
    Hemisphere hemisphere, {
    Set<String>? excludeNames,
  }) {
    final season = Season.current(date, hemisphere);
    final list = _seasonMap[hemisphere]?[season] ?? _northernSummer;
    final exclude = excludeNames?.map((n) => n.toLowerCase()).toSet() ?? {};

    return list.where((item) => !exclude.contains(item.toLowerCase())).toList()
      ..sort();
  }
}
