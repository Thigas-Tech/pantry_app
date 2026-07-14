import 'package:pantry_app/models/hemisphere.dart';

/// The four meteorological seasons.
enum Season {
  /// Spring (northern: Mar-May, southern: Sep-Nov).
  spring,

  /// Summer (northern: Jun-Aug, southern: Dec-Feb).
  summer,

  /// Autumn (northern: Sep-Nov, southern: Mar-May).
  autumn,

  /// Winter (northern: Dec-Feb, southern: Jun-Aug).
  winter;

  /// Returns the current [Season] for the given [date] and [hemisphere].
  ///
  /// Uses meteorological season boundaries (first of month).
  /// [hemisphere] must be [Hemisphere.northern] or [Hemisphere.southern].
  static Season current(DateTime date, Hemisphere hemisphere) {
    final month = date.month;
    if (hemisphere == Hemisphere.southern) {
      return _southernSeason(month);
    }
    return _northernSeason(month);
  }

  static Season _northernSeason(int month) => switch (month) {
    >= 3 && <= 5 => Season.spring,
    >= 6 && <= 8 => Season.summer,
    >= 9 && <= 11 => Season.autumn,
    _ => Season.winter,
  };

  static Season _southernSeason(int month) => switch (month) {
    >= 3 && <= 5 => Season.autumn,
    >= 6 && <= 8 => Season.winter,
    >= 9 && <= 11 => Season.spring,
    _ => Season.summer,
  };
}
