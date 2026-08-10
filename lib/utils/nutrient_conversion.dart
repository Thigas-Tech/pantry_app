import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/utils/off_units.dart';

/// Converts nutrient values between the unit spellings offered by the
/// nutrition editor ([OffUnitCatalog.nutrientWeightUnits],
/// [OffUnitCatalog.energyUnits], [OffUnitCatalog.percentUnits]).
///
/// Open Food Facts stores weight nutrients per 100 g in grams, so a value
/// entered in mg must be divided by 1000 before submission, while a value
/// imported from the API (always grams) is converted to the nutrient's
/// human-friendly unit (e.g. vitamin C in mg) for display.
class NutrientConverter {
  /// Prevents instantiation of this static helper.
  NutrientConverter._();

  /// Converts [value] expressed in [fromUnit] into [toUnit].
  ///
  /// Weight conversions between g/mg/mcg are exact multiples. Energy
  /// conversions between kcal and kJ use the Open Food Facts factor 4.1868.
  /// Any unit outside the weight or energy sets (such as the percent unit,
  /// which needs no conversion) returns [value] unchanged.
  static double convert(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    final inGrams = switch (fromUnit) {
      'mg' => value / 1000,
      'mcg' => value / 1000000,
      'g' => value,
      _ => double.nan,
    };
    if (!inGrams.isNaN) {
      return switch (toUnit) {
        'mg' => inGrams * 1000,
        'mcg' => inGrams * 1000000,
        'g' => inGrams,
        _ => value,
      };
    }

    if (fromUnit == 'kcal' && toUnit == 'kj') {
      return off.NutrimentsHelper.fromKCalToKJ(value);
    }
    if (fromUnit == 'kj' && toUnit == 'kcal') {
      return off.NutrimentsHelper.fromKJtoKCal(value);
    }
    return value;
  }
}
