/// Money math helpers shared by the price, recipe, and stats features.
///
/// Money is stored as [double] across the app (the SQLite `REAL` columns),
/// so every arithmetic result is rounded to the currency's two-decimal-cent
/// convention before being displayed or summed. Rounding is applied per
/// ingredient and again to the final total so that a recipe cost never shows
/// fractional cents and repeated calculations stay deterministic.
class Money {
  /// Prevents instantiation of this static helper.
  Money._();

  /// Rounds [value] to two decimal places using round-half-up semantics.
  ///
  /// A small epsilon compensates for binary floating-point representation
  /// errors (e.g. `9.99 * 2 / 12` evaluates to `1.6649999999999999`, which
  /// would otherwise round down to 1.66 instead of the expected 1.67).
  static double roundToCents(double value) {
    final scaled = value * 100 + 1e-9;
    return scaled.roundToDouble() / 100;
  }
}
