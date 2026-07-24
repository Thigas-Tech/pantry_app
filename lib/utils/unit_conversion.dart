import 'package:pantry_app/utils/logger.dart';

/// Normalizes and converts between compatible measurement units.
///
/// Supported unit groups:
///   - weight: g, kg
///   - volume: ml, L, tbsp, tsp, cup
///   - count: pieces
class UnitConverter {
  UnitConverter._();

  static const _weightUnits = {'g', 'kg'};
  static const _volumeUnits = {'ml', 'L', 'tbsp', 'tsp', 'cup'};

  static const _toMl = <String, double>{
    'ml': 1,
    'L': 1000,
    'tbsp': 15,
    'tsp': 5,
    'cup': 240,
  };

  /// Normalizes [quantity] in [unit] to grams.
  static double normalizeToGrams(double quantity, String unit) {
    if (unit == 'kg') return quantity * 1000;
    if (unit == 'g') return quantity;
    logWarning('normalizeToGrams: unsupported unit $unit, returning 0');
    return 0;
  }

  /// Normalizes [quantity] in [unit] to milliliters.
  static double normalizeToMilliliters(double quantity, String unit) {
    final factor = _toMl[unit];
    if (factor != null) return quantity * factor;
    logWarning('normalizeToMilliliters: unsupported unit $unit, returning 0');
    return 0;
  }

  /// Returns the base unit for the group of [unit].
  static String baseUnitFor(String unit) {
    if (_weightUnits.contains(unit)) return 'g';
    if (_volumeUnits.contains(unit)) return 'ml';
    return 'pieces';
  }

  /// Converts a normalized quantity (grams or ml) back to [targetUnit].
  static double convertBack(double normalizedQty, String targetUnit) {
    if (targetUnit == 'g' || targetUnit == 'ml' || targetUnit == 'pieces') {
      return normalizedQty;
    }
    if (targetUnit == 'kg') return normalizedQty / 1000;
    if (targetUnit == 'L') return normalizedQty / 1000;
    final factor = _toMl[targetUnit];
    if (factor != null && factor > 0) return normalizedQty / factor;
    return normalizedQty;
  }

  /// Whether two units belong to the same measurement group.
  static bool areUnitsCompatible(String unitA, String unitB) {
    if (unitA == unitB) return true;
    if (_weightUnits.contains(unitA) && _weightUnits.contains(unitB)) {
      return true;
    }
    if (_volumeUnits.contains(unitA) && _volumeUnits.contains(unitB)) {
      return true;
    }
    return false;
  }

  /// Converts [quantity] from [fromUnit] to [toUnit] directly.
  ///
  /// Returns the original [quantity] if units are identical or incompatible
  /// (with a warning log).
  static double convert(double quantity, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return quantity;
    if (!areUnitsCompatible(fromUnit, toUnit)) {
      logWarning('Incompatible units: $fromUnit -> $toUnit');
      return quantity;
    }
    final base = baseUnitFor(fromUnit);
    if (base == 'g') {
      final inGrams = normalizeToGrams(quantity, fromUnit);
      return convertBack(inGrams, toUnit);
    }
    if (base == 'ml') {
      final inMl = normalizeToMilliliters(quantity, fromUnit);
      return convertBack(inMl, toUnit);
    }
    return quantity;
  }
}
