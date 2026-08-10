import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/utils/nutrient_catalog.dart';
import 'package:pantry_app/utils/off_units.dart';

part 'product_nutrient.freezed.dart';
part 'product_nutrient.g.dart';

/// A single additional nutrient stored alongside the six core nutrition
/// fields of a product.
///
/// Additional nutrients are the non-core contributors (vitamins, minerals,
/// fats, sugars, percent nutrients) that the user can add on the manual
/// entry screen and that are imported from Open Food Facts. Unlike the core
/// fields, each additional nutrient carries its own [value] and [unit] so a
/// vitamin can be stored in mg while a mineral is stored in mcg.
///
/// The [offTag] is the Open Food Facts tag (e.g. 'vitamin-c', 'sodium') and
/// uniquely identifies the nutrient. The unit uses the app-canonical
/// spellings from [OffUnitCatalog] ('g', 'mg', 'mcg', 'kcal', 'kj', '%').
///
/// See also:
/// - [OffUnitCatalog] — canonical unit spellings.
/// - [NutrientCatalog] — the curated nutrient set.
@freezed
abstract class ProductNutrient with _$ProductNutrient {
  /// Constructs a [ProductNutrient].
  ///
  /// All three fields are required: the Open Food Facts tag, the numeric
  /// value, and the app-canonical unit the value is expressed in.
  const factory ProductNutrient({
    /// The Open Food Facts nutrient tag (e.g. 'vitamin-c', 'sodium').
    required String offTag,

    /// The nutrient value in [unit].
    required double value,

    /// The app-canonical unit ([OffUnitCatalog]) the [value] uses.
    required String unit,
  }) = _ProductNutrient;

  /// Creates a [ProductNutrient] from a JSON map.
  ///
  /// Used when decoding the additional_nutrients JSON column of the local
  /// database and the product cache entries stored in Firestore.
  factory ProductNutrient.fromJson(Map<String, dynamic> json) =>
      _$ProductNutrientFromJson(json);
}
