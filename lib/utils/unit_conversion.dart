import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/off_units.dart';

/// Normalizes and converts between compatible measurement units.
///
/// Supported unit groups:
///   - weight: g, kg, mg, mcg, oz, lb
///   - volume: ml, L, tbsp, tsp, cup, fl oz
///   - count: pieces
class UnitConverter {
  UnitConverter._();

  static const _weightUnits = {'g', 'kg', 'mg', 'mcg', 'oz', 'lb'};
  static const _volumeUnits = {'ml', 'L', 'tbsp', 'tsp', 'cup', 'fl oz'};

  static const _ozToG = 28.3495;
  static const _lbToG = 453.592;
  static const _flOzToMl = 29.5735;

  static const _toMl = <String, double>{
    'ml': 1,
    'L': 1000,
    'tbsp': 15,
    'tsp': 5,
    'cup': 240,
    'fl oz': 29.5735,
  };

  /// Normalizes [quantity] in [unit] to grams.
  static double normalizeToGrams(double quantity, String unit) {
    if (unit == 'kg') return quantity * 1000;
    if (unit == 'g') return quantity;
    if (unit == 'mg') return quantity / 1000;
    if (unit == 'mcg') return quantity / 1e6;
    if (unit == 'oz') return quantity * _ozToG;
    if (unit == 'lb') return quantity * _lbToG;
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
    if (targetUnit == 'mg') return normalizedQty * 1000;
    if (targetUnit == 'mcg') return normalizedQty * 1e6;
    if (targetUnit == 'oz') return normalizedQty / _ozToG;
    if (targetUnit == 'lb') return normalizedQty / _lbToG;
    if (targetUnit == 'fl oz') return normalizedQty / _flOzToMl;
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

  /// Scales [quantity] in [unit] to the most appropriate representation.
  ///
  /// Examples: 1500 g -> (1.5, kg), 32 oz -> (2.0, lb),
  /// 3 pieces -> (3, pieces).
  static ({double quantity, String unit}) autoScale(
    double quantity,
    String unit,
  ) {
    if (quantity == 0 || unit == 'pieces') {
      return (quantity: quantity, unit: unit);
    }

    switch (unit) {
      case 'g':
        if (quantity >= 1000) {
          return (quantity: _round(quantity / 1000, 'kg'), unit: 'kg');
        }
        return (quantity: _round(quantity, 'g'), unit: 'g');
      case 'kg':
        return (quantity: _round(quantity, 'kg'), unit: 'kg');
      case 'ml':
        if (quantity >= 1000) {
          return (quantity: _round(quantity / 1000, 'L'), unit: 'L');
        }
        return (quantity: _round(quantity, 'ml'), unit: 'ml');
      case 'L':
        return (quantity: _round(quantity, 'L'), unit: 'L');
      case 'oz':
        if (quantity >= 16) {
          return (quantity: _round(quantity / 16, 'lb'), unit: 'lb');
        }
        return (quantity: _round(quantity, 'oz'), unit: 'oz');
      case 'lb':
        return (quantity: _round(quantity, 'lb'), unit: 'lb');
      case 'fl oz':
        if (quantity >= 8) {
          return (quantity: _round(quantity / 8, 'cup'), unit: 'cup');
        }
        return (quantity: _round(quantity, 'fl oz'), unit: 'fl oz');
      case 'cup':
      case 'tbsp':
      case 'tsp':
        return (quantity: _round(quantity, unit), unit: unit);
      default:
        return (quantity: _round(quantity, 'g'), unit: unit);
    }
  }

  /// Converts [quantity] in [fromUnit] for display in [targetSystem].
  ///
  /// - Metric system: auto-scales within metric (g -> kg, ml -> L).
  /// - Imperial system: converts to the preferred imperial unit.
  /// - The 'pieces' unit always passes through unchanged.
  /// - Respects [weightPref] and [volumePref] when target is imperial.
  static ({double quantity, String unit}) displayUnit(
    double quantity,
    String fromUnit,
    UnitSystem targetSystem, {
    WeightUnitPreference weightPref = WeightUnitPreference.auto,
    VolumeUnitPreference volumePref = VolumeUnitPreference.auto,
  }) {
    if (fromUnit == 'pieces') return (quantity: quantity, unit: 'pieces');

    final base = baseUnitFor(fromUnit);
    if (base == 'pieces') return (quantity: quantity, unit: fromUnit);

    if (targetSystem == UnitSystem.metric) {
      if (base == 'g') {
        final inGrams = normalizeToGrams(quantity, fromUnit);
        return autoScale(inGrams, 'g');
      }
      final inMl = normalizeToMilliliters(quantity, fromUnit);
      return autoScale(inMl, 'ml');
    }

    // Imperial target
    if (base == 'g') {
      final inGrams = normalizeToGrams(quantity, fromUnit);
      switch (weightPref) {
        case WeightUnitPreference.ounces:
          return (
            quantity: _round(convertBack(inGrams, 'oz'), 'oz'),
            unit: 'oz',
          );
        case WeightUnitPreference.pounds:
          return (
            quantity: _round(convertBack(inGrams, 'lb'), 'lb'),
            unit: 'lb',
          );
        case WeightUnitPreference.auto:
          final oz = convertBack(inGrams, 'oz');
          if (oz >= 16) {
            return (
              quantity: _round(convertBack(inGrams, 'lb'), 'lb'),
              unit: 'lb',
            );
          }
          return (quantity: _round(oz, 'oz'), unit: 'oz');
      }
    }

    // Volume
    final inMl = normalizeToMilliliters(quantity, fromUnit);
    switch (volumePref) {
      case VolumeUnitPreference.fluidOunces:
        return (
          quantity: _round(convertBack(inMl, 'fl oz'), 'fl oz'),
          unit: 'fl oz',
        );
      case VolumeUnitPreference.cups:
        return (
          quantity: _round(convertBack(inMl, 'cup'), 'cup'),
          unit: 'cup',
        );
      case VolumeUnitPreference.tablespoons:
        return (
          quantity: _round(convertBack(inMl, 'tbsp'), 'tbsp'),
          unit: 'tbsp',
        );
      case VolumeUnitPreference.teaspoons:
        return (
          quantity: _round(convertBack(inMl, 'tsp'), 'tsp'),
          unit: 'tsp',
        );
      case VolumeUnitPreference.auto:
        final flOz = convertBack(inMl, 'fl oz');
        if (flOz >= 8) {
          return (
            quantity: _round(convertBack(inMl, 'cup'), 'cup'),
            unit: 'cup',
          );
        }
        if (flOz >= 1) {
          return (quantity: _round(flOz, 'fl oz'), unit: 'fl oz');
        }
        final tbsp = convertBack(inMl, 'tbsp');
        if (tbsp >= 1) {
          return (quantity: _round(tbsp, 'tbsp'), unit: 'tbsp');
        }
        final tsp = convertBack(inMl, 'tsp');
        return (quantity: _round(tsp, 'tsp'), unit: 'tsp');
    }
  }

  /// Returns the list of available units for the given [system].
  ///
  /// Delegates to [OffUnitCatalog] so this list stays in sync with the one
  /// used by the unit resolver.
  static List<String> allUnitsForSystem(UnitSystem system) {
    if (system == UnitSystem.metric) {
      return OffUnitCatalog.quantityUnits;
    }
    return OffUnitCatalog.imperialUnits;
  }

  /// Rounds [value] to a reasonable precision for [unit].
  ///
  /// - lb, cup: whole numbers
  /// - oz, fl oz: 1 decimal
  /// - metric: 1 decimal when < 10, whole when >= 10
  static double _round(double value, String unit) {
    switch (unit) {
      case 'lb':
      case 'cup':
        return value.roundToDouble();
      case 'oz':
      case 'fl oz':
        return (value * 10).roundToDouble() / 10;
      default:
        if (value >= 10) return value.roundToDouble();
        return (value * 10).roundToDouble() / 10;
    }
  }
}
