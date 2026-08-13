import 'package:pantry_app/services/produce_serving_presets.dart';

/// Resolves a per-piece serving weight in grams for produce-style items.
///
/// This is the single source of truth for converting between piece counts and
/// gram weights so the shortage check, the cook transaction, and recipe cost
/// scaling all agree. Sources are consulted in order:
///
///   1. The inventory row's stored `serving_weight_g` (persisted when the
///      user adds a produce item in unit mode).
///   2. [ProduceServingPresets], keyed by the produce name.
///
/// Returns null when neither source knows the weight.
class ServingWeightResolver {
  /// Prevents instantiation of this static helper.
  ServingWeightResolver._();

  /// Resolves the grams per piece for [produceName].
  ///
  /// [rowServingWeightG] is the optional `serving_weight_g` value from an
  /// inventory row; [produceName] is the ingredient or product display name
  /// used for the preset lookup. Returns null when no weight is available.
  static double? resolve({
    required String produceName,
    double? rowServingWeightG,
  }) {
    if (rowServingWeightG != null && rowServingWeightG > 0) {
      return rowServingWeightG;
    }
    final presets = ProduceServingPresets.forName(produceName);
    return presets?['Medium'] ?? presets?.values.firstOrNull;
  }
}
