// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Product {

/// The barcode (EAN‑13, UPC, etc.) that uniquely identifies the product.
///
/// This is the primary key in the local database and the lookup key for
/// the Open Food Facts API.
@JsonKey(name: '_id') String get barcode;/// The product name as returned by Open Food Facts.
///
/// In rare cases the API may return an empty string; the repository
/// should handle that gracefully.
@JsonKey(name: 'product_name') String get name;/// The brand name(s), often comma‑separated when multiple brands exist
/// (e.g. `"Ferrero"`, `"Nestlé, Nespresso"`).
@JsonKey(name: 'brands') String? get brand;/// A URL to the product’s front image on the Open Food Facts CDN.
///
/// May be `null` if no image has been uploaded for this product.
@JsonKey(name: 'image_url') String? get imageUrl;/// The product category as assigned by the Open Food Facts community.
///
/// Often a comma‑separated hierarchy (e.g. `"Spreads, Sweet spreads"`).
/// Used in the add‑to‑inventory screen to suggest a default expiry date
/// based on the category (e.g., dairy → +7 days).
@JsonKey(name: 'category') String? get category;/// The full ingredients list as plain text.
///
/// Currently stored as a single string, exactly as returned by the API.
/// In the future this could be migrated to a separate `ingredients` table
/// to enable allergen filtering or per‑ingredient search.
@JsonKey(name: 'ingredients_text') String? get ingredients;/// The suggested serving size, typically with a unit (e.g. `"15 g"`,
/// `"1 cookie (28 g)"`).
@JsonKey(name: 'serving_size') String? get servingSize;/// Energy content in **kilocalories per 100 g** (or 100 ml).
///
/// Sourced from `nutriments.energy-kcal_100g` in the API response.
@JsonKey(name: 'energy_kcal') double? get energyKcal;/// Protein content in **grams per 100 g** (or 100 ml).
@JsonKey(name: 'protein_g') double? get proteinG;/// Carbohydrate content in **grams per 100 g** (or 100 ml).
@JsonKey(name: 'carbs_g') double? get carbsG;/// Fat content in **grams per 100 g** (or 100 ml).
@JsonKey(name: 'fat_g') double? get fatG;/// Fiber content in **grams per 100 g** (or 100 ml).
@JsonKey(name: 'fiber_g') double? get fiberG;/// Salt content in **grams per 100 g** (or 100 ml).
@JsonKey(name: 'salt_g') double? get saltG;/// Epoch timestamp (milliseconds since Unix epoch) of when the product
/// data was last fetched from the API or submitted by the user.
///
/// Set automatically in `OpenFoodFactsApi.getByBarcode` and
/// `OpenFoodFactsApi.submitProduct`.
@JsonKey(name: 'last_synced') int? get lastSynced;/// The Nutri-Score grade of the product (`'a'` through `'e'`), or `null`
/// if the data is unavailable. May also be `'not-applicable'` when the
/// Nutri-Score system does not apply to this product category (e.g. food
/// additives).
///
/// Sourced from `nutriscore_grade` in the Open Food Facts v3 API.
@JsonKey(name: 'nutriscore_grade') String? get nutriscoreGrade;/// The product category that makes Nutri-Score not applicable, if any.
///
/// This is present only when [nutriscoreGrade] is `'not-applicable'` and
/// explains why (e.g. `'en:food-additives'`).
///
/// Sourced from `nutriscore_data.nutriscore_not_applicable_for_category`
/// in the API response. This field is not included in the JSON generated
/// by `json_serializable` because the value comes from a nested object.
@JsonKey(includeFromJson: false, includeToJson: false) String? get nutriscoreNotApplicableCategory;/// The origin of this product record.
///
/// - `'api'` — fetched from Open Food Facts (can be safely flushed and
///   re‑fetched).
/// - `'manual'` — entered by the user via the add‑product screen or
///   imported from CSV (must never be deleted by a cache flush).
///
/// Defaults to `'api'` because most products come from the OFF
/// integration. The add‑product screen and CSV import override it to
/// `'manual'`.
///
/// Not serialised from JSON because the OFF API does not include this
/// field; it is only stored in the local database.
@JsonKey(includeFromJson: false, includeToJson: false) String get source;/// Local file path to a photo of the nutrition facts table.
///
/// Populated when the user captures a photo on the manual‑entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
/// Not serialised to/from JSON because it is only used locally.
@JsonKey(includeFromJson: false, includeToJson: false) String? get nutritionImagePath;/// Local file path to a photo of the ingredients list.
///
/// Populated when the user captures a photo on the manual‑entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
/// Not serialised to/from JSON because it is only used locally.
@JsonKey(includeFromJson: false, includeToJson: false) String? get ingredientsImagePath;/// Local file path to a photo of the product packaging / front.
///
/// Populated when the user captures a photo on the manual‑entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
/// Not serialised to/from JSON because it is only used locally.
@JsonKey(includeFromJson: false, includeToJson: false) String? get productImagePath;/// The submission status of this product to Open Food Facts.
///
/// - [productSubmissionNotSubmitted] – not yet submitted (default).
/// - [productSubmissionPending] – queued for submission.
/// - [productSubmissionSubmitted] – successfully submitted.
/// - [productSubmissionFailed] – submission failed; retry possible.
///
/// Not serialised from JSON because the OFF API does not include this
/// field; it is only stored in the local database.
@JsonKey(includeFromJson: false, includeToJson: false) String get submissionStatus;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.category, category) || other.category == category)&&(identical(other.ingredients, ingredients) || other.ingredients == ingredients)&&(identical(other.servingSize, servingSize) || other.servingSize == servingSize)&&(identical(other.energyKcal, energyKcal) || other.energyKcal == energyKcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG)&&(identical(other.saltG, saltG) || other.saltG == saltG)&&(identical(other.lastSynced, lastSynced) || other.lastSynced == lastSynced)&&(identical(other.nutriscoreGrade, nutriscoreGrade) || other.nutriscoreGrade == nutriscoreGrade)&&(identical(other.nutriscoreNotApplicableCategory, nutriscoreNotApplicableCategory) || other.nutriscoreNotApplicableCategory == nutriscoreNotApplicableCategory)&&(identical(other.source, source) || other.source == source)&&(identical(other.nutritionImagePath, nutritionImagePath) || other.nutritionImagePath == nutritionImagePath)&&(identical(other.ingredientsImagePath, ingredientsImagePath) || other.ingredientsImagePath == ingredientsImagePath)&&(identical(other.productImagePath, productImagePath) || other.productImagePath == productImagePath)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,barcode,name,brand,imageUrl,category,ingredients,servingSize,energyKcal,proteinG,carbsG,fatG,fiberG,saltG,lastSynced,nutriscoreGrade,nutriscoreNotApplicableCategory,source,nutritionImagePath,ingredientsImagePath,productImagePath,submissionStatus]);

@override
String toString() {
  return 'Product(barcode: $barcode, name: $name, brand: $brand, imageUrl: $imageUrl, category: $category, ingredients: $ingredients, servingSize: $servingSize, energyKcal: $energyKcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG, saltG: $saltG, lastSynced: $lastSynced, nutriscoreGrade: $nutriscoreGrade, nutriscoreNotApplicableCategory: $nutriscoreNotApplicableCategory, source: $source, nutritionImagePath: $nutritionImagePath, ingredientsImagePath: $ingredientsImagePath, productImagePath: $productImagePath, submissionStatus: $submissionStatus)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String barcode,@JsonKey(name: 'product_name') String name,@JsonKey(name: 'brands') String? brand,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'category') String? category,@JsonKey(name: 'ingredients_text') String? ingredients,@JsonKey(name: 'serving_size') String? servingSize,@JsonKey(name: 'energy_kcal') double? energyKcal,@JsonKey(name: 'protein_g') double? proteinG,@JsonKey(name: 'carbs_g') double? carbsG,@JsonKey(name: 'fat_g') double? fatG,@JsonKey(name: 'fiber_g') double? fiberG,@JsonKey(name: 'salt_g') double? saltG,@JsonKey(name: 'last_synced') int? lastSynced,@JsonKey(name: 'nutriscore_grade') String? nutriscoreGrade,@JsonKey(includeFromJson: false, includeToJson: false) String? nutriscoreNotApplicableCategory,@JsonKey(includeFromJson: false, includeToJson: false) String source,@JsonKey(includeFromJson: false, includeToJson: false) String? nutritionImagePath,@JsonKey(includeFromJson: false, includeToJson: false) String? ingredientsImagePath,@JsonKey(includeFromJson: false, includeToJson: false) String? productImagePath,@JsonKey(includeFromJson: false, includeToJson: false) String submissionStatus
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? barcode = null,Object? name = null,Object? brand = freezed,Object? imageUrl = freezed,Object? category = freezed,Object? ingredients = freezed,Object? servingSize = freezed,Object? energyKcal = freezed,Object? proteinG = freezed,Object? carbsG = freezed,Object? fatG = freezed,Object? fiberG = freezed,Object? saltG = freezed,Object? lastSynced = freezed,Object? nutriscoreGrade = freezed,Object? nutriscoreNotApplicableCategory = freezed,Object? source = null,Object? nutritionImagePath = freezed,Object? ingredientsImagePath = freezed,Object? productImagePath = freezed,Object? submissionStatus = null,}) {
  return _then(_self.copyWith(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,ingredients: freezed == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as String?,servingSize: freezed == servingSize ? _self.servingSize : servingSize // ignore: cast_nullable_to_non_nullable
as String?,energyKcal: freezed == energyKcal ? _self.energyKcal : energyKcal // ignore: cast_nullable_to_non_nullable
as double?,proteinG: freezed == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double?,carbsG: freezed == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double?,fatG: freezed == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double?,fiberG: freezed == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double?,saltG: freezed == saltG ? _self.saltG : saltG // ignore: cast_nullable_to_non_nullable
as double?,lastSynced: freezed == lastSynced ? _self.lastSynced : lastSynced // ignore: cast_nullable_to_non_nullable
as int?,nutriscoreGrade: freezed == nutriscoreGrade ? _self.nutriscoreGrade : nutriscoreGrade // ignore: cast_nullable_to_non_nullable
as String?,nutriscoreNotApplicableCategory: freezed == nutriscoreNotApplicableCategory ? _self.nutriscoreNotApplicableCategory : nutriscoreNotApplicableCategory // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,nutritionImagePath: freezed == nutritionImagePath ? _self.nutritionImagePath : nutritionImagePath // ignore: cast_nullable_to_non_nullable
as String?,ingredientsImagePath: freezed == ingredientsImagePath ? _self.ingredientsImagePath : ingredientsImagePath // ignore: cast_nullable_to_non_nullable
as String?,productImagePath: freezed == productImagePath ? _self.productImagePath : productImagePath // ignore: cast_nullable_to_non_nullable
as String?,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String barcode, @JsonKey(name: 'product_name')  String name, @JsonKey(name: 'brands')  String? brand, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'category')  String? category, @JsonKey(name: 'ingredients_text')  String? ingredients, @JsonKey(name: 'serving_size')  String? servingSize, @JsonKey(name: 'energy_kcal')  double? energyKcal, @JsonKey(name: 'protein_g')  double? proteinG, @JsonKey(name: 'carbs_g')  double? carbsG, @JsonKey(name: 'fat_g')  double? fatG, @JsonKey(name: 'fiber_g')  double? fiberG, @JsonKey(name: 'salt_g')  double? saltG, @JsonKey(name: 'last_synced')  int? lastSynced, @JsonKey(name: 'nutriscore_grade')  String? nutriscoreGrade, @JsonKey(includeFromJson: false, includeToJson: false)  String? nutriscoreNotApplicableCategory, @JsonKey(includeFromJson: false, includeToJson: false)  String source, @JsonKey(includeFromJson: false, includeToJson: false)  String? nutritionImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String? ingredientsImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String? productImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String submissionStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.barcode,_that.name,_that.brand,_that.imageUrl,_that.category,_that.ingredients,_that.servingSize,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.lastSynced,_that.nutriscoreGrade,_that.nutriscoreNotApplicableCategory,_that.source,_that.nutritionImagePath,_that.ingredientsImagePath,_that.productImagePath,_that.submissionStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String barcode, @JsonKey(name: 'product_name')  String name, @JsonKey(name: 'brands')  String? brand, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'category')  String? category, @JsonKey(name: 'ingredients_text')  String? ingredients, @JsonKey(name: 'serving_size')  String? servingSize, @JsonKey(name: 'energy_kcal')  double? energyKcal, @JsonKey(name: 'protein_g')  double? proteinG, @JsonKey(name: 'carbs_g')  double? carbsG, @JsonKey(name: 'fat_g')  double? fatG, @JsonKey(name: 'fiber_g')  double? fiberG, @JsonKey(name: 'salt_g')  double? saltG, @JsonKey(name: 'last_synced')  int? lastSynced, @JsonKey(name: 'nutriscore_grade')  String? nutriscoreGrade, @JsonKey(includeFromJson: false, includeToJson: false)  String? nutriscoreNotApplicableCategory, @JsonKey(includeFromJson: false, includeToJson: false)  String source, @JsonKey(includeFromJson: false, includeToJson: false)  String? nutritionImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String? ingredientsImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String? productImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String submissionStatus)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.barcode,_that.name,_that.brand,_that.imageUrl,_that.category,_that.ingredients,_that.servingSize,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.lastSynced,_that.nutriscoreGrade,_that.nutriscoreNotApplicableCategory,_that.source,_that.nutritionImagePath,_that.ingredientsImagePath,_that.productImagePath,_that.submissionStatus);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String barcode, @JsonKey(name: 'product_name')  String name, @JsonKey(name: 'brands')  String? brand, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'category')  String? category, @JsonKey(name: 'ingredients_text')  String? ingredients, @JsonKey(name: 'serving_size')  String? servingSize, @JsonKey(name: 'energy_kcal')  double? energyKcal, @JsonKey(name: 'protein_g')  double? proteinG, @JsonKey(name: 'carbs_g')  double? carbsG, @JsonKey(name: 'fat_g')  double? fatG, @JsonKey(name: 'fiber_g')  double? fiberG, @JsonKey(name: 'salt_g')  double? saltG, @JsonKey(name: 'last_synced')  int? lastSynced, @JsonKey(name: 'nutriscore_grade')  String? nutriscoreGrade, @JsonKey(includeFromJson: false, includeToJson: false)  String? nutriscoreNotApplicableCategory, @JsonKey(includeFromJson: false, includeToJson: false)  String source, @JsonKey(includeFromJson: false, includeToJson: false)  String? nutritionImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String? ingredientsImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String? productImagePath, @JsonKey(includeFromJson: false, includeToJson: false)  String submissionStatus)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.barcode,_that.name,_that.brand,_that.imageUrl,_that.category,_that.ingredients,_that.servingSize,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.lastSynced,_that.nutriscoreGrade,_that.nutriscoreNotApplicableCategory,_that.source,_that.nutritionImagePath,_that.ingredientsImagePath,_that.productImagePath,_that.submissionStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({@JsonKey(name: '_id') required this.barcode, @JsonKey(name: 'product_name') required this.name, @JsonKey(name: 'brands') this.brand, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'category') this.category, @JsonKey(name: 'ingredients_text') this.ingredients, @JsonKey(name: 'serving_size') this.servingSize, @JsonKey(name: 'energy_kcal') this.energyKcal, @JsonKey(name: 'protein_g') this.proteinG, @JsonKey(name: 'carbs_g') this.carbsG, @JsonKey(name: 'fat_g') this.fatG, @JsonKey(name: 'fiber_g') this.fiberG, @JsonKey(name: 'salt_g') this.saltG, @JsonKey(name: 'last_synced') this.lastSynced, @JsonKey(name: 'nutriscore_grade') this.nutriscoreGrade, @JsonKey(includeFromJson: false, includeToJson: false) this.nutriscoreNotApplicableCategory, @JsonKey(includeFromJson: false, includeToJson: false) this.source = 'api', @JsonKey(includeFromJson: false, includeToJson: false) this.nutritionImagePath, @JsonKey(includeFromJson: false, includeToJson: false) this.ingredientsImagePath, @JsonKey(includeFromJson: false, includeToJson: false) this.productImagePath, @JsonKey(includeFromJson: false, includeToJson: false) this.submissionStatus = productSubmissionNotSubmitted});
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

/// The barcode (EAN‑13, UPC, etc.) that uniquely identifies the product.
///
/// This is the primary key in the local database and the lookup key for
/// the Open Food Facts API.
@override@JsonKey(name: '_id') final  String barcode;
/// The product name as returned by Open Food Facts.
///
/// In rare cases the API may return an empty string; the repository
/// should handle that gracefully.
@override@JsonKey(name: 'product_name') final  String name;
/// The brand name(s), often comma‑separated when multiple brands exist
/// (e.g. `"Ferrero"`, `"Nestlé, Nespresso"`).
@override@JsonKey(name: 'brands') final  String? brand;
/// A URL to the product’s front image on the Open Food Facts CDN.
///
/// May be `null` if no image has been uploaded for this product.
@override@JsonKey(name: 'image_url') final  String? imageUrl;
/// The product category as assigned by the Open Food Facts community.
///
/// Often a comma‑separated hierarchy (e.g. `"Spreads, Sweet spreads"`).
/// Used in the add‑to‑inventory screen to suggest a default expiry date
/// based on the category (e.g., dairy → +7 days).
@override@JsonKey(name: 'category') final  String? category;
/// The full ingredients list as plain text.
///
/// Currently stored as a single string, exactly as returned by the API.
/// In the future this could be migrated to a separate `ingredients` table
/// to enable allergen filtering or per‑ingredient search.
@override@JsonKey(name: 'ingredients_text') final  String? ingredients;
/// The suggested serving size, typically with a unit (e.g. `"15 g"`,
/// `"1 cookie (28 g)"`).
@override@JsonKey(name: 'serving_size') final  String? servingSize;
/// Energy content in **kilocalories per 100 g** (or 100 ml).
///
/// Sourced from `nutriments.energy-kcal_100g` in the API response.
@override@JsonKey(name: 'energy_kcal') final  double? energyKcal;
/// Protein content in **grams per 100 g** (or 100 ml).
@override@JsonKey(name: 'protein_g') final  double? proteinG;
/// Carbohydrate content in **grams per 100 g** (or 100 ml).
@override@JsonKey(name: 'carbs_g') final  double? carbsG;
/// Fat content in **grams per 100 g** (or 100 ml).
@override@JsonKey(name: 'fat_g') final  double? fatG;
/// Fiber content in **grams per 100 g** (or 100 ml).
@override@JsonKey(name: 'fiber_g') final  double? fiberG;
/// Salt content in **grams per 100 g** (or 100 ml).
@override@JsonKey(name: 'salt_g') final  double? saltG;
/// Epoch timestamp (milliseconds since Unix epoch) of when the product
/// data was last fetched from the API or submitted by the user.
///
/// Set automatically in `OpenFoodFactsApi.getByBarcode` and
/// `OpenFoodFactsApi.submitProduct`.
@override@JsonKey(name: 'last_synced') final  int? lastSynced;
/// The Nutri-Score grade of the product (`'a'` through `'e'`), or `null`
/// if the data is unavailable. May also be `'not-applicable'` when the
/// Nutri-Score system does not apply to this product category (e.g. food
/// additives).
///
/// Sourced from `nutriscore_grade` in the Open Food Facts v3 API.
@override@JsonKey(name: 'nutriscore_grade') final  String? nutriscoreGrade;
/// The product category that makes Nutri-Score not applicable, if any.
///
/// This is present only when [nutriscoreGrade] is `'not-applicable'` and
/// explains why (e.g. `'en:food-additives'`).
///
/// Sourced from `nutriscore_data.nutriscore_not_applicable_for_category`
/// in the API response. This field is not included in the JSON generated
/// by `json_serializable` because the value comes from a nested object.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? nutriscoreNotApplicableCategory;
/// The origin of this product record.
///
/// - `'api'` — fetched from Open Food Facts (can be safely flushed and
///   re‑fetched).
/// - `'manual'` — entered by the user via the add‑product screen or
///   imported from CSV (must never be deleted by a cache flush).
///
/// Defaults to `'api'` because most products come from the OFF
/// integration. The add‑product screen and CSV import override it to
/// `'manual'`.
///
/// Not serialised from JSON because the OFF API does not include this
/// field; it is only stored in the local database.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String source;
/// Local file path to a photo of the nutrition facts table.
///
/// Populated when the user captures a photo on the manual‑entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
/// Not serialised to/from JSON because it is only used locally.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? nutritionImagePath;
/// Local file path to a photo of the ingredients list.
///
/// Populated when the user captures a photo on the manual‑entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
/// Not serialised to/from JSON because it is only used locally.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? ingredientsImagePath;
/// Local file path to a photo of the product packaging / front.
///
/// Populated when the user captures a photo on the manual‑entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
/// Not serialised to/from JSON because it is only used locally.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? productImagePath;
/// The submission status of this product to Open Food Facts.
///
/// - [productSubmissionNotSubmitted] – not yet submitted (default).
/// - [productSubmissionPending] – queued for submission.
/// - [productSubmissionSubmitted] – successfully submitted.
/// - [productSubmissionFailed] – submission failed; retry possible.
///
/// Not serialised from JSON because the OFF API does not include this
/// field; it is only stored in the local database.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String submissionStatus;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.category, category) || other.category == category)&&(identical(other.ingredients, ingredients) || other.ingredients == ingredients)&&(identical(other.servingSize, servingSize) || other.servingSize == servingSize)&&(identical(other.energyKcal, energyKcal) || other.energyKcal == energyKcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG)&&(identical(other.saltG, saltG) || other.saltG == saltG)&&(identical(other.lastSynced, lastSynced) || other.lastSynced == lastSynced)&&(identical(other.nutriscoreGrade, nutriscoreGrade) || other.nutriscoreGrade == nutriscoreGrade)&&(identical(other.nutriscoreNotApplicableCategory, nutriscoreNotApplicableCategory) || other.nutriscoreNotApplicableCategory == nutriscoreNotApplicableCategory)&&(identical(other.source, source) || other.source == source)&&(identical(other.nutritionImagePath, nutritionImagePath) || other.nutritionImagePath == nutritionImagePath)&&(identical(other.ingredientsImagePath, ingredientsImagePath) || other.ingredientsImagePath == ingredientsImagePath)&&(identical(other.productImagePath, productImagePath) || other.productImagePath == productImagePath)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,barcode,name,brand,imageUrl,category,ingredients,servingSize,energyKcal,proteinG,carbsG,fatG,fiberG,saltG,lastSynced,nutriscoreGrade,nutriscoreNotApplicableCategory,source,nutritionImagePath,ingredientsImagePath,productImagePath,submissionStatus]);

@override
String toString() {
  return 'Product(barcode: $barcode, name: $name, brand: $brand, imageUrl: $imageUrl, category: $category, ingredients: $ingredients, servingSize: $servingSize, energyKcal: $energyKcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG, saltG: $saltG, lastSynced: $lastSynced, nutriscoreGrade: $nutriscoreGrade, nutriscoreNotApplicableCategory: $nutriscoreNotApplicableCategory, source: $source, nutritionImagePath: $nutritionImagePath, ingredientsImagePath: $ingredientsImagePath, productImagePath: $productImagePath, submissionStatus: $submissionStatus)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String barcode,@JsonKey(name: 'product_name') String name,@JsonKey(name: 'brands') String? brand,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'category') String? category,@JsonKey(name: 'ingredients_text') String? ingredients,@JsonKey(name: 'serving_size') String? servingSize,@JsonKey(name: 'energy_kcal') double? energyKcal,@JsonKey(name: 'protein_g') double? proteinG,@JsonKey(name: 'carbs_g') double? carbsG,@JsonKey(name: 'fat_g') double? fatG,@JsonKey(name: 'fiber_g') double? fiberG,@JsonKey(name: 'salt_g') double? saltG,@JsonKey(name: 'last_synced') int? lastSynced,@JsonKey(name: 'nutriscore_grade') String? nutriscoreGrade,@JsonKey(includeFromJson: false, includeToJson: false) String? nutriscoreNotApplicableCategory,@JsonKey(includeFromJson: false, includeToJson: false) String source,@JsonKey(includeFromJson: false, includeToJson: false) String? nutritionImagePath,@JsonKey(includeFromJson: false, includeToJson: false) String? ingredientsImagePath,@JsonKey(includeFromJson: false, includeToJson: false) String? productImagePath,@JsonKey(includeFromJson: false, includeToJson: false) String submissionStatus
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? barcode = null,Object? name = null,Object? brand = freezed,Object? imageUrl = freezed,Object? category = freezed,Object? ingredients = freezed,Object? servingSize = freezed,Object? energyKcal = freezed,Object? proteinG = freezed,Object? carbsG = freezed,Object? fatG = freezed,Object? fiberG = freezed,Object? saltG = freezed,Object? lastSynced = freezed,Object? nutriscoreGrade = freezed,Object? nutriscoreNotApplicableCategory = freezed,Object? source = null,Object? nutritionImagePath = freezed,Object? ingredientsImagePath = freezed,Object? productImagePath = freezed,Object? submissionStatus = null,}) {
  return _then(_Product(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,ingredients: freezed == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as String?,servingSize: freezed == servingSize ? _self.servingSize : servingSize // ignore: cast_nullable_to_non_nullable
as String?,energyKcal: freezed == energyKcal ? _self.energyKcal : energyKcal // ignore: cast_nullable_to_non_nullable
as double?,proteinG: freezed == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double?,carbsG: freezed == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double?,fatG: freezed == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double?,fiberG: freezed == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double?,saltG: freezed == saltG ? _self.saltG : saltG // ignore: cast_nullable_to_non_nullable
as double?,lastSynced: freezed == lastSynced ? _self.lastSynced : lastSynced // ignore: cast_nullable_to_non_nullable
as int?,nutriscoreGrade: freezed == nutriscoreGrade ? _self.nutriscoreGrade : nutriscoreGrade // ignore: cast_nullable_to_non_nullable
as String?,nutriscoreNotApplicableCategory: freezed == nutriscoreNotApplicableCategory ? _self.nutriscoreNotApplicableCategory : nutriscoreNotApplicableCategory // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,nutritionImagePath: freezed == nutritionImagePath ? _self.nutritionImagePath : nutritionImagePath // ignore: cast_nullable_to_non_nullable
as String?,ingredientsImagePath: freezed == ingredientsImagePath ? _self.ingredientsImagePath : ingredientsImagePath // ignore: cast_nullable_to_non_nullable
as String?,productImagePath: freezed == productImagePath ? _self.productImagePath : productImagePath // ignore: cast_nullable_to_non_nullable
as String?,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
