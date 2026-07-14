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

/// The barcode (EAN-13, UPC, etc.) that uniquely identifies the product.
///
/// This is the primary key in the local database and the lookup key for
/// the Open Food Facts API.
 String get barcode;/// The product name as returned by Open Food Facts.
///
/// In rare cases the API may return an empty string; the repository
/// should handle that gracefully.
 String get name;/// The brand name(s), often comma-separated when multiple brands exist
/// (e.g. `"Ferrero"`, `"Nestle, Nespresso"`).
 String? get brand;/// A URL to the product's front image on the Open Food Facts CDN.
///
/// May be `null` if no image has been uploaded for this product.
 String? get imageUrl;/// OFF CDN URL for the nutrition facts table image, if available.
///
/// Used by the photo-completeness stats screen to compare local user
/// photos against what OFF already has for this product.
 String? get offNutritionImageUrl;/// OFF CDN URL for the ingredients list image, if available.
 String? get offIngredientsImageUrl;/// OFF CDN URL for the product front/packaging image, if available.
 String? get offProductImageUrl;/// The OFF taxonomy hierarchy for this product, from broadest to
/// most specific. Each entry is a language-prefixed tag
/// (e.g. `en:eggs`, `en:chicken-eggs`).
///
/// May be `null` for manually entered products or when OFF has no
/// taxonomy data.
 List<String>? get categoriesHierarchy;/// The product category as assigned by the Open Food Facts community.
///
/// Often a comma-separated hierarchy (e.g. `"Spreads, Sweet spreads"`).
/// Used in the add-to-inventory screen to suggest a default expiry date
/// based on the category (e.g., dairy -> +7 days).
 String? get category;/// The full ingredients list as plain text.
///
/// Currently stored as a single string, exactly as returned by the API.
/// In the future this could be migrated to a separate `ingredients` table
/// to enable allergen filtering or per-ingredient search.
 String? get ingredients;/// The suggested serving size, typically with a unit (e.g. `"15 g"`,
/// `"1 cookie (28 g)"`).
 String? get servingSize;/// Energy content in **kilocalories per 100 g** (or 100 ml).
///
/// Sourced from `nutriments.energy-kcal_100g` in the API response.
 double? get energyKcal;/// Protein content in **grams per 100 g** (or 100 ml).
 double? get proteinG;/// Carbohydrate content in **grams per 100 g** (or 100 ml).
 double? get carbsG;/// Fat content in **grams per 100 g** (or 100 ml).
 double? get fatG;/// Fiber content in **grams per 100 g** (or 100 ml).
 double? get fiberG;/// Salt content in **grams per 100 g** (or 100 ml).
 double? get saltG;/// Epoch timestamp (milliseconds since Unix epoch) of when the product
/// data was last fetched from the API or submitted by the user.
///
/// Set automatically when the product is fetched from the API or
/// submitted by the user.
 int? get lastSynced;/// The Nutri-Score grade of the product (`'a'` through `'e'`), or `null`
/// if the data is unavailable. May also be `'not-applicable'` when the
/// Nutri-Score system does not apply to this product category (e.g. food
/// additives).
///
/// Sourced from `nutrition_grade_fr` in the Open Food Facts v3 API via
/// the SDK's `nutriscore` field.
 String? get nutriscoreGrade;/// The product category that makes Nutri-Score not applicable, if any.
///
/// This is present only when [nutriscoreGrade] is `'not-applicable'` and
/// explains why (e.g. `'en:food-additives'`).
///
/// Note: the official Dart SDK does not expose the
/// `nutriscore_data.nutriscore_not_applicable_for_category` field, so
/// this value is only populated when reading from the local database
/// for previously cached products.
 String? get nutriscoreNotApplicableCategory;/// The origin of this product record.
///
/// - `'api'` — fetched from Open Food Facts (can be safely flushed and
///   re-fetched).
/// - `'manual'` — entered by the user via the add-product screen or
///   imported from CSV (must never be deleted by a cache flush).
///
/// Defaults to `'api'` because most products come from the OFF
/// integration. The add-product screen overrides it to
/// `'manual'`.
 String get source;/// The locale code of the language used when this product was fetched
/// from Open Food Facts (e.g. `'en'`, `'fr'`, `'pt'`).
///
/// This represents the language *requested* by the client, not necessarily
/// the language *returned* — OFF silently falls back to English if the
/// requested language has no data for a given field. Storing the
/// requested code allows the "Show in language" ActionChip to display
/// meaningful options.
///
/// Defaults to 'en' for legacy records and manually entered products.
 String get languageCode;/// Local file path to a photo of the nutrition facts table.
///
/// Populated when the user captures a photo on the manual-entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
 String? get nutritionImagePath;/// Local file path to a photo of the ingredients list.
///
/// Populated when the user captures a photo on the manual-entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
 String? get ingredientsImagePath;/// Local file path to a photo of the product packaging / front.
///
/// Populated when the user captures a photo on the manual-entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
 String? get productImagePath;/// The submission status of this product to Open Food Facts.
///
/// - [productSubmissionNotSubmitted] — not yet submitted (default).
/// - [productSubmissionPending] — queued for submission.
/// - [productSubmissionSubmitted] — successfully submitted.
/// - [productSubmissionFailed] — submission failed; retry possible.
 String get submissionStatus;/// The PLU (Price Look-Up) code for this product, if it is a fresh
/// produce item (e.g. `'4011'` for Banana, `'4032'` for Apple).
///
/// Only meaningful when [productType] is [ProductType.produce]. 4-digit
/// codes are standard PLU codes; 5-digit codes starting with `'9'`
/// indicate organic produce. This field is nullable for barcoded and
/// custom products.
 String? get pluCode;/// The classification of this product.
///
/// - [ProductType.barcoded] — scanned from manufacturer barcode (default).
/// - [ProductType.produce] — identified by PLU code as fresh produce.
/// - [ProductType.custom] — manually entered by the user.
 ProductType get productType;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.offNutritionImageUrl, offNutritionImageUrl) || other.offNutritionImageUrl == offNutritionImageUrl)&&(identical(other.offIngredientsImageUrl, offIngredientsImageUrl) || other.offIngredientsImageUrl == offIngredientsImageUrl)&&(identical(other.offProductImageUrl, offProductImageUrl) || other.offProductImageUrl == offProductImageUrl)&&const DeepCollectionEquality().equals(other.categoriesHierarchy, categoriesHierarchy)&&(identical(other.category, category) || other.category == category)&&(identical(other.ingredients, ingredients) || other.ingredients == ingredients)&&(identical(other.servingSize, servingSize) || other.servingSize == servingSize)&&(identical(other.energyKcal, energyKcal) || other.energyKcal == energyKcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG)&&(identical(other.saltG, saltG) || other.saltG == saltG)&&(identical(other.lastSynced, lastSynced) || other.lastSynced == lastSynced)&&(identical(other.nutriscoreGrade, nutriscoreGrade) || other.nutriscoreGrade == nutriscoreGrade)&&(identical(other.nutriscoreNotApplicableCategory, nutriscoreNotApplicableCategory) || other.nutriscoreNotApplicableCategory == nutriscoreNotApplicableCategory)&&(identical(other.source, source) || other.source == source)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.nutritionImagePath, nutritionImagePath) || other.nutritionImagePath == nutritionImagePath)&&(identical(other.ingredientsImagePath, ingredientsImagePath) || other.ingredientsImagePath == ingredientsImagePath)&&(identical(other.productImagePath, productImagePath) || other.productImagePath == productImagePath)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.pluCode, pluCode) || other.pluCode == pluCode)&&(identical(other.productType, productType) || other.productType == productType));
}


@override
int get hashCode => Object.hashAll([runtimeType,barcode,name,brand,imageUrl,offNutritionImageUrl,offIngredientsImageUrl,offProductImageUrl,const DeepCollectionEquality().hash(categoriesHierarchy),category,ingredients,servingSize,energyKcal,proteinG,carbsG,fatG,fiberG,saltG,lastSynced,nutriscoreGrade,nutriscoreNotApplicableCategory,source,languageCode,nutritionImagePath,ingredientsImagePath,productImagePath,submissionStatus,pluCode,productType]);

@override
String toString() {
  return 'Product(barcode: $barcode, name: $name, brand: $brand, imageUrl: $imageUrl, offNutritionImageUrl: $offNutritionImageUrl, offIngredientsImageUrl: $offIngredientsImageUrl, offProductImageUrl: $offProductImageUrl, categoriesHierarchy: $categoriesHierarchy, category: $category, ingredients: $ingredients, servingSize: $servingSize, energyKcal: $energyKcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG, saltG: $saltG, lastSynced: $lastSynced, nutriscoreGrade: $nutriscoreGrade, nutriscoreNotApplicableCategory: $nutriscoreNotApplicableCategory, source: $source, languageCode: $languageCode, nutritionImagePath: $nutritionImagePath, ingredientsImagePath: $ingredientsImagePath, productImagePath: $productImagePath, submissionStatus: $submissionStatus, pluCode: $pluCode, productType: $productType)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String barcode, String name, String? brand, String? imageUrl, String? offNutritionImageUrl, String? offIngredientsImageUrl, String? offProductImageUrl, List<String>? categoriesHierarchy, String? category, String? ingredients, String? servingSize, double? energyKcal, double? proteinG, double? carbsG, double? fatG, double? fiberG, double? saltG, int? lastSynced, String? nutriscoreGrade, String? nutriscoreNotApplicableCategory, String source, String languageCode, String? nutritionImagePath, String? ingredientsImagePath, String? productImagePath, String submissionStatus, String? pluCode, ProductType productType
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
@pragma('vm:prefer-inline') @override $Res call({Object? barcode = null,Object? name = null,Object? brand = freezed,Object? imageUrl = freezed,Object? offNutritionImageUrl = freezed,Object? offIngredientsImageUrl = freezed,Object? offProductImageUrl = freezed,Object? categoriesHierarchy = freezed,Object? category = freezed,Object? ingredients = freezed,Object? servingSize = freezed,Object? energyKcal = freezed,Object? proteinG = freezed,Object? carbsG = freezed,Object? fatG = freezed,Object? fiberG = freezed,Object? saltG = freezed,Object? lastSynced = freezed,Object? nutriscoreGrade = freezed,Object? nutriscoreNotApplicableCategory = freezed,Object? source = null,Object? languageCode = null,Object? nutritionImagePath = freezed,Object? ingredientsImagePath = freezed,Object? productImagePath = freezed,Object? submissionStatus = null,Object? pluCode = freezed,Object? productType = null,}) {
  return _then(_self.copyWith(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,offNutritionImageUrl: freezed == offNutritionImageUrl ? _self.offNutritionImageUrl : offNutritionImageUrl // ignore: cast_nullable_to_non_nullable
as String?,offIngredientsImageUrl: freezed == offIngredientsImageUrl ? _self.offIngredientsImageUrl : offIngredientsImageUrl // ignore: cast_nullable_to_non_nullable
as String?,offProductImageUrl: freezed == offProductImageUrl ? _self.offProductImageUrl : offProductImageUrl // ignore: cast_nullable_to_non_nullable
as String?,categoriesHierarchy: freezed == categoriesHierarchy ? _self.categoriesHierarchy : categoriesHierarchy // ignore: cast_nullable_to_non_nullable
as List<String>?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
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
as String,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,nutritionImagePath: freezed == nutritionImagePath ? _self.nutritionImagePath : nutritionImagePath // ignore: cast_nullable_to_non_nullable
as String?,ingredientsImagePath: freezed == ingredientsImagePath ? _self.ingredientsImagePath : ingredientsImagePath // ignore: cast_nullable_to_non_nullable
as String?,productImagePath: freezed == productImagePath ? _self.productImagePath : productImagePath // ignore: cast_nullable_to_non_nullable
as String?,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as String,pluCode: freezed == pluCode ? _self.pluCode : pluCode // ignore: cast_nullable_to_non_nullable
as String?,productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as ProductType,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String barcode,  String name,  String? brand,  String? imageUrl,  String? offNutritionImageUrl,  String? offIngredientsImageUrl,  String? offProductImageUrl,  List<String>? categoriesHierarchy,  String? category,  String? ingredients,  String? servingSize,  double? energyKcal,  double? proteinG,  double? carbsG,  double? fatG,  double? fiberG,  double? saltG,  int? lastSynced,  String? nutriscoreGrade,  String? nutriscoreNotApplicableCategory,  String source,  String languageCode,  String? nutritionImagePath,  String? ingredientsImagePath,  String? productImagePath,  String submissionStatus,  String? pluCode,  ProductType productType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.barcode,_that.name,_that.brand,_that.imageUrl,_that.offNutritionImageUrl,_that.offIngredientsImageUrl,_that.offProductImageUrl,_that.categoriesHierarchy,_that.category,_that.ingredients,_that.servingSize,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.lastSynced,_that.nutriscoreGrade,_that.nutriscoreNotApplicableCategory,_that.source,_that.languageCode,_that.nutritionImagePath,_that.ingredientsImagePath,_that.productImagePath,_that.submissionStatus,_that.pluCode,_that.productType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String barcode,  String name,  String? brand,  String? imageUrl,  String? offNutritionImageUrl,  String? offIngredientsImageUrl,  String? offProductImageUrl,  List<String>? categoriesHierarchy,  String? category,  String? ingredients,  String? servingSize,  double? energyKcal,  double? proteinG,  double? carbsG,  double? fatG,  double? fiberG,  double? saltG,  int? lastSynced,  String? nutriscoreGrade,  String? nutriscoreNotApplicableCategory,  String source,  String languageCode,  String? nutritionImagePath,  String? ingredientsImagePath,  String? productImagePath,  String submissionStatus,  String? pluCode,  ProductType productType)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.barcode,_that.name,_that.brand,_that.imageUrl,_that.offNutritionImageUrl,_that.offIngredientsImageUrl,_that.offProductImageUrl,_that.categoriesHierarchy,_that.category,_that.ingredients,_that.servingSize,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.lastSynced,_that.nutriscoreGrade,_that.nutriscoreNotApplicableCategory,_that.source,_that.languageCode,_that.nutritionImagePath,_that.ingredientsImagePath,_that.productImagePath,_that.submissionStatus,_that.pluCode,_that.productType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String barcode,  String name,  String? brand,  String? imageUrl,  String? offNutritionImageUrl,  String? offIngredientsImageUrl,  String? offProductImageUrl,  List<String>? categoriesHierarchy,  String? category,  String? ingredients,  String? servingSize,  double? energyKcal,  double? proteinG,  double? carbsG,  double? fatG,  double? fiberG,  double? saltG,  int? lastSynced,  String? nutriscoreGrade,  String? nutriscoreNotApplicableCategory,  String source,  String languageCode,  String? nutritionImagePath,  String? ingredientsImagePath,  String? productImagePath,  String submissionStatus,  String? pluCode,  ProductType productType)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.barcode,_that.name,_that.brand,_that.imageUrl,_that.offNutritionImageUrl,_that.offIngredientsImageUrl,_that.offProductImageUrl,_that.categoriesHierarchy,_that.category,_that.ingredients,_that.servingSize,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.lastSynced,_that.nutriscoreGrade,_that.nutriscoreNotApplicableCategory,_that.source,_that.languageCode,_that.nutritionImagePath,_that.ingredientsImagePath,_that.productImagePath,_that.submissionStatus,_that.pluCode,_that.productType);case _:
  return null;

}
}

}

/// @nodoc


class _Product implements Product {
  const _Product({required this.barcode, required this.name, this.brand, this.imageUrl, this.offNutritionImageUrl, this.offIngredientsImageUrl, this.offProductImageUrl, final  List<String>? categoriesHierarchy, this.category, this.ingredients, this.servingSize, this.energyKcal, this.proteinG, this.carbsG, this.fatG, this.fiberG, this.saltG, this.lastSynced, this.nutriscoreGrade, this.nutriscoreNotApplicableCategory, this.source = 'api', this.languageCode = 'en', this.nutritionImagePath, this.ingredientsImagePath, this.productImagePath, this.submissionStatus = productSubmissionNotSubmitted, this.pluCode, this.productType = ProductType.barcoded}): _categoriesHierarchy = categoriesHierarchy;
  

/// The barcode (EAN-13, UPC, etc.) that uniquely identifies the product.
///
/// This is the primary key in the local database and the lookup key for
/// the Open Food Facts API.
@override final  String barcode;
/// The product name as returned by Open Food Facts.
///
/// In rare cases the API may return an empty string; the repository
/// should handle that gracefully.
@override final  String name;
/// The brand name(s), often comma-separated when multiple brands exist
/// (e.g. `"Ferrero"`, `"Nestle, Nespresso"`).
@override final  String? brand;
/// A URL to the product's front image on the Open Food Facts CDN.
///
/// May be `null` if no image has been uploaded for this product.
@override final  String? imageUrl;
/// OFF CDN URL for the nutrition facts table image, if available.
///
/// Used by the photo-completeness stats screen to compare local user
/// photos against what OFF already has for this product.
@override final  String? offNutritionImageUrl;
/// OFF CDN URL for the ingredients list image, if available.
@override final  String? offIngredientsImageUrl;
/// OFF CDN URL for the product front/packaging image, if available.
@override final  String? offProductImageUrl;
/// The OFF taxonomy hierarchy for this product, from broadest to
/// most specific. Each entry is a language-prefixed tag
/// (e.g. `en:eggs`, `en:chicken-eggs`).
///
/// May be `null` for manually entered products or when OFF has no
/// taxonomy data.
 final  List<String>? _categoriesHierarchy;
/// The OFF taxonomy hierarchy for this product, from broadest to
/// most specific. Each entry is a language-prefixed tag
/// (e.g. `en:eggs`, `en:chicken-eggs`).
///
/// May be `null` for manually entered products or when OFF has no
/// taxonomy data.
@override List<String>? get categoriesHierarchy {
  final value = _categoriesHierarchy;
  if (value == null) return null;
  if (_categoriesHierarchy is EqualUnmodifiableListView) return _categoriesHierarchy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// The product category as assigned by the Open Food Facts community.
///
/// Often a comma-separated hierarchy (e.g. `"Spreads, Sweet spreads"`).
/// Used in the add-to-inventory screen to suggest a default expiry date
/// based on the category (e.g., dairy -> +7 days).
@override final  String? category;
/// The full ingredients list as plain text.
///
/// Currently stored as a single string, exactly as returned by the API.
/// In the future this could be migrated to a separate `ingredients` table
/// to enable allergen filtering or per-ingredient search.
@override final  String? ingredients;
/// The suggested serving size, typically with a unit (e.g. `"15 g"`,
/// `"1 cookie (28 g)"`).
@override final  String? servingSize;
/// Energy content in **kilocalories per 100 g** (or 100 ml).
///
/// Sourced from `nutriments.energy-kcal_100g` in the API response.
@override final  double? energyKcal;
/// Protein content in **grams per 100 g** (or 100 ml).
@override final  double? proteinG;
/// Carbohydrate content in **grams per 100 g** (or 100 ml).
@override final  double? carbsG;
/// Fat content in **grams per 100 g** (or 100 ml).
@override final  double? fatG;
/// Fiber content in **grams per 100 g** (or 100 ml).
@override final  double? fiberG;
/// Salt content in **grams per 100 g** (or 100 ml).
@override final  double? saltG;
/// Epoch timestamp (milliseconds since Unix epoch) of when the product
/// data was last fetched from the API or submitted by the user.
///
/// Set automatically when the product is fetched from the API or
/// submitted by the user.
@override final  int? lastSynced;
/// The Nutri-Score grade of the product (`'a'` through `'e'`), or `null`
/// if the data is unavailable. May also be `'not-applicable'` when the
/// Nutri-Score system does not apply to this product category (e.g. food
/// additives).
///
/// Sourced from `nutrition_grade_fr` in the Open Food Facts v3 API via
/// the SDK's `nutriscore` field.
@override final  String? nutriscoreGrade;
/// The product category that makes Nutri-Score not applicable, if any.
///
/// This is present only when [nutriscoreGrade] is `'not-applicable'` and
/// explains why (e.g. `'en:food-additives'`).
///
/// Note: the official Dart SDK does not expose the
/// `nutriscore_data.nutriscore_not_applicable_for_category` field, so
/// this value is only populated when reading from the local database
/// for previously cached products.
@override final  String? nutriscoreNotApplicableCategory;
/// The origin of this product record.
///
/// - `'api'` — fetched from Open Food Facts (can be safely flushed and
///   re-fetched).
/// - `'manual'` — entered by the user via the add-product screen or
///   imported from CSV (must never be deleted by a cache flush).
///
/// Defaults to `'api'` because most products come from the OFF
/// integration. The add-product screen overrides it to
/// `'manual'`.
@override@JsonKey() final  String source;
/// The locale code of the language used when this product was fetched
/// from Open Food Facts (e.g. `'en'`, `'fr'`, `'pt'`).
///
/// This represents the language *requested* by the client, not necessarily
/// the language *returned* — OFF silently falls back to English if the
/// requested language has no data for a given field. Storing the
/// requested code allows the "Show in language" ActionChip to display
/// meaningful options.
///
/// Defaults to 'en' for legacy records and manually entered products.
@override@JsonKey() final  String languageCode;
/// Local file path to a photo of the nutrition facts table.
///
/// Populated when the user captures a photo on the manual-entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
@override final  String? nutritionImagePath;
/// Local file path to a photo of the ingredients list.
///
/// Populated when the user captures a photo on the manual-entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
@override final  String? ingredientsImagePath;
/// Local file path to a photo of the product packaging / front.
///
/// Populated when the user captures a photo on the manual-entry screen.
/// Stored as a stable path inside `<app-documents>/product_images/`.
@override final  String? productImagePath;
/// The submission status of this product to Open Food Facts.
///
/// - [productSubmissionNotSubmitted] — not yet submitted (default).
/// - [productSubmissionPending] — queued for submission.
/// - [productSubmissionSubmitted] — successfully submitted.
/// - [productSubmissionFailed] — submission failed; retry possible.
@override@JsonKey() final  String submissionStatus;
/// The PLU (Price Look-Up) code for this product, if it is a fresh
/// produce item (e.g. `'4011'` for Banana, `'4032'` for Apple).
///
/// Only meaningful when [productType] is [ProductType.produce]. 4-digit
/// codes are standard PLU codes; 5-digit codes starting with `'9'`
/// indicate organic produce. This field is nullable for barcoded and
/// custom products.
@override final  String? pluCode;
/// The classification of this product.
///
/// - [ProductType.barcoded] — scanned from manufacturer barcode (default).
/// - [ProductType.produce] — identified by PLU code as fresh produce.
/// - [ProductType.custom] — manually entered by the user.
@override@JsonKey() final  ProductType productType;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.offNutritionImageUrl, offNutritionImageUrl) || other.offNutritionImageUrl == offNutritionImageUrl)&&(identical(other.offIngredientsImageUrl, offIngredientsImageUrl) || other.offIngredientsImageUrl == offIngredientsImageUrl)&&(identical(other.offProductImageUrl, offProductImageUrl) || other.offProductImageUrl == offProductImageUrl)&&const DeepCollectionEquality().equals(other._categoriesHierarchy, _categoriesHierarchy)&&(identical(other.category, category) || other.category == category)&&(identical(other.ingredients, ingredients) || other.ingredients == ingredients)&&(identical(other.servingSize, servingSize) || other.servingSize == servingSize)&&(identical(other.energyKcal, energyKcal) || other.energyKcal == energyKcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG)&&(identical(other.saltG, saltG) || other.saltG == saltG)&&(identical(other.lastSynced, lastSynced) || other.lastSynced == lastSynced)&&(identical(other.nutriscoreGrade, nutriscoreGrade) || other.nutriscoreGrade == nutriscoreGrade)&&(identical(other.nutriscoreNotApplicableCategory, nutriscoreNotApplicableCategory) || other.nutriscoreNotApplicableCategory == nutriscoreNotApplicableCategory)&&(identical(other.source, source) || other.source == source)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.nutritionImagePath, nutritionImagePath) || other.nutritionImagePath == nutritionImagePath)&&(identical(other.ingredientsImagePath, ingredientsImagePath) || other.ingredientsImagePath == ingredientsImagePath)&&(identical(other.productImagePath, productImagePath) || other.productImagePath == productImagePath)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.pluCode, pluCode) || other.pluCode == pluCode)&&(identical(other.productType, productType) || other.productType == productType));
}


@override
int get hashCode => Object.hashAll([runtimeType,barcode,name,brand,imageUrl,offNutritionImageUrl,offIngredientsImageUrl,offProductImageUrl,const DeepCollectionEquality().hash(_categoriesHierarchy),category,ingredients,servingSize,energyKcal,proteinG,carbsG,fatG,fiberG,saltG,lastSynced,nutriscoreGrade,nutriscoreNotApplicableCategory,source,languageCode,nutritionImagePath,ingredientsImagePath,productImagePath,submissionStatus,pluCode,productType]);

@override
String toString() {
  return 'Product(barcode: $barcode, name: $name, brand: $brand, imageUrl: $imageUrl, offNutritionImageUrl: $offNutritionImageUrl, offIngredientsImageUrl: $offIngredientsImageUrl, offProductImageUrl: $offProductImageUrl, categoriesHierarchy: $categoriesHierarchy, category: $category, ingredients: $ingredients, servingSize: $servingSize, energyKcal: $energyKcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG, saltG: $saltG, lastSynced: $lastSynced, nutriscoreGrade: $nutriscoreGrade, nutriscoreNotApplicableCategory: $nutriscoreNotApplicableCategory, source: $source, languageCode: $languageCode, nutritionImagePath: $nutritionImagePath, ingredientsImagePath: $ingredientsImagePath, productImagePath: $productImagePath, submissionStatus: $submissionStatus, pluCode: $pluCode, productType: $productType)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String barcode, String name, String? brand, String? imageUrl, String? offNutritionImageUrl, String? offIngredientsImageUrl, String? offProductImageUrl, List<String>? categoriesHierarchy, String? category, String? ingredients, String? servingSize, double? energyKcal, double? proteinG, double? carbsG, double? fatG, double? fiberG, double? saltG, int? lastSynced, String? nutriscoreGrade, String? nutriscoreNotApplicableCategory, String source, String languageCode, String? nutritionImagePath, String? ingredientsImagePath, String? productImagePath, String submissionStatus, String? pluCode, ProductType productType
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
@override @pragma('vm:prefer-inline') $Res call({Object? barcode = null,Object? name = null,Object? brand = freezed,Object? imageUrl = freezed,Object? offNutritionImageUrl = freezed,Object? offIngredientsImageUrl = freezed,Object? offProductImageUrl = freezed,Object? categoriesHierarchy = freezed,Object? category = freezed,Object? ingredients = freezed,Object? servingSize = freezed,Object? energyKcal = freezed,Object? proteinG = freezed,Object? carbsG = freezed,Object? fatG = freezed,Object? fiberG = freezed,Object? saltG = freezed,Object? lastSynced = freezed,Object? nutriscoreGrade = freezed,Object? nutriscoreNotApplicableCategory = freezed,Object? source = null,Object? languageCode = null,Object? nutritionImagePath = freezed,Object? ingredientsImagePath = freezed,Object? productImagePath = freezed,Object? submissionStatus = null,Object? pluCode = freezed,Object? productType = null,}) {
  return _then(_Product(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,offNutritionImageUrl: freezed == offNutritionImageUrl ? _self.offNutritionImageUrl : offNutritionImageUrl // ignore: cast_nullable_to_non_nullable
as String?,offIngredientsImageUrl: freezed == offIngredientsImageUrl ? _self.offIngredientsImageUrl : offIngredientsImageUrl // ignore: cast_nullable_to_non_nullable
as String?,offProductImageUrl: freezed == offProductImageUrl ? _self.offProductImageUrl : offProductImageUrl // ignore: cast_nullable_to_non_nullable
as String?,categoriesHierarchy: freezed == categoriesHierarchy ? _self._categoriesHierarchy : categoriesHierarchy // ignore: cast_nullable_to_non_nullable
as List<String>?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
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
as String,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,nutritionImagePath: freezed == nutritionImagePath ? _self.nutritionImagePath : nutritionImagePath // ignore: cast_nullable_to_non_nullable
as String?,ingredientsImagePath: freezed == ingredientsImagePath ? _self.ingredientsImagePath : ingredientsImagePath // ignore: cast_nullable_to_non_nullable
as String?,productImagePath: freezed == productImagePath ? _self.productImagePath : productImagePath // ignore: cast_nullable_to_non_nullable
as String?,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as String,pluCode: freezed == pluCode ? _self.pluCode : pluCode // ignore: cast_nullable_to_non_nullable
as String?,productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}


}

// dart format on
