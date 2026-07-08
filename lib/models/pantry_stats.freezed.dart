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

 int get totalProducts; int get totalItems; double get averageNutriscoreNumeric; int get expiredCount; int get expiringSoonCount; int get goodCount; int get addedThisWeek; int get addedThisMonth; List<WeeklyCount> get weeklyAdditions; Map<String, int> get itemsByLocation; List<CategoryCount> get categoriesTop; Map<String, int> get nutriscoreDistribution; Map<String, int> get itemsBySource; PhotoStats get localPhotos; PhotoStats get offPhotos; double get totalValue; double get averagePrice; int get pricedItemCount;
/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PantryStatsCopyWith<PantryStats> get copyWith => _$PantryStatsCopyWithImpl<PantryStats>(this as PantryStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PantryStats&&(identical(other.totalProducts, totalProducts) || other.totalProducts == totalProducts)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.averageNutriscoreNumeric, averageNutriscoreNumeric) || other.averageNutriscoreNumeric == averageNutriscoreNumeric)&&(identical(other.expiredCount, expiredCount) || other.expiredCount == expiredCount)&&(identical(other.expiringSoonCount, expiringSoonCount) || other.expiringSoonCount == expiringSoonCount)&&(identical(other.goodCount, goodCount) || other.goodCount == goodCount)&&(identical(other.addedThisWeek, addedThisWeek) || other.addedThisWeek == addedThisWeek)&&(identical(other.addedThisMonth, addedThisMonth) || other.addedThisMonth == addedThisMonth)&&const DeepCollectionEquality().equals(other.weeklyAdditions, weeklyAdditions)&&const DeepCollectionEquality().equals(other.itemsByLocation, itemsByLocation)&&const DeepCollectionEquality().equals(other.categoriesTop, categoriesTop)&&const DeepCollectionEquality().equals(other.nutriscoreDistribution, nutriscoreDistribution)&&const DeepCollectionEquality().equals(other.itemsBySource, itemsBySource)&&(identical(other.localPhotos, localPhotos) || other.localPhotos == localPhotos)&&(identical(other.offPhotos, offPhotos) || other.offPhotos == offPhotos)&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.averagePrice, averagePrice) || other.averagePrice == averagePrice)&&(identical(other.pricedItemCount, pricedItemCount) || other.pricedItemCount == pricedItemCount));
}


@override
int get hashCode => Object.hash(runtimeType,totalProducts,totalItems,averageNutriscoreNumeric,expiredCount,expiringSoonCount,goodCount,addedThisWeek,addedThisMonth,const DeepCollectionEquality().hash(weeklyAdditions),const DeepCollectionEquality().hash(itemsByLocation),const DeepCollectionEquality().hash(categoriesTop),const DeepCollectionEquality().hash(nutriscoreDistribution),const DeepCollectionEquality().hash(itemsBySource),localPhotos,offPhotos,totalValue,averagePrice,pricedItemCount);

@override
String toString() {
  return 'PantryStats(totalProducts: $totalProducts, totalItems: $totalItems, averageNutriscoreNumeric: $averageNutriscoreNumeric, expiredCount: $expiredCount, expiringSoonCount: $expiringSoonCount, goodCount: $goodCount, addedThisWeek: $addedThisWeek, addedThisMonth: $addedThisMonth, weeklyAdditions: $weeklyAdditions, itemsByLocation: $itemsByLocation, categoriesTop: $categoriesTop, nutriscoreDistribution: $nutriscoreDistribution, itemsBySource: $itemsBySource, localPhotos: $localPhotos, offPhotos: $offPhotos, totalValue: $totalValue, averagePrice: $averagePrice, pricedItemCount: $pricedItemCount)';
}


}

/// @nodoc
abstract mixin class $PantryStatsCopyWith<$Res>  {
  factory $PantryStatsCopyWith(PantryStats value, $Res Function(PantryStats) _then) = _$PantryStatsCopyWithImpl;
@useResult
$Res call({
 int totalProducts, int totalItems, double averageNutriscoreNumeric, int expiredCount, int expiringSoonCount, int goodCount, int addedThisWeek, int addedThisMonth, List<WeeklyCount> weeklyAdditions, Map<String, int> itemsByLocation, List<CategoryCount> categoriesTop, Map<String, int> nutriscoreDistribution, Map<String, int> itemsBySource, PhotoStats localPhotos, PhotoStats offPhotos, double totalValue, double averagePrice, int pricedItemCount
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
@pragma('vm:prefer-inline') @override $Res call({Object? totalProducts = null,Object? totalItems = null,Object? averageNutriscoreNumeric = null,Object? expiredCount = null,Object? expiringSoonCount = null,Object? goodCount = null,Object? addedThisWeek = null,Object? addedThisMonth = null,Object? weeklyAdditions = null,Object? itemsByLocation = null,Object? categoriesTop = null,Object? nutriscoreDistribution = null,Object? itemsBySource = null,Object? localPhotos = null,Object? offPhotos = null,Object? totalValue = null,Object? averagePrice = null,Object? pricedItemCount = null,}) {
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
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalProducts,  int totalItems,  double averageNutriscoreNumeric,  int expiredCount,  int expiringSoonCount,  int goodCount,  int addedThisWeek,  int addedThisMonth,  List<WeeklyCount> weeklyAdditions,  Map<String, int> itemsByLocation,  List<CategoryCount> categoriesTop,  Map<String, int> nutriscoreDistribution,  Map<String, int> itemsBySource,  PhotoStats localPhotos,  PhotoStats offPhotos,  double totalValue,  double averagePrice,  int pricedItemCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PantryStats() when $default != null:
return $default(_that.totalProducts,_that.totalItems,_that.averageNutriscoreNumeric,_that.expiredCount,_that.expiringSoonCount,_that.goodCount,_that.addedThisWeek,_that.addedThisMonth,_that.weeklyAdditions,_that.itemsByLocation,_that.categoriesTop,_that.nutriscoreDistribution,_that.itemsBySource,_that.localPhotos,_that.offPhotos,_that.totalValue,_that.averagePrice,_that.pricedItemCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalProducts,  int totalItems,  double averageNutriscoreNumeric,  int expiredCount,  int expiringSoonCount,  int goodCount,  int addedThisWeek,  int addedThisMonth,  List<WeeklyCount> weeklyAdditions,  Map<String, int> itemsByLocation,  List<CategoryCount> categoriesTop,  Map<String, int> nutriscoreDistribution,  Map<String, int> itemsBySource,  PhotoStats localPhotos,  PhotoStats offPhotos,  double totalValue,  double averagePrice,  int pricedItemCount)  $default,) {final _that = this;
switch (_that) {
case _PantryStats():
return $default(_that.totalProducts,_that.totalItems,_that.averageNutriscoreNumeric,_that.expiredCount,_that.expiringSoonCount,_that.goodCount,_that.addedThisWeek,_that.addedThisMonth,_that.weeklyAdditions,_that.itemsByLocation,_that.categoriesTop,_that.nutriscoreDistribution,_that.itemsBySource,_that.localPhotos,_that.offPhotos,_that.totalValue,_that.averagePrice,_that.pricedItemCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalProducts,  int totalItems,  double averageNutriscoreNumeric,  int expiredCount,  int expiringSoonCount,  int goodCount,  int addedThisWeek,  int addedThisMonth,  List<WeeklyCount> weeklyAdditions,  Map<String, int> itemsByLocation,  List<CategoryCount> categoriesTop,  Map<String, int> nutriscoreDistribution,  Map<String, int> itemsBySource,  PhotoStats localPhotos,  PhotoStats offPhotos,  double totalValue,  double averagePrice,  int pricedItemCount)?  $default,) {final _that = this;
switch (_that) {
case _PantryStats() when $default != null:
return $default(_that.totalProducts,_that.totalItems,_that.averageNutriscoreNumeric,_that.expiredCount,_that.expiringSoonCount,_that.goodCount,_that.addedThisWeek,_that.addedThisMonth,_that.weeklyAdditions,_that.itemsByLocation,_that.categoriesTop,_that.nutriscoreDistribution,_that.itemsBySource,_that.localPhotos,_that.offPhotos,_that.totalValue,_that.averagePrice,_that.pricedItemCount);case _:
  return null;

}
}

}

/// @nodoc


class _PantryStats implements PantryStats {
  const _PantryStats({required this.totalProducts, required this.totalItems, required this.averageNutriscoreNumeric, required this.expiredCount, required this.expiringSoonCount, required this.goodCount, required this.addedThisWeek, required this.addedThisMonth, required final  List<WeeklyCount> weeklyAdditions, required final  Map<String, int> itemsByLocation, required final  List<CategoryCount> categoriesTop, required final  Map<String, int> nutriscoreDistribution, required final  Map<String, int> itemsBySource, required this.localPhotos, required this.offPhotos, this.totalValue = 0, this.averagePrice = 0, this.pricedItemCount = 0}): _weeklyAdditions = weeklyAdditions,_itemsByLocation = itemsByLocation,_categoriesTop = categoriesTop,_nutriscoreDistribution = nutriscoreDistribution,_itemsBySource = itemsBySource;
  

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

/// Create a copy of PantryStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PantryStatsCopyWith<_PantryStats> get copyWith => __$PantryStatsCopyWithImpl<_PantryStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PantryStats&&(identical(other.totalProducts, totalProducts) || other.totalProducts == totalProducts)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.averageNutriscoreNumeric, averageNutriscoreNumeric) || other.averageNutriscoreNumeric == averageNutriscoreNumeric)&&(identical(other.expiredCount, expiredCount) || other.expiredCount == expiredCount)&&(identical(other.expiringSoonCount, expiringSoonCount) || other.expiringSoonCount == expiringSoonCount)&&(identical(other.goodCount, goodCount) || other.goodCount == goodCount)&&(identical(other.addedThisWeek, addedThisWeek) || other.addedThisWeek == addedThisWeek)&&(identical(other.addedThisMonth, addedThisMonth) || other.addedThisMonth == addedThisMonth)&&const DeepCollectionEquality().equals(other._weeklyAdditions, _weeklyAdditions)&&const DeepCollectionEquality().equals(other._itemsByLocation, _itemsByLocation)&&const DeepCollectionEquality().equals(other._categoriesTop, _categoriesTop)&&const DeepCollectionEquality().equals(other._nutriscoreDistribution, _nutriscoreDistribution)&&const DeepCollectionEquality().equals(other._itemsBySource, _itemsBySource)&&(identical(other.localPhotos, localPhotos) || other.localPhotos == localPhotos)&&(identical(other.offPhotos, offPhotos) || other.offPhotos == offPhotos)&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.averagePrice, averagePrice) || other.averagePrice == averagePrice)&&(identical(other.pricedItemCount, pricedItemCount) || other.pricedItemCount == pricedItemCount));
}


@override
int get hashCode => Object.hash(runtimeType,totalProducts,totalItems,averageNutriscoreNumeric,expiredCount,expiringSoonCount,goodCount,addedThisWeek,addedThisMonth,const DeepCollectionEquality().hash(_weeklyAdditions),const DeepCollectionEquality().hash(_itemsByLocation),const DeepCollectionEquality().hash(_categoriesTop),const DeepCollectionEquality().hash(_nutriscoreDistribution),const DeepCollectionEquality().hash(_itemsBySource),localPhotos,offPhotos,totalValue,averagePrice,pricedItemCount);

@override
String toString() {
  return 'PantryStats(totalProducts: $totalProducts, totalItems: $totalItems, averageNutriscoreNumeric: $averageNutriscoreNumeric, expiredCount: $expiredCount, expiringSoonCount: $expiringSoonCount, goodCount: $goodCount, addedThisWeek: $addedThisWeek, addedThisMonth: $addedThisMonth, weeklyAdditions: $weeklyAdditions, itemsByLocation: $itemsByLocation, categoriesTop: $categoriesTop, nutriscoreDistribution: $nutriscoreDistribution, itemsBySource: $itemsBySource, localPhotos: $localPhotos, offPhotos: $offPhotos, totalValue: $totalValue, averagePrice: $averagePrice, pricedItemCount: $pricedItemCount)';
}


}

/// @nodoc
abstract mixin class _$PantryStatsCopyWith<$Res> implements $PantryStatsCopyWith<$Res> {
  factory _$PantryStatsCopyWith(_PantryStats value, $Res Function(_PantryStats) _then) = __$PantryStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalProducts, int totalItems, double averageNutriscoreNumeric, int expiredCount, int expiringSoonCount, int goodCount, int addedThisWeek, int addedThisMonth, List<WeeklyCount> weeklyAdditions, Map<String, int> itemsByLocation, List<CategoryCount> categoriesTop, Map<String, int> nutriscoreDistribution, Map<String, int> itemsBySource, PhotoStats localPhotos, PhotoStats offPhotos, double totalValue, double averagePrice, int pricedItemCount
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
@override @pragma('vm:prefer-inline') $Res call({Object? totalProducts = null,Object? totalItems = null,Object? averageNutriscoreNumeric = null,Object? expiredCount = null,Object? expiringSoonCount = null,Object? goodCount = null,Object? addedThisWeek = null,Object? addedThisMonth = null,Object? weeklyAdditions = null,Object? itemsByLocation = null,Object? categoriesTop = null,Object? nutriscoreDistribution = null,Object? itemsBySource = null,Object? localPhotos = null,Object? offPhotos = null,Object? totalValue = null,Object? averagePrice = null,Object? pricedItemCount = null,}) {
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
as int,
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

// dart format on
