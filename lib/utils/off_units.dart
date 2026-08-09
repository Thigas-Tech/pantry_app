import 'package:openfoodfacts/openfoodfacts.dart' as off;

/// Central catalog of unit spellings used across the app.
///
/// Provides the single source of truth for the unit lists shown by the
/// inventory, recipe, and serving-size inputs so the unit resolver and the
/// unit converter never drift apart.
class OffUnitCatalog {
  /// Prevents instantiation of this static helper.
  OffUnitCatalog._();

  /// App-side canonical spelling for every member of the Open Food Facts
  /// [off.Unit] enum, normalized from the raw SDK tag where needed.
  ///
  /// The SDK reports 'liter' and 'percent' for the L and PERCENT members,
  /// while the app stores 'L' and '%'. The spelling for the UNKNOWN member
  /// is kept as 'unknown' for symmetry with the SDK.
  static const Map<off.Unit, String> sdkUnitToCanonical = {
    off.Unit.KCAL: 'kcal',
    off.Unit.KJ: 'kj',
    off.Unit.G: 'g',
    off.Unit.MILLI_G: 'mg',
    off.Unit.MICRO_G: 'mcg',
    off.Unit.MILLI_L: 'ml',
    off.Unit.L: 'L',
    off.Unit.PERCENT: '%',
    off.Unit.UNKNOWN: 'unknown',
    off.Unit.G_PER_KG: 'g/kg',
    off.Unit.PERCENT_DV: '% DV',
    off.Unit.IU: 'IU',
  };

  /// OFF-conformant quantity units for the structured serving-size input.
  ///
  /// Contains only the weight and volume members of the SDK enum. App-only
  /// units such as 'kg' and 'pieces', which have no enum member, and the
  /// nutrition-only units (kcal, kj, percent, g/kg, % DV, IU, unknown) are
  /// intentionally excluded so the serving-size input stays aligned with the
  /// Open Food Facts SDK.
  static final List<String> sdkQuantityUnits = ['g', 'mg', 'mcg', 'ml', 'L'];

  /// Metric units offered by the inventory and recipe forms.
  ///
  /// Complements the OFF quantity units with the app-only 'kg' and 'pieces'
  /// units, which have no member in the Open Food Facts [off.Unit] enum.
  static final List<String> quantityUnits = [
    'pieces',
    'g',
    'kg',
    'mg',
    'mcg',
    'ml',
    'L',
  ];

  /// Imperial units offered by the inventory and recipe forms.
  static final List<String> imperialUnits = [
    'pieces',
    'oz',
    'lb',
    'fl oz',
    'cup',
    'tbsp',
    'tsp',
  ];
}
