import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/off_units.dart';

/// Context in which a unit system is used.
enum UnitContext {
  /// Serving sizes shown on product details.
  servingSize,

  /// Ingredient quantities in recipe forms.
  recipeIngredients,

  /// Inventory item quantities.
  inventory,
}

/// Stateless helper that resolves the effective [UnitSystem] for a given
/// [UnitContext] from [Settings], accounting for per-context overrides.
///
/// Also provides unit lists and utility checks for metric/imperial units.
class UnitResolver {
  /// Prevents instantiation of this static helper.
  UnitResolver._();

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
      return OffUnitCatalog.quantityUnits;
    }
    return OffUnitCatalog.imperialUnits;
  }

  /// Whether [unit] is a metric unit (or neutral like "pieces").
  ///
  /// Returns true for metric/neutral units, false for imperial units.
  static bool isMetricUnit(String unit) {
    switch (unit) {
      case 'pieces':
      case 'g':
      case 'kg':
      case 'mg':
      case 'mcg':
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
