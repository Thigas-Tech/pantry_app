// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_cache_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductCacheEntry {

/// The barcode (EAN-13, UPC, etc.) used as the Firestore document ID.
 String get barcode;/// The product name as returned by Open Food Facts.
 String get name;/// Epoch timestamp (ms) of when this entry was first created.
 int get createdAt;/// Epoch timestamp (ms) of when this entry was last refreshed.
 int get lastRefreshedAt;/// Epoch timestamp (ms) of when this entry should be refreshed next.
 int get nextRefreshAt;/// The brand name(s), often comma-separated.
@JsonKey(includeIfNull: false) String? get brand;/// The product category (e.g. "Spreads, Sweet spreads").
@JsonKey(includeIfNull: false) String? get category;/// The OFF taxonomy hierarchy, broadest to most specific.
@JsonKey(includeIfNull: false) List<String>? get categoriesHierarchy;/// The full ingredients list as plain text.
@JsonKey(includeIfNull: false) String? get ingredients;/// The suggested serving size (e.g. "15 g").
@JsonKey(includeIfNull: false) String? get servingSize;/// The display quantity as printed on packaging (e.g. "500 ml").
@JsonKey(includeIfNull: false) String? get quantity;/// Normalized numeric product quantity in g or ml.
@JsonKey(includeIfNull: false) double? get productQuantity;/// Energy in kilocalories per 100 g.
@JsonKey(includeIfNull: false) double? get energyKcal;/// Protein in grams per 100 g.
@JsonKey(includeIfNull: false) double? get proteinG;/// Carbohydrates in grams per 100 g.
@JsonKey(includeIfNull: false) double? get carbsG;/// Fat in grams per 100 g.
@JsonKey(includeIfNull: false) double? get fatG;/// Fiber in grams per 100 g.
@JsonKey(includeIfNull: false) double? get fiberG;/// Salt in grams per 100 g.
@JsonKey(includeIfNull: false) double? get saltG;/// The Nutri-Score grade ('a' through 'e'), or 'not-applicable'.
@JsonKey(includeIfNull: false) String? get nutriscoreGrade;/// URL to the product's front image on the OFF CDN.
@JsonKey(includeIfNull: false) String? get imageUrl;/// URL to the nutrition facts table image on the OFF CDN.
@JsonKey(includeIfNull: false) String? get offNutritionImageUrl;/// URL to the ingredients list image on the OFF CDN.
@JsonKey(includeIfNull: false) String? get offIngredientsImageUrl;/// URL to the product packaging image on the OFF CDN.
@JsonKey(includeIfNull: false) String? get offProductImageUrl;/// The locale used when fetching this product (e.g. 'en', 'pt').
 String get languageCode;/// Schema version for forward compatibility.
 int get schemaVersion;
/// Create a copy of ProductCacheEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCacheEntryCopyWith<ProductCacheEntry> get copyWith => _$ProductCacheEntryCopyWithImpl<ProductCacheEntry>(this as ProductCacheEntry, _$identity);

  /// Serializes this ProductCacheEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCacheEntry&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastRefreshedAt, lastRefreshedAt) || other.lastRefreshedAt == lastRefreshedAt)&&(identical(other.nextRefreshAt, nextRefreshAt) || other.nextRefreshAt == nextRefreshAt)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.categoriesHierarchy, categoriesHierarchy)&&(identical(other.ingredients, ingredients) || other.ingredients == ingredients)&&(identical(other.servingSize, servingSize) || other.servingSize == servingSize)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.productQuantity, productQuantity) || other.productQuantity == productQuantity)&&(identical(other.energyKcal, energyKcal) || other.energyKcal == energyKcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG)&&(identical(other.saltG, saltG) || other.saltG == saltG)&&(identical(other.nutriscoreGrade, nutriscoreGrade) || other.nutriscoreGrade == nutriscoreGrade)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.offNutritionImageUrl, offNutritionImageUrl) || other.offNutritionImageUrl == offNutritionImageUrl)&&(identical(other.offIngredientsImageUrl, offIngredientsImageUrl) || other.offIngredientsImageUrl == offIngredientsImageUrl)&&(identical(other.offProductImageUrl, offProductImageUrl) || other.offProductImageUrl == offProductImageUrl)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,barcode,name,createdAt,lastRefreshedAt,nextRefreshAt,brand,category,const DeepCollectionEquality().hash(categoriesHierarchy),ingredients,servingSize,quantity,productQuantity,energyKcal,proteinG,carbsG,fatG,fiberG,saltG,nutriscoreGrade,imageUrl,offNutritionImageUrl,offIngredientsImageUrl,offProductImageUrl,languageCode,schemaVersion]);

@override
String toString() {
  return 'ProductCacheEntry(barcode: $barcode, name: $name, createdAt: $createdAt, lastRefreshedAt: $lastRefreshedAt, nextRefreshAt: $nextRefreshAt, brand: $brand, category: $category, categoriesHierarchy: $categoriesHierarchy, ingredients: $ingredients, servingSize: $servingSize, quantity: $quantity, productQuantity: $productQuantity, energyKcal: $energyKcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG, saltG: $saltG, nutriscoreGrade: $nutriscoreGrade, imageUrl: $imageUrl, offNutritionImageUrl: $offNutritionImageUrl, offIngredientsImageUrl: $offIngredientsImageUrl, offProductImageUrl: $offProductImageUrl, languageCode: $languageCode, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $ProductCacheEntryCopyWith<$Res>  {
  factory $ProductCacheEntryCopyWith(ProductCacheEntry value, $Res Function(ProductCacheEntry) _then) = _$ProductCacheEntryCopyWithImpl;
@useResult
$Res call({
 String barcode, String name, int createdAt, int lastRefreshedAt, int nextRefreshAt,@JsonKey(includeIfNull: false) String? brand,@JsonKey(includeIfNull: false) String? category,@JsonKey(includeIfNull: false) List<String>? categoriesHierarchy,@JsonKey(includeIfNull: false) String? ingredients,@JsonKey(includeIfNull: false) String? servingSize,@JsonKey(includeIfNull: false) String? quantity,@JsonKey(includeIfNull: false) double? productQuantity,@JsonKey(includeIfNull: false) double? energyKcal,@JsonKey(includeIfNull: false) double? proteinG,@JsonKey(includeIfNull: false) double? carbsG,@JsonKey(includeIfNull: false) double? fatG,@JsonKey(includeIfNull: false) double? fiberG,@JsonKey(includeIfNull: false) double? saltG,@JsonKey(includeIfNull: false) String? nutriscoreGrade,@JsonKey(includeIfNull: false) String? imageUrl,@JsonKey(includeIfNull: false) String? offNutritionImageUrl,@JsonKey(includeIfNull: false) String? offIngredientsImageUrl,@JsonKey(includeIfNull: false) String? offProductImageUrl, String languageCode, int schemaVersion
});




}
/// @nodoc
class _$ProductCacheEntryCopyWithImpl<$Res>
    implements $ProductCacheEntryCopyWith<$Res> {
  _$ProductCacheEntryCopyWithImpl(this._self, this._then);

  final ProductCacheEntry _self;
  final $Res Function(ProductCacheEntry) _then;

/// Create a copy of ProductCacheEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? barcode = null,Object? name = null,Object? createdAt = null,Object? lastRefreshedAt = null,Object? nextRefreshAt = null,Object? brand = freezed,Object? category = freezed,Object? categoriesHierarchy = freezed,Object? ingredients = freezed,Object? servingSize = freezed,Object? quantity = freezed,Object? productQuantity = freezed,Object? energyKcal = freezed,Object? proteinG = freezed,Object? carbsG = freezed,Object? fatG = freezed,Object? fiberG = freezed,Object? saltG = freezed,Object? nutriscoreGrade = freezed,Object? imageUrl = freezed,Object? offNutritionImageUrl = freezed,Object? offIngredientsImageUrl = freezed,Object? offProductImageUrl = freezed,Object? languageCode = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,lastRefreshedAt: null == lastRefreshedAt ? _self.lastRefreshedAt : lastRefreshedAt // ignore: cast_nullable_to_non_nullable
as int,nextRefreshAt: null == nextRefreshAt ? _self.nextRefreshAt : nextRefreshAt // ignore: cast_nullable_to_non_nullable
as int,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,categoriesHierarchy: freezed == categoriesHierarchy ? _self.categoriesHierarchy : categoriesHierarchy // ignore: cast_nullable_to_non_nullable
as List<String>?,ingredients: freezed == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as String?,servingSize: freezed == servingSize ? _self.servingSize : servingSize // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,productQuantity: freezed == productQuantity ? _self.productQuantity : productQuantity // ignore: cast_nullable_to_non_nullable
as double?,energyKcal: freezed == energyKcal ? _self.energyKcal : energyKcal // ignore: cast_nullable_to_non_nullable
as double?,proteinG: freezed == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double?,carbsG: freezed == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double?,fatG: freezed == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double?,fiberG: freezed == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double?,saltG: freezed == saltG ? _self.saltG : saltG // ignore: cast_nullable_to_non_nullable
as double?,nutriscoreGrade: freezed == nutriscoreGrade ? _self.nutriscoreGrade : nutriscoreGrade // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,offNutritionImageUrl: freezed == offNutritionImageUrl ? _self.offNutritionImageUrl : offNutritionImageUrl // ignore: cast_nullable_to_non_nullable
as String?,offIngredientsImageUrl: freezed == offIngredientsImageUrl ? _self.offIngredientsImageUrl : offIngredientsImageUrl // ignore: cast_nullable_to_non_nullable
as String?,offProductImageUrl: freezed == offProductImageUrl ? _self.offProductImageUrl : offProductImageUrl // ignore: cast_nullable_to_non_nullable
as String?,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductCacheEntry].
extension ProductCacheEntryPatterns on ProductCacheEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCacheEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCacheEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCacheEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProductCacheEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCacheEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCacheEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String barcode,  String name,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt, @JsonKey(includeIfNull: false)  String? brand, @JsonKey(includeIfNull: false)  String? category, @JsonKey(includeIfNull: false)  List<String>? categoriesHierarchy, @JsonKey(includeIfNull: false)  String? ingredients, @JsonKey(includeIfNull: false)  String? servingSize, @JsonKey(includeIfNull: false)  String? quantity, @JsonKey(includeIfNull: false)  double? productQuantity, @JsonKey(includeIfNull: false)  double? energyKcal, @JsonKey(includeIfNull: false)  double? proteinG, @JsonKey(includeIfNull: false)  double? carbsG, @JsonKey(includeIfNull: false)  double? fatG, @JsonKey(includeIfNull: false)  double? fiberG, @JsonKey(includeIfNull: false)  double? saltG, @JsonKey(includeIfNull: false)  String? nutriscoreGrade, @JsonKey(includeIfNull: false)  String? imageUrl, @JsonKey(includeIfNull: false)  String? offNutritionImageUrl, @JsonKey(includeIfNull: false)  String? offIngredientsImageUrl, @JsonKey(includeIfNull: false)  String? offProductImageUrl,  String languageCode,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCacheEntry() when $default != null:
return $default(_that.barcode,_that.name,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.brand,_that.category,_that.categoriesHierarchy,_that.ingredients,_that.servingSize,_that.quantity,_that.productQuantity,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.nutriscoreGrade,_that.imageUrl,_that.offNutritionImageUrl,_that.offIngredientsImageUrl,_that.offProductImageUrl,_that.languageCode,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String barcode,  String name,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt, @JsonKey(includeIfNull: false)  String? brand, @JsonKey(includeIfNull: false)  String? category, @JsonKey(includeIfNull: false)  List<String>? categoriesHierarchy, @JsonKey(includeIfNull: false)  String? ingredients, @JsonKey(includeIfNull: false)  String? servingSize, @JsonKey(includeIfNull: false)  String? quantity, @JsonKey(includeIfNull: false)  double? productQuantity, @JsonKey(includeIfNull: false)  double? energyKcal, @JsonKey(includeIfNull: false)  double? proteinG, @JsonKey(includeIfNull: false)  double? carbsG, @JsonKey(includeIfNull: false)  double? fatG, @JsonKey(includeIfNull: false)  double? fiberG, @JsonKey(includeIfNull: false)  double? saltG, @JsonKey(includeIfNull: false)  String? nutriscoreGrade, @JsonKey(includeIfNull: false)  String? imageUrl, @JsonKey(includeIfNull: false)  String? offNutritionImageUrl, @JsonKey(includeIfNull: false)  String? offIngredientsImageUrl, @JsonKey(includeIfNull: false)  String? offProductImageUrl,  String languageCode,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _ProductCacheEntry():
return $default(_that.barcode,_that.name,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.brand,_that.category,_that.categoriesHierarchy,_that.ingredients,_that.servingSize,_that.quantity,_that.productQuantity,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.nutriscoreGrade,_that.imageUrl,_that.offNutritionImageUrl,_that.offIngredientsImageUrl,_that.offProductImageUrl,_that.languageCode,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String barcode,  String name,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt, @JsonKey(includeIfNull: false)  String? brand, @JsonKey(includeIfNull: false)  String? category, @JsonKey(includeIfNull: false)  List<String>? categoriesHierarchy, @JsonKey(includeIfNull: false)  String? ingredients, @JsonKey(includeIfNull: false)  String? servingSize, @JsonKey(includeIfNull: false)  String? quantity, @JsonKey(includeIfNull: false)  double? productQuantity, @JsonKey(includeIfNull: false)  double? energyKcal, @JsonKey(includeIfNull: false)  double? proteinG, @JsonKey(includeIfNull: false)  double? carbsG, @JsonKey(includeIfNull: false)  double? fatG, @JsonKey(includeIfNull: false)  double? fiberG, @JsonKey(includeIfNull: false)  double? saltG, @JsonKey(includeIfNull: false)  String? nutriscoreGrade, @JsonKey(includeIfNull: false)  String? imageUrl, @JsonKey(includeIfNull: false)  String? offNutritionImageUrl, @JsonKey(includeIfNull: false)  String? offIngredientsImageUrl, @JsonKey(includeIfNull: false)  String? offProductImageUrl,  String languageCode,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _ProductCacheEntry() when $default != null:
return $default(_that.barcode,_that.name,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.brand,_that.category,_that.categoriesHierarchy,_that.ingredients,_that.servingSize,_that.quantity,_that.productQuantity,_that.energyKcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.saltG,_that.nutriscoreGrade,_that.imageUrl,_that.offNutritionImageUrl,_that.offIngredientsImageUrl,_that.offProductImageUrl,_that.languageCode,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductCacheEntry extends ProductCacheEntry {
  const _ProductCacheEntry({required this.barcode, required this.name, required this.createdAt, required this.lastRefreshedAt, required this.nextRefreshAt, @JsonKey(includeIfNull: false) this.brand, @JsonKey(includeIfNull: false) this.category, @JsonKey(includeIfNull: false) final  List<String>? categoriesHierarchy, @JsonKey(includeIfNull: false) this.ingredients, @JsonKey(includeIfNull: false) this.servingSize, @JsonKey(includeIfNull: false) this.quantity, @JsonKey(includeIfNull: false) this.productQuantity, @JsonKey(includeIfNull: false) this.energyKcal, @JsonKey(includeIfNull: false) this.proteinG, @JsonKey(includeIfNull: false) this.carbsG, @JsonKey(includeIfNull: false) this.fatG, @JsonKey(includeIfNull: false) this.fiberG, @JsonKey(includeIfNull: false) this.saltG, @JsonKey(includeIfNull: false) this.nutriscoreGrade, @JsonKey(includeIfNull: false) this.imageUrl, @JsonKey(includeIfNull: false) this.offNutritionImageUrl, @JsonKey(includeIfNull: false) this.offIngredientsImageUrl, @JsonKey(includeIfNull: false) this.offProductImageUrl, this.languageCode = 'en', this.schemaVersion = 1}): _categoriesHierarchy = categoriesHierarchy,super._();
  factory _ProductCacheEntry.fromJson(Map<String, dynamic> json) => _$ProductCacheEntryFromJson(json);

/// The barcode (EAN-13, UPC, etc.) used as the Firestore document ID.
@override final  String barcode;
/// The product name as returned by Open Food Facts.
@override final  String name;
/// Epoch timestamp (ms) of when this entry was first created.
@override final  int createdAt;
/// Epoch timestamp (ms) of when this entry was last refreshed.
@override final  int lastRefreshedAt;
/// Epoch timestamp (ms) of when this entry should be refreshed next.
@override final  int nextRefreshAt;
/// The brand name(s), often comma-separated.
@override@JsonKey(includeIfNull: false) final  String? brand;
/// The product category (e.g. "Spreads, Sweet spreads").
@override@JsonKey(includeIfNull: false) final  String? category;
/// The OFF taxonomy hierarchy, broadest to most specific.
 final  List<String>? _categoriesHierarchy;
/// The OFF taxonomy hierarchy, broadest to most specific.
@override@JsonKey(includeIfNull: false) List<String>? get categoriesHierarchy {
  final value = _categoriesHierarchy;
  if (value == null) return null;
  if (_categoriesHierarchy is EqualUnmodifiableListView) return _categoriesHierarchy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// The full ingredients list as plain text.
@override@JsonKey(includeIfNull: false) final  String? ingredients;
/// The suggested serving size (e.g. "15 g").
@override@JsonKey(includeIfNull: false) final  String? servingSize;
/// The display quantity as printed on packaging (e.g. "500 ml").
@override@JsonKey(includeIfNull: false) final  String? quantity;
/// Normalized numeric product quantity in g or ml.
@override@JsonKey(includeIfNull: false) final  double? productQuantity;
/// Energy in kilocalories per 100 g.
@override@JsonKey(includeIfNull: false) final  double? energyKcal;
/// Protein in grams per 100 g.
@override@JsonKey(includeIfNull: false) final  double? proteinG;
/// Carbohydrates in grams per 100 g.
@override@JsonKey(includeIfNull: false) final  double? carbsG;
/// Fat in grams per 100 g.
@override@JsonKey(includeIfNull: false) final  double? fatG;
/// Fiber in grams per 100 g.
@override@JsonKey(includeIfNull: false) final  double? fiberG;
/// Salt in grams per 100 g.
@override@JsonKey(includeIfNull: false) final  double? saltG;
/// The Nutri-Score grade ('a' through 'e'), or 'not-applicable'.
@override@JsonKey(includeIfNull: false) final  String? nutriscoreGrade;
/// URL to the product's front image on the OFF CDN.
@override@JsonKey(includeIfNull: false) final  String? imageUrl;
/// URL to the nutrition facts table image on the OFF CDN.
@override@JsonKey(includeIfNull: false) final  String? offNutritionImageUrl;
/// URL to the ingredients list image on the OFF CDN.
@override@JsonKey(includeIfNull: false) final  String? offIngredientsImageUrl;
/// URL to the product packaging image on the OFF CDN.
@override@JsonKey(includeIfNull: false) final  String? offProductImageUrl;
/// The locale used when fetching this product (e.g. 'en', 'pt').
@override@JsonKey() final  String languageCode;
/// Schema version for forward compatibility.
@override@JsonKey() final  int schemaVersion;

/// Create a copy of ProductCacheEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCacheEntryCopyWith<_ProductCacheEntry> get copyWith => __$ProductCacheEntryCopyWithImpl<_ProductCacheEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductCacheEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCacheEntry&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastRefreshedAt, lastRefreshedAt) || other.lastRefreshedAt == lastRefreshedAt)&&(identical(other.nextRefreshAt, nextRefreshAt) || other.nextRefreshAt == nextRefreshAt)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._categoriesHierarchy, _categoriesHierarchy)&&(identical(other.ingredients, ingredients) || other.ingredients == ingredients)&&(identical(other.servingSize, servingSize) || other.servingSize == servingSize)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.productQuantity, productQuantity) || other.productQuantity == productQuantity)&&(identical(other.energyKcal, energyKcal) || other.energyKcal == energyKcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG)&&(identical(other.saltG, saltG) || other.saltG == saltG)&&(identical(other.nutriscoreGrade, nutriscoreGrade) || other.nutriscoreGrade == nutriscoreGrade)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.offNutritionImageUrl, offNutritionImageUrl) || other.offNutritionImageUrl == offNutritionImageUrl)&&(identical(other.offIngredientsImageUrl, offIngredientsImageUrl) || other.offIngredientsImageUrl == offIngredientsImageUrl)&&(identical(other.offProductImageUrl, offProductImageUrl) || other.offProductImageUrl == offProductImageUrl)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,barcode,name,createdAt,lastRefreshedAt,nextRefreshAt,brand,category,const DeepCollectionEquality().hash(_categoriesHierarchy),ingredients,servingSize,quantity,productQuantity,energyKcal,proteinG,carbsG,fatG,fiberG,saltG,nutriscoreGrade,imageUrl,offNutritionImageUrl,offIngredientsImageUrl,offProductImageUrl,languageCode,schemaVersion]);

@override
String toString() {
  return 'ProductCacheEntry(barcode: $barcode, name: $name, createdAt: $createdAt, lastRefreshedAt: $lastRefreshedAt, nextRefreshAt: $nextRefreshAt, brand: $brand, category: $category, categoriesHierarchy: $categoriesHierarchy, ingredients: $ingredients, servingSize: $servingSize, quantity: $quantity, productQuantity: $productQuantity, energyKcal: $energyKcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG, saltG: $saltG, nutriscoreGrade: $nutriscoreGrade, imageUrl: $imageUrl, offNutritionImageUrl: $offNutritionImageUrl, offIngredientsImageUrl: $offIngredientsImageUrl, offProductImageUrl: $offProductImageUrl, languageCode: $languageCode, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$ProductCacheEntryCopyWith<$Res> implements $ProductCacheEntryCopyWith<$Res> {
  factory _$ProductCacheEntryCopyWith(_ProductCacheEntry value, $Res Function(_ProductCacheEntry) _then) = __$ProductCacheEntryCopyWithImpl;
@override @useResult
$Res call({
 String barcode, String name, int createdAt, int lastRefreshedAt, int nextRefreshAt,@JsonKey(includeIfNull: false) String? brand,@JsonKey(includeIfNull: false) String? category,@JsonKey(includeIfNull: false) List<String>? categoriesHierarchy,@JsonKey(includeIfNull: false) String? ingredients,@JsonKey(includeIfNull: false) String? servingSize,@JsonKey(includeIfNull: false) String? quantity,@JsonKey(includeIfNull: false) double? productQuantity,@JsonKey(includeIfNull: false) double? energyKcal,@JsonKey(includeIfNull: false) double? proteinG,@JsonKey(includeIfNull: false) double? carbsG,@JsonKey(includeIfNull: false) double? fatG,@JsonKey(includeIfNull: false) double? fiberG,@JsonKey(includeIfNull: false) double? saltG,@JsonKey(includeIfNull: false) String? nutriscoreGrade,@JsonKey(includeIfNull: false) String? imageUrl,@JsonKey(includeIfNull: false) String? offNutritionImageUrl,@JsonKey(includeIfNull: false) String? offIngredientsImageUrl,@JsonKey(includeIfNull: false) String? offProductImageUrl, String languageCode, int schemaVersion
});




}
/// @nodoc
class __$ProductCacheEntryCopyWithImpl<$Res>
    implements _$ProductCacheEntryCopyWith<$Res> {
  __$ProductCacheEntryCopyWithImpl(this._self, this._then);

  final _ProductCacheEntry _self;
  final $Res Function(_ProductCacheEntry) _then;

/// Create a copy of ProductCacheEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? barcode = null,Object? name = null,Object? createdAt = null,Object? lastRefreshedAt = null,Object? nextRefreshAt = null,Object? brand = freezed,Object? category = freezed,Object? categoriesHierarchy = freezed,Object? ingredients = freezed,Object? servingSize = freezed,Object? quantity = freezed,Object? productQuantity = freezed,Object? energyKcal = freezed,Object? proteinG = freezed,Object? carbsG = freezed,Object? fatG = freezed,Object? fiberG = freezed,Object? saltG = freezed,Object? nutriscoreGrade = freezed,Object? imageUrl = freezed,Object? offNutritionImageUrl = freezed,Object? offIngredientsImageUrl = freezed,Object? offProductImageUrl = freezed,Object? languageCode = null,Object? schemaVersion = null,}) {
  return _then(_ProductCacheEntry(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,lastRefreshedAt: null == lastRefreshedAt ? _self.lastRefreshedAt : lastRefreshedAt // ignore: cast_nullable_to_non_nullable
as int,nextRefreshAt: null == nextRefreshAt ? _self.nextRefreshAt : nextRefreshAt // ignore: cast_nullable_to_non_nullable
as int,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,categoriesHierarchy: freezed == categoriesHierarchy ? _self._categoriesHierarchy : categoriesHierarchy // ignore: cast_nullable_to_non_nullable
as List<String>?,ingredients: freezed == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as String?,servingSize: freezed == servingSize ? _self.servingSize : servingSize // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,productQuantity: freezed == productQuantity ? _self.productQuantity : productQuantity // ignore: cast_nullable_to_non_nullable
as double?,energyKcal: freezed == energyKcal ? _self.energyKcal : energyKcal // ignore: cast_nullable_to_non_nullable
as double?,proteinG: freezed == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double?,carbsG: freezed == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double?,fatG: freezed == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double?,fiberG: freezed == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double?,saltG: freezed == saltG ? _self.saltG : saltG // ignore: cast_nullable_to_non_nullable
as double?,nutriscoreGrade: freezed == nutriscoreGrade ? _self.nutriscoreGrade : nutriscoreGrade // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,offNutritionImageUrl: freezed == offNutritionImageUrl ? _self.offNutritionImageUrl : offNutritionImageUrl // ignore: cast_nullable_to_non_nullable
as String?,offIngredientsImageUrl: freezed == offIngredientsImageUrl ? _self.offIngredientsImageUrl : offIngredientsImageUrl // ignore: cast_nullable_to_non_nullable
as String?,offProductImageUrl: freezed == offProductImageUrl ? _self.offProductImageUrl : offProductImageUrl // ignore: cast_nullable_to_non_nullable
as String?,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
