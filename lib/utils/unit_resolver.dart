import 'package:pantry_app/providers/settings_provider.dart';

/// Context in which a unit system is used.
enum UnitContext { servingSize, recipeIngredients, inventory }

/// Stateless helper that resolves the effective [UnitSystem] for a given
/// [UnitContext] from [Settings], accounting for per-context overrides.
///
/// Also provides unit lists and utility checks for metric/imperial units.
abstract final class UnitResolver {
  /// Returns the effective [UnitSystem] for [context] based on [settings].
  ///
  /// If the per-context override is non-null, returns the override.
  /// Otherwise, returns the global [Settings.unitSystem].
  static UnitSystem systemFor({
    required Settings settings,
    required UnitContext context,
  }) {
    final override = switch (context) {
      UnitContext.servingSize => settings.unitSystemServingSize,
      UnitContext.recipeIngredients => settings.unitSystemRecipeIngredients,
      UnitContext.inventory => settings.unitSystemInventory,
    };
    return override ?? settings.unitSystem;
  }

  /// Returns the list of available units for [system].
  static List<String> unitsForSystem(UnitSystem system) {
    if (system == UnitSystem.metric) {
      return ['pieces', 'g', 'kg', 'ml', 'L'];
    }
    return ['pieces', 'oz', 'lb', 'fl oz', 'cup', 'tbsp', 'tsp'];
  }

  /// Whether [unit] is a metric unit (or neutral like "pieces").
  ///
  /// Returns true for metric/neutral units, false for imperial units.
  static bool isMetricUnit(String unit) {
    switch (unit) {
      case 'pieces':
      case 'g':
      case 'kg':
      case 'ml':
      case 'L':
        return true;
      case 'oz':
      case 'lb':
      case 'fl oz':
      case 'cup':
      case 'tbsp':
      case 'tsp':
        return false;
      default:
        return true;
    }
  }
}
