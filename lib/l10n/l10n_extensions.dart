import 'package:pantry_app/l10n/app_localizations.dart';

/// Extension on [AppLocalizations] providing convenience methods for
/// formatting quantities, localizing units, locations, inventory names,
/// and theme modes.
extension AppLocalizationsX on AppLocalizations {
  /// Formats a quantity with a localized unit (e.g., "5 kg").
  String formatQuantityUnit(double? quantity, String? unit) {
    if (quantity == null || unit == null) return '';
    return '${quantity.toInt()} ${localizeUnit(unit)}';
  }

  /// Returns the localized string for a unit code.
  String localizeUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'pieces':
        return unitPieces;
      case 'g':
      case 'grams':
        return unitGrams;
      case 'kg':
      case 'kgs':
        return unitKg;
      case 'ml':
        return unitMl;
      case 'l':
      case 'liter':
      case 'liters':
        return unitLiter;
      default:
        return unit;
    }
  }

  /// Returns the localized string for a location code.
  String localizeLocation(String location) {
    switch (location.toLowerCase()) {
      case 'pantry':
        return locationPantry;
      case 'fridge':
      case 'refrigerator':
        return locationFridge;
      case 'freezer':
        return locationFreezer;
      default:
        return location;
    }
  }

  /// Returns the display name for an inventory, localizing the default names.
  String displayInventoryName(String name) {
    if (name == 'Home' || name == 'Casa') {
      return defaultInventoryName;
    }
    return name;
  }

  /// Returns the localized name for a theme mode name.
  String localizeThemeMode(String modeName) {
    switch (modeName) {
      case 'system':
        return themeModeSystem;
      case 'light':
        return themeModeLight;
      case 'dark':
        return themeModeDark;
      default:
        return modeName;
    }
  }
}
