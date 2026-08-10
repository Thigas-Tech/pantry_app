import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/utils/off_units.dart';

/// Curated catalog of Open Food Facts nutrients supported by the app.
///
/// The six core nutrients (energy, protein, carbohydrates, fat, fiber, salt)
/// are first-class fields on the product model and are handled by the
/// dedicated core editor rows. Everything else a user can add to the manual
/// nutrition editor — and everything imported from Open Food Facts into the
/// product additional-nutrients list — comes from [nutrients].
///
/// ## Selection rules
///
/// The curated set deliberately excludes:
/// - the six core nutrients, which have dedicated editor rows;
/// - pet-food-only nutrients (`probablyPetFood`, e.g. crude protein);
/// - read-only or computed tags (nutrition-score-fr/uk, carbon-footprint,
///   glycemic-index, water-hardness, acidity, ph, energy-from-fat);
/// - nutrients whose typical unit has no editor representation.
///
/// Keeping the set bounded means the API import filter and the merge logic
/// only ever deal with known tags, so the stored data stays consistent.
class NutrientCatalog {
  /// Prevents instantiation of this static helper.
  NutrientCatalog._();

  /// The six core nutrients that are first-class product fields.
  static const Set<off.Nutrient> coreNutrients = {
    off.Nutrient.energyKCal,
    off.Nutrient.proteins,
    off.Nutrient.carbohydrates,
    off.Nutrient.fat,
    off.Nutrient.fiber,
    off.Nutrient.salt,
  };

  /// The curated, ordered list of additional nutrients offered by the
  /// editor and imported from Open Food Facts.
  ///
  /// Ordered for display: fats, carbohydrates, minerals, vitamins, then
  /// specialty and percent nutrients.
  static const List<off.Nutrient> nutrients = [
    off.Nutrient.saturatedFat,
    off.Nutrient.monounsaturatedFat,
    off.Nutrient.polyunsaturatedFat,
    off.Nutrient.transFat,
    off.Nutrient.cholesterol,
    off.Nutrient.omega3,
    off.Nutrient.omega6,
    off.Nutrient.sugars,
    off.Nutrient.addedSugars,
    off.Nutrient.starch,
    off.Nutrient.sugarAlcohol,
    off.Nutrient.solubleFiber,
    off.Nutrient.insolubleFiber,
    off.Nutrient.sodium,
    off.Nutrient.potassium,
    off.Nutrient.calcium,
    off.Nutrient.iron,
    off.Nutrient.magnesium,
    off.Nutrient.phosphorus,
    off.Nutrient.zinc,
    off.Nutrient.copper,
    off.Nutrient.manganese,
    off.Nutrient.selenium,
    off.Nutrient.chromium,
    off.Nutrient.molybdenum,
    off.Nutrient.fluoride,
    off.Nutrient.iodine,
    off.Nutrient.chloride,
    off.Nutrient.vitaminA,
    off.Nutrient.vitaminC,
    off.Nutrient.vitaminD,
    off.Nutrient.vitaminE,
    off.Nutrient.vitaminK,
    off.Nutrient.vitaminB1,
    off.Nutrient.vitaminB2,
    off.Nutrient.vitaminPP,
    off.Nutrient.vitaminB6,
    off.Nutrient.vitaminB9,
    off.Nutrient.vitaminB12,
    off.Nutrient.biotin,
    off.Nutrient.pantothenicAcid,
    off.Nutrient.choline,
    off.Nutrient.caffeine,
    off.Nutrient.alcohol,
    off.Nutrient.cocoa,
    off.Nutrient.fruitsVegetablesNuts,
  ];

  /// Returns the unit options offered by the editor for [nutrient].
  ///
  /// Weight nutrients (grams-based) offer g/mg/mcg, energy nutrients offer
  /// kcal/kJ, and percent nutrients offer only the percent unit. Volume and
  /// other exotic units are never offered because no curated nutrient uses
  /// them on Open Food Facts.
  static List<String> allowedUnits(off.Nutrient nutrient) =>
      switch (nutrient.typicalUnit) {
        off.Unit.G ||
        off.Unit.MILLI_G ||
        off.Unit.MICRO_G => ['g', 'mg', 'mcg'],
        off.Unit.KCAL || off.Unit.KJ => ['kcal', 'kj'],
        off.Unit.PERCENT => ['%'],
        _ => const [],
      };

  /// Returns the app-canonical unit for [nutrient] (see [OffUnitCatalog]).
  ///
  /// This is the unit a value from the API is converted into before storage
  /// (e.g. vitamin C from grams to mg) and the default unit a new editor row
  /// starts with.
  static String canonicalUnitFor(off.Nutrient nutrient) =>
      OffUnitCatalog.sdkUnitToCanonical[nutrient.typicalUnit]!;

  /// Returns the [off.Nutrient] matching [offTag], or null when the tag is
  /// not part of the curated catalog.
  ///
  /// Uses the SDK lookup so the Open Food Facts 'energy' special case
  /// (mapped to energy-kj) is handled consistently.
  static off.Nutrient? nutrientFromOffTag(String offTag) {
    final nutrient = off.Nutrient.fromOffTag(offTag);
    if (nutrient == null) return null;
    if (coreNutrients.contains(nutrient)) return null;
    if (!nutrients.contains(nutrient)) return null;
    return nutrient;
  }
}
