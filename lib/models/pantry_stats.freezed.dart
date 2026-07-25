// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pantry_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PantryStats {

 int get totalProducts; int get totalItems; double get averageNutriscoreNumeric; int get expiredCount; int get expiringSoonCount; int get goodCount; int get addedThisWeek; int get addedThisMonth; List<WeeklyCount> get weeklyAdditions; Map<String, int> get itemsByLocation; List<CategoryCount> get categoriesTop; Map<String, int> get nutriscoreDistribution; Map<String, int> get itemsBySource; PhotoStats get localPhotos; PhotoStats get offPhotos; double get totalValue; double get averagePrice; int get pricedItemCount; List<MonthlySpending> get monthlySpending; List<StoreSpending> get storeSpending; List<StoreNutriscore> get nutriscoreByStore; int get mealsCooked; double get totalRecipeCost; double get averageRecipeNutriScore; String get mostCookedRecipe;
/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PantryStatsCopyWith<PantryStats> get copyWith => _$PantryStatsCopyWithImpl<PantryStats>(this as PantryStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PantryStats&&(identical(other.totalProducts, totalProducts) || other.totalProducts == totalProducts)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.averageNutriscoreNumeric, averageNutriscoreNumeric) || other.averageNutriscoreNumeric == averageNutriscoreNumeric)&&(identical(other.expiredCount, expiredCount) || other.expiredCount == expiredCount)&&(identical(other.expiringSoonCount, expiringSoonCount) || other.expiringSoonCount == expiringSoonCount)&&(identical(other.goodCount, goodCount) || other.goodCount == goodCount)&&(identical(other.addedThisWeek, addedThisWeek) || other.addedThisWeek == addedThisWeek)&&(identical(other.addedThisMonth, addedThisMonth) || other.addedThisMonth == addedThisMonth)&&const DeepCollectionEquality().equals(other.weeklyAdditions, weeklyAdditions)&&const DeepCollectionEquality().equals(other.itemsByLocation, itemsByLocation)&&const DeepCollectionEquality().equals(other.categoriesTop, categoriesTop)&&const DeepCollectionEquality().equals(other.nutriscoreDistribution, nutriscoreDistribution)&&const DeepCollectionEquality().equals(other.itemsBySource, itemsBySource)&&(identical(other.localPhotos, localPhotos) || other.localPhotos == localPhotos)&&(identical(other.offPhotos, offPhotos) || other.offPhotos == offPhotos)&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.averagePrice, averagePrice) || other.averagePrice == averagePrice)&&(identical(other.pricedItemCount, pricedItemCount) || other.pricedItemCount == pricedItemCount)&&const DeepCollectionEquality().equals(other.monthlySpending, monthlySpending)&&const DeepCollectionEquality().equals(other.storeSpending, storeSpending)&&const DeepCollectionEquality().equals(other.nutriscoreByStore, nutriscoreByStore)&&(identical(other.mealsCooked, mealsCooked) || other.mealsCooked == mealsCooked)&&(identical(other.totalRecipeCost, totalRecipeCost) || other.totalRecipeCost == totalRecipeCost)&&(identical(other.averageRecipeNutriScore, averageRecipeNutriScore) || other.averageRecipeNutriScore == averageRecipeNutriScore)&&(identical(other.mostCookedRecipe, mostCookedRecipe) || other.mostCookedRecipe == mostCookedRecipe));
}


@override
int get hashCode => Object.hashAll([runtimeType,totalProducts,totalItems,averageNutriscoreNumeric,expiredCount,expiringSoonCount,goodCount,addedThisWeek,addedThisMonth,const DeepCollectionEquality().hash(weeklyAdditions),const DeepCollectionEquality().hash(itemsByLocation),const DeepCollectionEquality().hash(categoriesTop),const DeepCollectionEquality().hash(nutriscoreDistribution),const DeepCollectionEquality().hash(itemsBySource),localPhotos,offPhotos,totalValue,averagePrice,pricedItemCount,const DeepCollectionEquality().hash(monthlySpending),const DeepCollectionEquality().hash(storeSpending),const DeepCollectionEquality().hash(nutriscoreByStore),mealsCooked,totalRecipeCost,averageRecipeNutriScore,mostCookedRecipe]);

@override
String toString() {
  return 'PantryStats(totalProducts: $totalProducts, totalItems: $totalItems, averageNutriscoreNumeric: $averageNutriscoreNumeric, expiredCount: $expiredCount, expiringSoonCount: $expiringSoonCount, goodCount: $goodCount, addedThisWeek: $addedThisWeek, addedThisMonth: $addedThisMonth, weeklyAdditions: $weeklyAdditions, itemsByLocation: $itemsByLocation, categoriesTop: $categoriesTop, nutriscoreDistribution: $nutriscoreDistribution, itemsBySource: $itemsBySource, localPhotos: $localPhotos, offPhotos: $offPhotos, totalValue: $totalValue, averagePrice: $averagePrice, pricedItemCount: $pricedItemCount, monthlySpending: $monthlySpending, storeSpending: $storeSpending, nutriscoreByStore: $nutriscoreByStore, mealsCooked: $mealsCooked, totalRecipeCost: $totalRecipeCost, averageRecipeNutriScore: $averageRecipeNutriScore, mostCookedRecipe: $mostCookedRecipe)';
}


}

/// @nodoc
abstract mixin class $PantryStatsCopyWith<$Res>  {
  factory $PantryStatsCopyWith(PantryStats value, $Res Function(PantryStats) _then) = _$PantryStatsCopyWithImpl;
@useResult
$Res call({
 int totalProducts, int totalItems, double averageNutriscoreNumeric, int expiredCount, int expiringSoonCount, int goodCount, int addedThisWeek, int addedThisMonth, List<WeeklyCount> weeklyAdditions, Map<String, int> itemsByLocation, List<CategoryCount> categoriesTop, Map<String, int> nutriscoreDistribution, Map<String, int> itemsBySource, PhotoStats localPhotos, PhotoStats offPhotos, double totalValue, double averagePrice, int pricedItemCount, List<MonthlySpending> monthlySpending, List<StoreSpending> storeSpending, List<StoreNutriscore> nutriscoreByStore, int mealsCooked, double totalRecipeCost, double averageRecipeNutriScore, String mostCookedRecipe
});


$PhotoStatsCopyWith<$Res> get localPhotos;$PhotoStatsCopyWith<$Res> get offPhotos;

}
/// @nodoc
class _$PantryStatsCopyWithImpl<$Res>
    implements $PantryStatsCopyWith<$Res> {
  _$PantryStatsCopyWithImpl(this._self, this._then);

  final PantryStats _self;
  final $Res Function(PantryStats) _then;

/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalProducts = null,Object? totalItems = null,Object? averageNutriscoreNumeric = null,Object? expiredCount = null,Object? expiringSoonCount = null,Object? goodCount = null,Object? addedThisWeek = null,Object? addedThisMonth = null,Object? weeklyAdditions = null,Object? itemsByLocation = null,Object? categoriesTop = null,Object? nutriscoreDistribution = null,Object? itemsBySource = null,Object? localPhotos = null,Object? offPhotos = null,Object? totalValue = null,Object? averagePrice = null,Object? pricedItemCount = null,Object? monthlySpending = null,Object? storeSpending = null,Object? nutriscoreByStore = null,Object? mealsCooked = null,Object? totalRecipeCost = null,Object? averageRecipeNutriScore = null,Object? mostCookedRecipe = null,}) {
  return _then(_self.copyWith(
totalProducts: null == totalProducts ? _self.totalProducts : totalProducts // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,averageNutriscoreNumeric: null == averageNutriscoreNumeric ? _self.averageNutriscoreNumeric : averageNutriscoreNumeric // ignore: cast_nullable_to_non_nullable
as double,expiredCount: null == expiredCount ? _self.expiredCount : expiredCount // ignore: cast_nullable_to_non_nullable
as int,expiringSoonCount: null == expiringSoonCount ? _self.expiringSoonCount : expiringSoonCount // ignore: cast_nullable_to_non_nullable
as int,goodCount: null == goodCount ? _self.goodCount : goodCount // ignore: cast_nullable_to_non_nullable
as int,addedThisWeek: null == addedThisWeek ? _self.addedThisWeek : addedThisWeek // ignore: cast_nullable_to_non_nullable
as int,addedThisMonth: null == addedThisMonth ? _self.addedThisMonth : addedThisMonth // ignore: cast_nullable_to_non_nullable
as int,weeklyAdditions: null == weeklyAdditions ? _self.weeklyAdditions : weeklyAdditions // ignore: cast_nullable_to_non_nullable
as List<WeeklyCount>,itemsByLocation: null == itemsByLocation ? _self.itemsByLocation : itemsByLocation // ignore: cast_nullable_to_non_nullable
as Map<String, int>,categoriesTop: null == categoriesTop ? _self.categoriesTop : categoriesTop // ignore: cast_nullable_to_non_nullable
as List<CategoryCount>,nutriscoreDistribution: null == nutriscoreDistribution ? _self.nutriscoreDistribution : nutriscoreDistribution // ignore: cast_nullable_to_non_nullable
as Map<String, int>,itemsBySource: null == itemsBySource ? _self.itemsBySource : itemsBySource // ignore: cast_nullable_to_non_nullable
as Map<String, int>,localPhotos: null == localPhotos ? _self.localPhotos : localPhotos // ignore: cast_nullable_to_non_nullable
as PhotoStats,offPhotos: null == offPhotos ? _self.offPhotos : offPhotos // ignore: cast_nullable_to_non_nullable
as PhotoStats,totalValue: null == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double,averagePrice: null == averagePrice ? _self.averagePrice : averagePrice // ignore: cast_nullable_to_non_nullable
as double,pricedItemCount: null == pricedItemCount ? _self.pricedItemCount : pricedItemCount // ignore: cast_nullable_to_non_nullable
as int,monthlySpending: null == monthlySpending ? _self.monthlySpending : monthlySpending // ignore: cast_nullable_to_non_nullable
as List<MonthlySpending>,storeSpending: null == storeSpending ? _self.storeSpending : storeSpending // ignore: cast_nullable_to_non_nullable
as List<StoreSpending>,nutriscoreByStore: null == nutriscoreByStore ? _self.nutriscoreByStore : nutriscoreByStore // ignore: cast_nullable_to_non_nullable
as List<StoreNutriscore>,mealsCooked: null == mealsCooked ? _self.mealsCooked : mealsCooked // ignore: cast_nullable_to_non_nullable
as int,totalRecipeCost: null == totalRecipeCost ? _self.totalRecipeCost : totalRecipeCost // ignore: cast_nullable_to_non_nullable
as double,averageRecipeNutriScore: null == averageRecipeNutriScore ? _self.averageRecipeNutriScore : averageRecipeNutriScore // ignore: cast_nullable_to_non_nullable
as double,mostCookedRecipe: null == mostCookedRecipe ? _self.mostCookedRecipe : mostCookedRecipe // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhotoStatsCopyWith<$Res> get localPhotos {
  
  return $PhotoStatsCopyWith<$Res>(_self.localPhotos, (value) {
    return _then(_self.copyWith(localPhotos: value));
  });
}/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhotoStatsCopyWith<$Res> get offPhotos {
  
  return $PhotoStatsCopyWith<$Res>(_self.offPhotos, (value) {
    return _then(_self.copyWith(offPhotos: value));
  });
}
}


/// Adds pattern-matching-related methods to [PantryStats].
extension PantryStatsPatterns on PantryStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PantryStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PantryStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PantryStats value)  $default,){
final _that = this;
switch (_that) {
case _PantryStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PantryStats value)?  $default,){
final _that = this;
switch (_that) {
case _PantryStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalProducts,  int totalItems,  double averageNutriscoreNumeric,  int expiredCount,  int expiringSoonCount,  int goodCount,  int addedThisWeek,  int addedThisMonth,  List<WeeklyCount> weeklyAdditions,  Map<String, int> itemsByLocation,  List<CategoryCount> categoriesTop,  Map<String, int> nutriscoreDistribution,  Map<String, int> itemsBySource,  PhotoStats localPhotos,  PhotoStats offPhotos,  double totalValue,  double averagePrice,  int pricedItemCount,  List<MonthlySpending> monthlySpending,  List<StoreSpending> storeSpending,  List<StoreNutriscore> nutriscoreByStore,  int mealsCooked,  double totalRecipeCost,  double averageRecipeNutriScore,  String mostCookedRecipe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PantryStats() when $default != null:
return $default(_that.totalProducts,_that.totalItems,_that.averageNutriscoreNumeric,_that.expiredCount,_that.expiringSoonCount,_that.goodCount,_that.addedThisWeek,_that.addedThisMonth,_that.weeklyAdditions,_that.itemsByLocation,_that.categoriesTop,_that.nutriscoreDistribution,_that.itemsBySource,_that.localPhotos,_that.offPhotos,_that.totalValue,_that.averagePrice,_that.pricedItemCount,_that.monthlySpending,_that.storeSpending,_that.nutriscoreByStore,_that.mealsCooked,_that.totalRecipeCost,_that.averageRecipeNutriScore,_that.mostCookedRecipe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalProducts,  int totalItems,  double averageNutriscoreNumeric,  int expiredCount,  int expiringSoonCount,  int goodCount,  int addedThisWeek,  int addedThisMonth,  List<WeeklyCount> weeklyAdditions,  Map<String, int> itemsByLocation,  List<CategoryCount> categoriesTop,  Map<String, int> nutriscoreDistribution,  Map<String, int> itemsBySource,  PhotoStats localPhotos,  PhotoStats offPhotos,  double totalValue,  double averagePrice,  int pricedItemCount,  List<MonthlySpending> monthlySpending,  List<StoreSpending> storeSpending,  List<StoreNutriscore> nutriscoreByStore,  int mealsCooked,  double totalRecipeCost,  double averageRecipeNutriScore,  String mostCookedRecipe)  $default,) {final _that = this;
switch (_that) {
case _PantryStats():
return $default(_that.totalProducts,_that.totalItems,_that.averageNutriscoreNumeric,_that.expiredCount,_that.expiringSoonCount,_that.goodCount,_that.addedThisWeek,_that.addedThisMonth,_that.weeklyAdditions,_that.itemsByLocation,_that.categoriesTop,_that.nutriscoreDistribution,_that.itemsBySource,_that.localPhotos,_that.offPhotos,_that.totalValue,_that.averagePrice,_that.pricedItemCount,_that.monthlySpending,_that.storeSpending,_that.nutriscoreByStore,_that.mealsCooked,_that.totalRecipeCost,_that.averageRecipeNutriScore,_that.mostCookedRecipe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalProducts,  int totalItems,  double averageNutriscoreNumeric,  int expiredCount,  int expiringSoonCount,  int goodCount,  int addedThisWeek,  int addedThisMonth,  List<WeeklyCount> weeklyAdditions,  Map<String, int> itemsByLocation,  List<CategoryCount> categoriesTop,  Map<String, int> nutriscoreDistribution,  Map<String, int> itemsBySource,  PhotoStats localPhotos,  PhotoStats offPhotos,  double totalValue,  double averagePrice,  int pricedItemCount,  List<MonthlySpending> monthlySpending,  List<StoreSpending> storeSpending,  List<StoreNutriscore> nutriscoreByStore,  int mealsCooked,  double totalRecipeCost,  double averageRecipeNutriScore,  String mostCookedRecipe)?  $default,) {final _that = this;
switch (_that) {
case _PantryStats() when $default != null:
return $default(_that.totalProducts,_that.totalItems,_that.averageNutriscoreNumeric,_that.expiredCount,_that.expiringSoonCount,_that.goodCount,_that.addedThisWeek,_that.addedThisMonth,_that.weeklyAdditions,_that.itemsByLocation,_that.categoriesTop,_that.nutriscoreDistribution,_that.itemsBySource,_that.localPhotos,_that.offPhotos,_that.totalValue,_that.averagePrice,_that.pricedItemCount,_that.monthlySpending,_that.storeSpending,_that.nutriscoreByStore,_that.mealsCooked,_that.totalRecipeCost,_that.averageRecipeNutriScore,_that.mostCookedRecipe);case _:
  return null;

}
}

}

/// @nodoc


class _PantryStats implements PantryStats {
  const _PantryStats({required this.totalProducts, required this.totalItems, required this.averageNutriscoreNumeric, required this.expiredCount, required this.expiringSoonCount, required this.goodCount, required this.addedThisWeek, required this.addedThisMonth, required final  List<WeeklyCount> weeklyAdditions, required final  Map<String, int> itemsByLocation, required final  List<CategoryCount> categoriesTop, required final  Map<String, int> nutriscoreDistribution, required final  Map<String, int> itemsBySource, required this.localPhotos, required this.offPhotos, this.totalValue = 0, this.averagePrice = 0, this.pricedItemCount = 0, final  List<MonthlySpending> monthlySpending = const [], final  List<StoreSpending> storeSpending = const [], final  List<StoreNutriscore> nutriscoreByStore = const [], this.mealsCooked = 0, this.totalRecipeCost = 0, this.averageRecipeNutriScore = 0, this.mostCookedRecipe = ''}): _weeklyAdditions = weeklyAdditions,_itemsByLocation = itemsByLocation,_categoriesTop = categoriesTop,_nutriscoreDistribution = nutriscoreDistribution,_itemsBySource = itemsBySource,_monthlySpending = monthlySpending,_storeSpending = storeSpending,_nutriscoreByStore = nutriscoreByStore;
  

@override final  int totalProducts;
@override final  int totalItems;
@override final  double averageNutriscoreNumeric;
@override final  int expiredCount;
@override final  int expiringSoonCount;
@override final  int goodCount;
@override final  int addedThisWeek;
@override final  int addedThisMonth;
 final  List<WeeklyCount> _weeklyAdditions;
@override List<WeeklyCount> get weeklyAdditions {
  if (_weeklyAdditions is EqualUnmodifiableListView) return _weeklyAdditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weeklyAdditions);
}

 final  Map<String, int> _itemsByLocation;
@override Map<String, int> get itemsByLocation {
  if (_itemsByLocation is EqualUnmodifiableMapView) return _itemsByLocation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_itemsByLocation);
}

 final  List<CategoryCount> _categoriesTop;
@override List<CategoryCount> get categoriesTop {
  if (_categoriesTop is EqualUnmodifiableListView) return _categoriesTop;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoriesTop);
}

 final  Map<String, int> _nutriscoreDistribution;
@override Map<String, int> get nutriscoreDistribution {
  if (_nutriscoreDistribution is EqualUnmodifiableMapView) return _nutriscoreDistribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nutriscoreDistribution);
}

 final  Map<String, int> _itemsBySource;
@override Map<String, int> get itemsBySource {
  if (_itemsBySource is EqualUnmodifiableMapView) return _itemsBySource;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_itemsBySource);
}

@override final  PhotoStats localPhotos;
@override final  PhotoStats offPhotos;
@override@JsonKey() final  double totalValue;
@override@JsonKey() final  double averagePrice;
@override@JsonKey() final  int pricedItemCount;
 final  List<MonthlySpending> _monthlySpending;
@override@JsonKey() List<MonthlySpending> get monthlySpending {
  if (_monthlySpending is EqualUnmodifiableListView) return _monthlySpending;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlySpending);
}

 final  List<StoreSpending> _storeSpending;
@override@JsonKey() List<StoreSpending> get storeSpending {
  if (_storeSpending is EqualUnmodifiableListView) return _storeSpending;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_storeSpending);
}

 final  List<StoreNutriscore> _nutriscoreByStore;
@override@JsonKey() List<StoreNutriscore> get nutriscoreByStore {
  if (_nutriscoreByStore is EqualUnmodifiableListView) return _nutriscoreByStore;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nutriscoreByStore);
}

@override@JsonKey() final  int mealsCooked;
@override@JsonKey() final  double totalRecipeCost;
@override@JsonKey() final  double averageRecipeNutriScore;
@override@JsonKey() final  String mostCookedRecipe;

/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PantryStatsCopyWith<_PantryStats> get copyWith => __$PantryStatsCopyWithImpl<_PantryStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PantryStats&&(identical(other.totalProducts, totalProducts) || other.totalProducts == totalProducts)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.averageNutriscoreNumeric, averageNutriscoreNumeric) || other.averageNutriscoreNumeric == averageNutriscoreNumeric)&&(identical(other.expiredCount, expiredCount) || other.expiredCount == expiredCount)&&(identical(other.expiringSoonCount, expiringSoonCount) || other.expiringSoonCount == expiringSoonCount)&&(identical(other.goodCount, goodCount) || other.goodCount == goodCount)&&(identical(other.addedThisWeek, addedThisWeek) || other.addedThisWeek == addedThisWeek)&&(identical(other.addedThisMonth, addedThisMonth) || other.addedThisMonth == addedThisMonth)&&const DeepCollectionEquality().equals(other._weeklyAdditions, _weeklyAdditions)&&const DeepCollectionEquality().equals(other._itemsByLocation, _itemsByLocation)&&const DeepCollectionEquality().equals(other._categoriesTop, _categoriesTop)&&const DeepCollectionEquality().equals(other._nutriscoreDistribution, _nutriscoreDistribution)&&const DeepCollectionEquality().equals(other._itemsBySource, _itemsBySource)&&(identical(other.localPhotos, localPhotos) || other.localPhotos == localPhotos)&&(identical(other.offPhotos, offPhotos) || other.offPhotos == offPhotos)&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.averagePrice, averagePrice) || other.averagePrice == averagePrice)&&(identical(other.pricedItemCount, pricedItemCount) || other.pricedItemCount == pricedItemCount)&&const DeepCollectionEquality().equals(other._monthlySpending, _monthlySpending)&&const DeepCollectionEquality().equals(other._storeSpending, _storeSpending)&&const DeepCollectionEquality().equals(other._nutriscoreByStore, _nutriscoreByStore)&&(identical(other.mealsCooked, mealsCooked) || other.mealsCooked == mealsCooked)&&(identical(other.totalRecipeCost, totalRecipeCost) || other.totalRecipeCost == totalRecipeCost)&&(identical(other.averageRecipeNutriScore, averageRecipeNutriScore) || other.averageRecipeNutriScore == averageRecipeNutriScore)&&(identical(other.mostCookedRecipe, mostCookedRecipe) || other.mostCookedRecipe == mostCookedRecipe));
}


@override
int get hashCode => Object.hashAll([runtimeType,totalProducts,totalItems,averageNutriscoreNumeric,expiredCount,expiringSoonCount,goodCount,addedThisWeek,addedThisMonth,const DeepCollectionEquality().hash(_weeklyAdditions),const DeepCollectionEquality().hash(_itemsByLocation),const DeepCollectionEquality().hash(_categoriesTop),const DeepCollectionEquality().hash(_nutriscoreDistribution),const DeepCollectionEquality().hash(_itemsBySource),localPhotos,offPhotos,totalValue,averagePrice,pricedItemCount,const DeepCollectionEquality().hash(_monthlySpending),const DeepCollectionEquality().hash(_storeSpending),const DeepCollectionEquality().hash(_nutriscoreByStore),mealsCooked,totalRecipeCost,averageRecipeNutriScore,mostCookedRecipe]);

@override
String toString() {
  return 'PantryStats(totalProducts: $totalProducts, totalItems: $totalItems, averageNutriscoreNumeric: $averageNutriscoreNumeric, expiredCount: $expiredCount, expiringSoonCount: $expiringSoonCount, goodCount: $goodCount, addedThisWeek: $addedThisWeek, addedThisMonth: $addedThisMonth, weeklyAdditions: $weeklyAdditions, itemsByLocation: $itemsByLocation, categoriesTop: $categoriesTop, nutriscoreDistribution: $nutriscoreDistribution, itemsBySource: $itemsBySource, localPhotos: $localPhotos, offPhotos: $offPhotos, totalValue: $totalValue, averagePrice: $averagePrice, pricedItemCount: $pricedItemCount, monthlySpending: $monthlySpending, storeSpending: $storeSpending, nutriscoreByStore: $nutriscoreByStore, mealsCooked: $mealsCooked, totalRecipeCost: $totalRecipeCost, averageRecipeNutriScore: $averageRecipeNutriScore, mostCookedRecipe: $mostCookedRecipe)';
}


}

/// @nodoc
abstract mixin class _$PantryStatsCopyWith<$Res> implements $PantryStatsCopyWith<$Res> {
  factory _$PantryStatsCopyWith(_PantryStats value, $Res Function(_PantryStats) _then) = __$PantryStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalProducts, int totalItems, double averageNutriscoreNumeric, int expiredCount, int expiringSoonCount, int goodCount, int addedThisWeek, int addedThisMonth, List<WeeklyCount> weeklyAdditions, Map<String, int> itemsByLocation, List<CategoryCount> categoriesTop, Map<String, int> nutriscoreDistribution, Map<String, int> itemsBySource, PhotoStats localPhotos, PhotoStats offPhotos, double totalValue, double averagePrice, int pricedItemCount, List<MonthlySpending> monthlySpending, List<StoreSpending> storeSpending, List<StoreNutriscore> nutriscoreByStore, int mealsCooked, double totalRecipeCost, double averageRecipeNutriScore, String mostCookedRecipe
});


@override $PhotoStatsCopyWith<$Res> get localPhotos;@override $PhotoStatsCopyWith<$Res> get offPhotos;

}
/// @nodoc
class __$PantryStatsCopyWithImpl<$Res>
    implements _$PantryStatsCopyWith<$Res> {
  __$PantryStatsCopyWithImpl(this._self, this._then);

  final _PantryStats _self;
  final $Res Function(_PantryStats) _then;

/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalProducts = null,Object? totalItems = null,Object? averageNutriscoreNumeric = null,Object? expiredCount = null,Object? expiringSoonCount = null,Object? goodCount = null,Object? addedThisWeek = null,Object? addedThisMonth = null,Object? weeklyAdditions = null,Object? itemsByLocation = null,Object? categoriesTop = null,Object? nutriscoreDistribution = null,Object? itemsBySource = null,Object? localPhotos = null,Object? offPhotos = null,Object? totalValue = null,Object? averagePrice = null,Object? pricedItemCount = null,Object? monthlySpending = null,Object? storeSpending = null,Object? nutriscoreByStore = null,Object? mealsCooked = null,Object? totalRecipeCost = null,Object? averageRecipeNutriScore = null,Object? mostCookedRecipe = null,}) {
  return _then(_PantryStats(
totalProducts: null == totalProducts ? _self.totalProducts : totalProducts // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,averageNutriscoreNumeric: null == averageNutriscoreNumeric ? _self.averageNutriscoreNumeric : averageNutriscoreNumeric // ignore: cast_nullable_to_non_nullable
as double,expiredCount: null == expiredCount ? _self.expiredCount : expiredCount // ignore: cast_nullable_to_non_nullable
as int,expiringSoonCount: null == expiringSoonCount ? _self.expiringSoonCount : expiringSoonCount // ignore: cast_nullable_to_non_nullable
as int,goodCount: null == goodCount ? _self.goodCount : goodCount // ignore: cast_nullable_to_non_nullable
as int,addedThisWeek: null == addedThisWeek ? _self.addedThisWeek : addedThisWeek // ignore: cast_nullable_to_non_nullable
as int,addedThisMonth: null == addedThisMonth ? _self.addedThisMonth : addedThisMonth // ignore: cast_nullable_to_non_nullable
as int,weeklyAdditions: null == weeklyAdditions ? _self._weeklyAdditions : weeklyAdditions // ignore: cast_nullable_to_non_nullable
as List<WeeklyCount>,itemsByLocation: null == itemsByLocation ? _self._itemsByLocation : itemsByLocation // ignore: cast_nullable_to_non_nullable
as Map<String, int>,categoriesTop: null == categoriesTop ? _self._categoriesTop : categoriesTop // ignore: cast_nullable_to_non_nullable
as List<CategoryCount>,nutriscoreDistribution: null == nutriscoreDistribution ? _self._nutriscoreDistribution : nutriscoreDistribution // ignore: cast_nullable_to_non_nullable
as Map<String, int>,itemsBySource: null == itemsBySource ? _self._itemsBySource : itemsBySource // ignore: cast_nullable_to_non_nullable
as Map<String, int>,localPhotos: null == localPhotos ? _self.localPhotos : localPhotos // ignore: cast_nullable_to_non_nullable
as PhotoStats,offPhotos: null == offPhotos ? _self.offPhotos : offPhotos // ignore: cast_nullable_to_non_nullable
as PhotoStats,totalValue: null == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double,averagePrice: null == averagePrice ? _self.averagePrice : averagePrice // ignore: cast_nullable_to_non_nullable
as double,pricedItemCount: null == pricedItemCount ? _self.pricedItemCount : pricedItemCount // ignore: cast_nullable_to_non_nullable
as int,monthlySpending: null == monthlySpending ? _self._monthlySpending : monthlySpending // ignore: cast_nullable_to_non_nullable
as List<MonthlySpending>,storeSpending: null == storeSpending ? _self._storeSpending : storeSpending // ignore: cast_nullable_to_non_nullable
as List<StoreSpending>,nutriscoreByStore: null == nutriscoreByStore ? _self._nutriscoreByStore : nutriscoreByStore // ignore: cast_nullable_to_non_nullable
as List<StoreNutriscore>,mealsCooked: null == mealsCooked ? _self.mealsCooked : mealsCooked // ignore: cast_nullable_to_non_nullable
as int,totalRecipeCost: null == totalRecipeCost ? _self.totalRecipeCost : totalRecipeCost // ignore: cast_nullable_to_non_nullable
as double,averageRecipeNutriScore: null == averageRecipeNutriScore ? _self.averageRecipeNutriScore : averageRecipeNutriScore // ignore: cast_nullable_to_non_nullable
as double,mostCookedRecipe: null == mostCookedRecipe ? _self.mostCookedRecipe : mostCookedRecipe // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhotoStatsCopyWith<$Res> get localPhotos {
  
  return $PhotoStatsCopyWith<$Res>(_self.localPhotos, (value) {
    return _then(_self.copyWith(localPhotos: value));
  });
}/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhotoStatsCopyWith<$Res> get offPhotos {
  
  return $PhotoStatsCopyWith<$Res>(_self.offPhotos, (value) {
    return _then(_self.copyWith(offPhotos: value));
  });
}
}

/// @nodoc
mixin _$WeeklyCount {

 String get weekLabel; int get count;
/// Create a copy of WeeklyCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyCountCopyWith<WeeklyCount> get copyWith => _$WeeklyCountCopyWithImpl<WeeklyCount>(this as WeeklyCount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyCount&&(identical(other.weekLabel, weekLabel) || other.weekLabel == weekLabel)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,weekLabel,count);

@override
String toString() {
  return 'WeeklyCount(weekLabel: $weekLabel, count: $count)';
}


}

/// @nodoc
abstract mixin class $WeeklyCountCopyWith<$Res>  {
  factory $WeeklyCountCopyWith(WeeklyCount value, $Res Function(WeeklyCount) _then) = _$WeeklyCountCopyWithImpl;
@useResult
$Res call({
 String weekLabel, int count
});




}
/// @nodoc
class _$WeeklyCountCopyWithImpl<$Res>
    implements $WeeklyCountCopyWith<$Res> {
  _$WeeklyCountCopyWithImpl(this._self, this._then);

  final WeeklyCount _self;
  final $Res Function(WeeklyCount) _then;

/// Create a copy of WeeklyCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekLabel = null,Object? count = null,}) {
  return _then(_self.copyWith(
weekLabel: null == weekLabel ? _self.weekLabel : weekLabel // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyCount].
extension WeeklyCountPatterns on WeeklyCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyCount value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyCount value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekLabel,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyCount() when $default != null:
return $default(_that.weekLabel,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekLabel,  int count)  $default,) {final _that = this;
switch (_that) {
case _WeeklyCount():
return $default(_that.weekLabel,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekLabel,  int count)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyCount() when $default != null:
return $default(_that.weekLabel,_that.count);case _:
  return null;

}
}

}

/// @nodoc


class _WeeklyCount implements WeeklyCount {
  const _WeeklyCount({required this.weekLabel, required this.count});
  

@override final  String weekLabel;
@override final  int count;

/// Create a copy of WeeklyCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyCountCopyWith<_WeeklyCount> get copyWith => __$WeeklyCountCopyWithImpl<_WeeklyCount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyCount&&(identical(other.weekLabel, weekLabel) || other.weekLabel == weekLabel)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,weekLabel,count);

@override
String toString() {
  return 'WeeklyCount(weekLabel: $weekLabel, count: $count)';
}


}

/// @nodoc
abstract mixin class _$WeeklyCountCopyWith<$Res> implements $WeeklyCountCopyWith<$Res> {
  factory _$WeeklyCountCopyWith(_WeeklyCount value, $Res Function(_WeeklyCount) _then) = __$WeeklyCountCopyWithImpl;
@override @useResult
$Res call({
 String weekLabel, int count
});




}
/// @nodoc
class __$WeeklyCountCopyWithImpl<$Res>
    implements _$WeeklyCountCopyWith<$Res> {
  __$WeeklyCountCopyWithImpl(this._self, this._then);

  final _WeeklyCount _self;
  final $Res Function(_WeeklyCount) _then;

/// Create a copy of WeeklyCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekLabel = null,Object? count = null,}) {
  return _then(_WeeklyCount(
weekLabel: null == weekLabel ? _self.weekLabel : weekLabel // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$CategoryCount {

 String get category; int get count;
/// Create a copy of CategoryCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryCountCopyWith<CategoryCount> get copyWith => _$CategoryCountCopyWithImpl<CategoryCount>(this as CategoryCount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryCount&&(identical(other.category, category) || other.category == category)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,category,count);

@override
String toString() {
  return 'CategoryCount(category: $category, count: $count)';
}


}

/// @nodoc
abstract mixin class $CategoryCountCopyWith<$Res>  {
  factory $CategoryCountCopyWith(CategoryCount value, $Res Function(CategoryCount) _then) = _$CategoryCountCopyWithImpl;
@useResult
$Res call({
 String category, int count
});




}
/// @nodoc
class _$CategoryCountCopyWithImpl<$Res>
    implements $CategoryCountCopyWith<$Res> {
  _$CategoryCountCopyWithImpl(this._self, this._then);

  final CategoryCount _self;
  final $Res Function(CategoryCount) _then;

/// Create a copy of CategoryCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? count = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryCount].
extension CategoryCountPatterns on CategoryCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryCount value)  $default,){
final _that = this;
switch (_that) {
case _CategoryCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryCount value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryCount() when $default != null:
return $default(_that.category,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  int count)  $default,) {final _that = this;
switch (_that) {
case _CategoryCount():
return $default(_that.category,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  int count)?  $default,) {final _that = this;
switch (_that) {
case _CategoryCount() when $default != null:
return $default(_that.category,_that.count);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryCount implements CategoryCount {
  const _CategoryCount({required this.category, required this.count});
  

@override final  String category;
@override final  int count;

/// Create a copy of CategoryCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryCountCopyWith<_CategoryCount> get copyWith => __$CategoryCountCopyWithImpl<_CategoryCount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryCount&&(identical(other.category, category) || other.category == category)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,category,count);

@override
String toString() {
  return 'CategoryCount(category: $category, count: $count)';
}


}

/// @nodoc
abstract mixin class _$CategoryCountCopyWith<$Res> implements $CategoryCountCopyWith<$Res> {
  factory _$CategoryCountCopyWith(_CategoryCount value, $Res Function(_CategoryCount) _then) = __$CategoryCountCopyWithImpl;
@override @useResult
$Res call({
 String category, int count
});




}
/// @nodoc
class __$CategoryCountCopyWithImpl<$Res>
    implements _$CategoryCountCopyWith<$Res> {
  __$CategoryCountCopyWithImpl(this._self, this._then);

  final _CategoryCount _self;
  final $Res Function(_CategoryCount) _then;

/// Create a copy of CategoryCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? count = null,}) {
  return _then(_CategoryCount(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PhotoStats {

 int get total; int get withNutrition; int get withIngredients; int get withProduct;
/// Create a copy of PhotoStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoStatsCopyWith<PhotoStats> get copyWith => _$PhotoStatsCopyWithImpl<PhotoStats>(this as PhotoStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoStats&&(identical(other.total, total) || other.total == total)&&(identical(other.withNutrition, withNutrition) || other.withNutrition == withNutrition)&&(identical(other.withIngredients, withIngredients) || other.withIngredients == withIngredients)&&(identical(other.withProduct, withProduct) || other.withProduct == withProduct));
}


@override
int get hashCode => Object.hash(runtimeType,total,withNutrition,withIngredients,withProduct);

@override
String toString() {
  return 'PhotoStats(total: $total, withNutrition: $withNutrition, withIngredients: $withIngredients, withProduct: $withProduct)';
}


}

/// @nodoc
abstract mixin class $PhotoStatsCopyWith<$Res>  {
  factory $PhotoStatsCopyWith(PhotoStats value, $Res Function(PhotoStats) _then) = _$PhotoStatsCopyWithImpl;
@useResult
$Res call({
 int total, int withNutrition, int withIngredients, int withProduct
});




}
/// @nodoc
class _$PhotoStatsCopyWithImpl<$Res>
    implements $PhotoStatsCopyWith<$Res> {
  _$PhotoStatsCopyWithImpl(this._self, this._then);

  final PhotoStats _self;
  final $Res Function(PhotoStats) _then;

/// Create a copy of PhotoStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? withNutrition = null,Object? withIngredients = null,Object? withProduct = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,withNutrition: null == withNutrition ? _self.withNutrition : withNutrition // ignore: cast_nullable_to_non_nullable
as int,withIngredients: null == withIngredients ? _self.withIngredients : withIngredients // ignore: cast_nullable_to_non_nullable
as int,withProduct: null == withProduct ? _self.withProduct : withProduct // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PhotoStats].
extension PhotoStatsPatterns on PhotoStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhotoStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhotoStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhotoStats value)  $default,){
final _that = this;
switch (_that) {
case _PhotoStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhotoStats value)?  $default,){
final _that = this;
switch (_that) {
case _PhotoStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int withNutrition,  int withIngredients,  int withProduct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhotoStats() when $default != null:
return $default(_that.total,_that.withNutrition,_that.withIngredients,_that.withProduct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int withNutrition,  int withIngredients,  int withProduct)  $default,) {final _that = this;
switch (_that) {
case _PhotoStats():
return $default(_that.total,_that.withNutrition,_that.withIngredients,_that.withProduct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int withNutrition,  int withIngredients,  int withProduct)?  $default,) {final _that = this;
switch (_that) {
case _PhotoStats() when $default != null:
return $default(_that.total,_that.withNutrition,_that.withIngredients,_that.withProduct);case _:
  return null;

}
}

}

/// @nodoc


class _PhotoStats implements PhotoStats {
  const _PhotoStats({required this.total, required this.withNutrition, required this.withIngredients, required this.withProduct});
  

@override final  int total;
@override final  int withNutrition;
@override final  int withIngredients;
@override final  int withProduct;

/// Create a copy of PhotoStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoStatsCopyWith<_PhotoStats> get copyWith => __$PhotoStatsCopyWithImpl<_PhotoStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhotoStats&&(identical(other.total, total) || other.total == total)&&(identical(other.withNutrition, withNutrition) || other.withNutrition == withNutrition)&&(identical(other.withIngredients, withIngredients) || other.withIngredients == withIngredients)&&(identical(other.withProduct, withProduct) || other.withProduct == withProduct));
}


@override
int get hashCode => Object.hash(runtimeType,total,withNutrition,withIngredients,withProduct);

@override
String toString() {
  return 'PhotoStats(total: $total, withNutrition: $withNutrition, withIngredients: $withIngredients, withProduct: $withProduct)';
}


}

/// @nodoc
abstract mixin class _$PhotoStatsCopyWith<$Res> implements $PhotoStatsCopyWith<$Res> {
  factory _$PhotoStatsCopyWith(_PhotoStats value, $Res Function(_PhotoStats) _then) = __$PhotoStatsCopyWithImpl;
@override @useResult
$Res call({
 int total, int withNutrition, int withIngredients, int withProduct
});




}
/// @nodoc
class __$PhotoStatsCopyWithImpl<$Res>
    implements _$PhotoStatsCopyWith<$Res> {
  __$PhotoStatsCopyWithImpl(this._self, this._then);

  final _PhotoStats _self;
  final $Res Function(_PhotoStats) _then;

/// Create a copy of PhotoStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? withNutrition = null,Object? withIngredients = null,Object? withProduct = null,}) {
  return _then(_PhotoStats(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,withNutrition: null == withNutrition ? _self.withNutrition : withNutrition // ignore: cast_nullable_to_non_nullable
as int,withIngredients: null == withIngredients ? _self.withIngredients : withIngredients // ignore: cast_nullable_to_non_nullable
as int,withProduct: null == withProduct ? _self.withProduct : withProduct // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$MonthlySpending {

/// ISO year-month label, e.g. "2026-07".
 String get month;/// Total spending in base currency for this month.
 double get total;
/// Create a copy of MonthlySpending
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlySpendingCopyWith<MonthlySpending> get copyWith => _$MonthlySpendingCopyWithImpl<MonthlySpending>(this as MonthlySpending, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlySpending&&(identical(other.month, month) || other.month == month)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,month,total);

@override
String toString() {
  return 'MonthlySpending(month: $month, total: $total)';
}


}

/// @nodoc
abstract mixin class $MonthlySpendingCopyWith<$Res>  {
  factory $MonthlySpendingCopyWith(MonthlySpending value, $Res Function(MonthlySpending) _then) = _$MonthlySpendingCopyWithImpl;
@useResult
$Res call({
 String month, double total
});




}
/// @nodoc
class _$MonthlySpendingCopyWithImpl<$Res>
    implements $MonthlySpendingCopyWith<$Res> {
  _$MonthlySpendingCopyWithImpl(this._self, this._then);

  final MonthlySpending _self;
  final $Res Function(MonthlySpending) _then;

/// Create a copy of MonthlySpending
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? total = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlySpending].
extension MonthlySpendingPatterns on MonthlySpending {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlySpending value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlySpending() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlySpending value)  $default,){
final _that = this;
switch (_that) {
case _MonthlySpending():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlySpending value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlySpending() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  double total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlySpending() when $default != null:
return $default(_that.month,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  double total)  $default,) {final _that = this;
switch (_that) {
case _MonthlySpending():
return $default(_that.month,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  double total)?  $default,) {final _that = this;
switch (_that) {
case _MonthlySpending() when $default != null:
return $default(_that.month,_that.total);case _:
  return null;

}
}

}

/// @nodoc


class _MonthlySpending implements MonthlySpending {
  const _MonthlySpending({required this.month, required this.total});
  

/// ISO year-month label, e.g. "2026-07".
@override final  String month;
/// Total spending in base currency for this month.
@override final  double total;

/// Create a copy of MonthlySpending
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlySpendingCopyWith<_MonthlySpending> get copyWith => __$MonthlySpendingCopyWithImpl<_MonthlySpending>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlySpending&&(identical(other.month, month) || other.month == month)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,month,total);

@override
String toString() {
  return 'MonthlySpending(month: $month, total: $total)';
}


}

/// @nodoc
abstract mixin class _$MonthlySpendingCopyWith<$Res> implements $MonthlySpendingCopyWith<$Res> {
  factory _$MonthlySpendingCopyWith(_MonthlySpending value, $Res Function(_MonthlySpending) _then) = __$MonthlySpendingCopyWithImpl;
@override @useResult
$Res call({
 String month, double total
});




}
/// @nodoc
class __$MonthlySpendingCopyWithImpl<$Res>
    implements _$MonthlySpendingCopyWith<$Res> {
  __$MonthlySpendingCopyWithImpl(this._self, this._then);

  final _MonthlySpending _self;
  final $Res Function(_MonthlySpending) _then;

/// Create a copy of MonthlySpending
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? total = null,}) {
  return _then(_MonthlySpending(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$StoreSpending {

/// Store name.
 String get store;/// Total spending at this store in base currency.
 double get total;/// Number of priced items purchased at this store.
 int get itemCount;
/// Create a copy of StoreSpending
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreSpendingCopyWith<StoreSpending> get copyWith => _$StoreSpendingCopyWithImpl<StoreSpending>(this as StoreSpending, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreSpending&&(identical(other.store, store) || other.store == store)&&(identical(other.total, total) || other.total == total)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount));
}


@override
int get hashCode => Object.hash(runtimeType,store,total,itemCount);

@override
String toString() {
  return 'StoreSpending(store: $store, total: $total, itemCount: $itemCount)';
}


}

/// @nodoc
abstract mixin class $StoreSpendingCopyWith<$Res>  {
  factory $StoreSpendingCopyWith(StoreSpending value, $Res Function(StoreSpending) _then) = _$StoreSpendingCopyWithImpl;
@useResult
$Res call({
 String store, double total, int itemCount
});




}
/// @nodoc
class _$StoreSpendingCopyWithImpl<$Res>
    implements $StoreSpendingCopyWith<$Res> {
  _$StoreSpendingCopyWithImpl(this._self, this._then);

  final StoreSpending _self;
  final $Res Function(StoreSpending) _then;

/// Create a copy of StoreSpending
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? store = null,Object? total = null,Object? itemCount = null,}) {
  return _then(_self.copyWith(
store: null == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StoreSpending].
extension StoreSpendingPatterns on StoreSpending {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoreSpending value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoreSpending() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoreSpending value)  $default,){
final _that = this;
switch (_that) {
case _StoreSpending():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoreSpending value)?  $default,){
final _that = this;
switch (_that) {
case _StoreSpending() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String store,  double total,  int itemCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoreSpending() when $default != null:
return $default(_that.store,_that.total,_that.itemCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String store,  double total,  int itemCount)  $default,) {final _that = this;
switch (_that) {
case _StoreSpending():
return $default(_that.store,_that.total,_that.itemCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String store,  double total,  int itemCount)?  $default,) {final _that = this;
switch (_that) {
case _StoreSpending() when $default != null:
return $default(_that.store,_that.total,_that.itemCount);case _:
  return null;

}
}

}

/// @nodoc


class _StoreSpending implements StoreSpending {
  const _StoreSpending({required this.store, required this.total, required this.itemCount});
  

/// Store name.
@override final  String store;
/// Total spending at this store in base currency.
@override final  double total;
/// Number of priced items purchased at this store.
@override final  int itemCount;

/// Create a copy of StoreSpending
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoreSpendingCopyWith<_StoreSpending> get copyWith => __$StoreSpendingCopyWithImpl<_StoreSpending>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoreSpending&&(identical(other.store, store) || other.store == store)&&(identical(other.total, total) || other.total == total)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount));
}


@override
int get hashCode => Object.hash(runtimeType,store,total,itemCount);

@override
String toString() {
  return 'StoreSpending(store: $store, total: $total, itemCount: $itemCount)';
}


}

/// @nodoc
abstract mixin class _$StoreSpendingCopyWith<$Res> implements $StoreSpendingCopyWith<$Res> {
  factory _$StoreSpendingCopyWith(_StoreSpending value, $Res Function(_StoreSpending) _then) = __$StoreSpendingCopyWithImpl;
@override @useResult
$Res call({
 String store, double total, int itemCount
});




}
/// @nodoc
class __$StoreSpendingCopyWithImpl<$Res>
    implements _$StoreSpendingCopyWith<$Res> {
  __$StoreSpendingCopyWithImpl(this._self, this._then);

  final _StoreSpending _self;
  final $Res Function(_StoreSpending) _then;

/// Create a copy of StoreSpending
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? store = null,Object? total = null,Object? itemCount = null,}) {
  return _then(_StoreSpending(
store: null == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$StoreNutriscore {

/// Store name.
 String get store;/// Average numeric Nutri-Score (5 = A, 4 = B, ... 1 = E).
 double get averageScore;
/// Create a copy of StoreNutriscore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreNutriscoreCopyWith<StoreNutriscore> get copyWith => _$StoreNutriscoreCopyWithImpl<StoreNutriscore>(this as StoreNutriscore, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreNutriscore&&(identical(other.store, store) || other.store == store)&&(identical(other.averageScore, averageScore) || other.averageScore == averageScore));
}


@override
int get hashCode => Object.hash(runtimeType,store,averageScore);

@override
String toString() {
  return 'StoreNutriscore(store: $store, averageScore: $averageScore)';
}


}

/// @nodoc
abstract mixin class $StoreNutriscoreCopyWith<$Res>  {
  factory $StoreNutriscoreCopyWith(StoreNutriscore value, $Res Function(StoreNutriscore) _then) = _$StoreNutriscoreCopyWithImpl;
@useResult
$Res call({
 String store, double averageScore
});




}
/// @nodoc
class _$StoreNutriscoreCopyWithImpl<$Res>
    implements $StoreNutriscoreCopyWith<$Res> {
  _$StoreNutriscoreCopyWithImpl(this._self, this._then);

  final StoreNutriscore _self;
  final $Res Function(StoreNutriscore) _then;

/// Create a copy of StoreNutriscore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? store = null,Object? averageScore = null,}) {
  return _then(_self.copyWith(
store: null == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String,averageScore: null == averageScore ? _self.averageScore : averageScore // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [StoreNutriscore].
extension StoreNutriscorePatterns on StoreNutriscore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoreNutriscore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoreNutriscore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoreNutriscore value)  $default,){
final _that = this;
switch (_that) {
case _StoreNutriscore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoreNutriscore value)?  $default,){
final _that = this;
switch (_that) {
case _StoreNutriscore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String store,  double averageScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoreNutriscore() when $default != null:
return $default(_that.store,_that.averageScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String store,  double averageScore)  $default,) {final _that = this;
switch (_that) {
case _StoreNutriscore():
return $default(_that.store,_that.averageScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String store,  double averageScore)?  $default,) {final _that = this;
switch (_that) {
case _StoreNutriscore() when $default != null:
return $default(_that.store,_that.averageScore);case _:
  return null;

}
}

}

/// @nodoc


class _StoreNutriscore implements StoreNutriscore {
  const _StoreNutriscore({required this.store, required this.averageScore});
  

/// Store name.
@override final  String store;
/// Average numeric Nutri-Score (5 = A, 4 = B, ... 1 = E).
@override final  double averageScore;

/// Create a copy of StoreNutriscore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoreNutriscoreCopyWith<_StoreNutriscore> get copyWith => __$StoreNutriscoreCopyWithImpl<_StoreNutriscore>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoreNutriscore&&(identical(other.store, store) || other.store == store)&&(identical(other.averageScore, averageScore) || other.averageScore == averageScore));
}


@override
int get hashCode => Object.hash(runtimeType,store,averageScore);

@override
String toString() {
  return 'StoreNutriscore(store: $store, averageScore: $averageScore)';
}


}

/// @nodoc
abstract mixin class _$StoreNutriscoreCopyWith<$Res> implements $StoreNutriscoreCopyWith<$Res> {
  factory _$StoreNutriscoreCopyWith(_StoreNutriscore value, $Res Function(_StoreNutriscore) _then) = __$StoreNutriscoreCopyWithImpl;
@override @useResult
$Res call({
 String store, double averageScore
});




}
/// @nodoc
class __$StoreNutriscoreCopyWithImpl<$Res>
    implements _$StoreNutriscoreCopyWith<$Res> {
  __$StoreNutriscoreCopyWithImpl(this._self, this._then);

  final _StoreNutriscore _self;
  final $Res Function(_StoreNutriscore) _then;

/// Create a copy of StoreNutriscore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? store = null,Object? averageScore = null,}) {
  return _then(_StoreNutriscore(
store: null == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String,averageScore: null == averageScore ? _self.averageScore : averageScore // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
