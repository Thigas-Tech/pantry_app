// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'produce_cache_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProduceCacheEntry {

/// USDA FDC (FoodData Central) ID for this produce item.
///
/// Set to `0` when the FDC ID is not known (e.g. from fallback data).
 int get fdcId;/// Lowercase English produce name used as the Firestore document ID
/// (e.g. `"apple"`, `"banana"`).
 String get name;/// Nutrition per 100 g, keyed by nutrient name.
///
/// Known keys: `energyKcal`, `proteinG`, `carbsG`, `fatG`, `fiberG`.
/// An empty map means no nutrition data is available.
 Map<String, double> get nutrition;/// Epoch timestamp (ms) of when this entry was first created.
 int get createdAt;/// Epoch timestamp (ms) of when this entry was last refreshed.
 int get lastRefreshedAt;/// Epoch timestamp (ms) of when this entry should be refreshed next.
 int get nextRefreshAt;/// Localized names keyed by locale code (e.g. `{"pt": "Maca"}`).
 Map<String, String> get localizedNames;/// PLU (Price Look-Up) codes associated with this produce item.
 List<String> get pluCodes;/// The USDA food category (e.g. `"Fruits and Fruit Juices"`).
@JsonKey(includeIfNull: false) String? get category;/// Suggested serving size in grams. Null when unknown.
@JsonKey(includeIfNull: false) double? get servingSizeG;/// Schema version for forward compatibility.
 int get schemaVersion;
/// Create a copy of ProduceCacheEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProduceCacheEntryCopyWith<ProduceCacheEntry> get copyWith => _$ProduceCacheEntryCopyWithImpl<ProduceCacheEntry>(this as ProduceCacheEntry, _$identity);

  /// Serializes this ProduceCacheEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProduceCacheEntry&&(identical(other.fdcId, fdcId) || other.fdcId == fdcId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.nutrition, nutrition)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastRefreshedAt, lastRefreshedAt) || other.lastRefreshedAt == lastRefreshedAt)&&(identical(other.nextRefreshAt, nextRefreshAt) || other.nextRefreshAt == nextRefreshAt)&&const DeepCollectionEquality().equals(other.localizedNames, localizedNames)&&const DeepCollectionEquality().equals(other.pluCodes, pluCodes)&&(identical(other.category, category) || other.category == category)&&(identical(other.servingSizeG, servingSizeG) || other.servingSizeG == servingSizeG)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fdcId,name,const DeepCollectionEquality().hash(nutrition),createdAt,lastRefreshedAt,nextRefreshAt,const DeepCollectionEquality().hash(localizedNames),const DeepCollectionEquality().hash(pluCodes),category,servingSizeG,schemaVersion);

@override
String toString() {
  return 'ProduceCacheEntry(fdcId: $fdcId, name: $name, nutrition: $nutrition, createdAt: $createdAt, lastRefreshedAt: $lastRefreshedAt, nextRefreshAt: $nextRefreshAt, localizedNames: $localizedNames, pluCodes: $pluCodes, category: $category, servingSizeG: $servingSizeG, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $ProduceCacheEntryCopyWith<$Res>  {
  factory $ProduceCacheEntryCopyWith(ProduceCacheEntry value, $Res Function(ProduceCacheEntry) _then) = _$ProduceCacheEntryCopyWithImpl;
@useResult
$Res call({
 int fdcId, String name, Map<String, double> nutrition, int createdAt, int lastRefreshedAt, int nextRefreshAt, Map<String, String> localizedNames, List<String> pluCodes,@JsonKey(includeIfNull: false) String? category,@JsonKey(includeIfNull: false) double? servingSizeG, int schemaVersion
});




}
/// @nodoc
class _$ProduceCacheEntryCopyWithImpl<$Res>
    implements $ProduceCacheEntryCopyWith<$Res> {
  _$ProduceCacheEntryCopyWithImpl(this._self, this._then);

  final ProduceCacheEntry _self;
  final $Res Function(ProduceCacheEntry) _then;

/// Create a copy of ProduceCacheEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fdcId = null,Object? name = null,Object? nutrition = null,Object? createdAt = null,Object? lastRefreshedAt = null,Object? nextRefreshAt = null,Object? localizedNames = null,Object? pluCodes = null,Object? category = freezed,Object? servingSizeG = freezed,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
fdcId: null == fdcId ? _self.fdcId : fdcId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nutrition: null == nutrition ? _self.nutrition : nutrition // ignore: cast_nullable_to_non_nullable
as Map<String, double>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,lastRefreshedAt: null == lastRefreshedAt ? _self.lastRefreshedAt : lastRefreshedAt // ignore: cast_nullable_to_non_nullable
as int,nextRefreshAt: null == nextRefreshAt ? _self.nextRefreshAt : nextRefreshAt // ignore: cast_nullable_to_non_nullable
as int,localizedNames: null == localizedNames ? _self.localizedNames : localizedNames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,pluCodes: null == pluCodes ? _self.pluCodes : pluCodes // ignore: cast_nullable_to_non_nullable
as List<String>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,servingSizeG: freezed == servingSizeG ? _self.servingSizeG : servingSizeG // ignore: cast_nullable_to_non_nullable
as double?,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProduceCacheEntry].
extension ProduceCacheEntryPatterns on ProduceCacheEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProduceCacheEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProduceCacheEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProduceCacheEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProduceCacheEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProduceCacheEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProduceCacheEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int fdcId,  String name,  Map<String, double> nutrition,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt,  Map<String, String> localizedNames,  List<String> pluCodes, @JsonKey(includeIfNull: false)  String? category, @JsonKey(includeIfNull: false)  double? servingSizeG,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProduceCacheEntry() when $default != null:
return $default(_that.fdcId,_that.name,_that.nutrition,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.localizedNames,_that.pluCodes,_that.category,_that.servingSizeG,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int fdcId,  String name,  Map<String, double> nutrition,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt,  Map<String, String> localizedNames,  List<String> pluCodes, @JsonKey(includeIfNull: false)  String? category, @JsonKey(includeIfNull: false)  double? servingSizeG,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _ProduceCacheEntry():
return $default(_that.fdcId,_that.name,_that.nutrition,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.localizedNames,_that.pluCodes,_that.category,_that.servingSizeG,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int fdcId,  String name,  Map<String, double> nutrition,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt,  Map<String, String> localizedNames,  List<String> pluCodes, @JsonKey(includeIfNull: false)  String? category, @JsonKey(includeIfNull: false)  double? servingSizeG,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _ProduceCacheEntry() when $default != null:
return $default(_that.fdcId,_that.name,_that.nutrition,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.localizedNames,_that.pluCodes,_that.category,_that.servingSizeG,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProduceCacheEntry extends ProduceCacheEntry {
  const _ProduceCacheEntry({required this.fdcId, required this.name, required final  Map<String, double> nutrition, required this.createdAt, required this.lastRefreshedAt, required this.nextRefreshAt, final  Map<String, String> localizedNames = const {}, final  List<String> pluCodes = const <String>[], @JsonKey(includeIfNull: false) this.category, @JsonKey(includeIfNull: false) this.servingSizeG, this.schemaVersion = 1}): _nutrition = nutrition,_localizedNames = localizedNames,_pluCodes = pluCodes,super._();
  factory _ProduceCacheEntry.fromJson(Map<String, dynamic> json) => _$ProduceCacheEntryFromJson(json);

/// USDA FDC (FoodData Central) ID for this produce item.
///
/// Set to `0` when the FDC ID is not known (e.g. from fallback data).
@override final  int fdcId;
/// Lowercase English produce name used as the Firestore document ID
/// (e.g. `"apple"`, `"banana"`).
@override final  String name;
/// Nutrition per 100 g, keyed by nutrient name.
///
/// Known keys: `energyKcal`, `proteinG`, `carbsG`, `fatG`, `fiberG`.
/// An empty map means no nutrition data is available.
 final  Map<String, double> _nutrition;
/// Nutrition per 100 g, keyed by nutrient name.
///
/// Known keys: `energyKcal`, `proteinG`, `carbsG`, `fatG`, `fiberG`.
/// An empty map means no nutrition data is available.
@override Map<String, double> get nutrition {
  if (_nutrition is EqualUnmodifiableMapView) return _nutrition;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nutrition);
}

/// Epoch timestamp (ms) of when this entry was first created.
@override final  int createdAt;
/// Epoch timestamp (ms) of when this entry was last refreshed.
@override final  int lastRefreshedAt;
/// Epoch timestamp (ms) of when this entry should be refreshed next.
@override final  int nextRefreshAt;
/// Localized names keyed by locale code (e.g. `{"pt": "Maca"}`).
 final  Map<String, String> _localizedNames;
/// Localized names keyed by locale code (e.g. `{"pt": "Maca"}`).
@override@JsonKey() Map<String, String> get localizedNames {
  if (_localizedNames is EqualUnmodifiableMapView) return _localizedNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_localizedNames);
}

/// PLU (Price Look-Up) codes associated with this produce item.
 final  List<String> _pluCodes;
/// PLU (Price Look-Up) codes associated with this produce item.
@override@JsonKey() List<String> get pluCodes {
  if (_pluCodes is EqualUnmodifiableListView) return _pluCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pluCodes);
}

/// The USDA food category (e.g. `"Fruits and Fruit Juices"`).
@override@JsonKey(includeIfNull: false) final  String? category;
/// Suggested serving size in grams. Null when unknown.
@override@JsonKey(includeIfNull: false) final  double? servingSizeG;
/// Schema version for forward compatibility.
@override@JsonKey() final  int schemaVersion;

/// Create a copy of ProduceCacheEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProduceCacheEntryCopyWith<_ProduceCacheEntry> get copyWith => __$ProduceCacheEntryCopyWithImpl<_ProduceCacheEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProduceCacheEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProduceCacheEntry&&(identical(other.fdcId, fdcId) || other.fdcId == fdcId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._nutrition, _nutrition)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastRefreshedAt, lastRefreshedAt) || other.lastRefreshedAt == lastRefreshedAt)&&(identical(other.nextRefreshAt, nextRefreshAt) || other.nextRefreshAt == nextRefreshAt)&&const DeepCollectionEquality().equals(other._localizedNames, _localizedNames)&&const DeepCollectionEquality().equals(other._pluCodes, _pluCodes)&&(identical(other.category, category) || other.category == category)&&(identical(other.servingSizeG, servingSizeG) || other.servingSizeG == servingSizeG)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fdcId,name,const DeepCollectionEquality().hash(_nutrition),createdAt,lastRefreshedAt,nextRefreshAt,const DeepCollectionEquality().hash(_localizedNames),const DeepCollectionEquality().hash(_pluCodes),category,servingSizeG,schemaVersion);

@override
String toString() {
  return 'ProduceCacheEntry(fdcId: $fdcId, name: $name, nutrition: $nutrition, createdAt: $createdAt, lastRefreshedAt: $lastRefreshedAt, nextRefreshAt: $nextRefreshAt, localizedNames: $localizedNames, pluCodes: $pluCodes, category: $category, servingSizeG: $servingSizeG, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$ProduceCacheEntryCopyWith<$Res> implements $ProduceCacheEntryCopyWith<$Res> {
  factory _$ProduceCacheEntryCopyWith(_ProduceCacheEntry value, $Res Function(_ProduceCacheEntry) _then) = __$ProduceCacheEntryCopyWithImpl;
@override @useResult
$Res call({
 int fdcId, String name, Map<String, double> nutrition, int createdAt, int lastRefreshedAt, int nextRefreshAt, Map<String, String> localizedNames, List<String> pluCodes,@JsonKey(includeIfNull: false) String? category,@JsonKey(includeIfNull: false) double? servingSizeG, int schemaVersion
});




}
/// @nodoc
class __$ProduceCacheEntryCopyWithImpl<$Res>
    implements _$ProduceCacheEntryCopyWith<$Res> {
  __$ProduceCacheEntryCopyWithImpl(this._self, this._then);

  final _ProduceCacheEntry _self;
  final $Res Function(_ProduceCacheEntry) _then;

/// Create a copy of ProduceCacheEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fdcId = null,Object? name = null,Object? nutrition = null,Object? createdAt = null,Object? lastRefreshedAt = null,Object? nextRefreshAt = null,Object? localizedNames = null,Object? pluCodes = null,Object? category = freezed,Object? servingSizeG = freezed,Object? schemaVersion = null,}) {
  return _then(_ProduceCacheEntry(
fdcId: null == fdcId ? _self.fdcId : fdcId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nutrition: null == nutrition ? _self._nutrition : nutrition // ignore: cast_nullable_to_non_nullable
as Map<String, double>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,lastRefreshedAt: null == lastRefreshedAt ? _self.lastRefreshedAt : lastRefreshedAt // ignore: cast_nullable_to_non_nullable
as int,nextRefreshAt: null == nextRefreshAt ? _self.nextRefreshAt : nextRefreshAt // ignore: cast_nullable_to_non_nullable
as int,localizedNames: null == localizedNames ? _self._localizedNames : localizedNames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,pluCodes: null == pluCodes ? _self._pluCodes : pluCodes // ignore: cast_nullable_to_non_nullable
as List<String>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,servingSizeG: freezed == servingSizeG ? _self.servingSizeG : servingSizeG // ignore: cast_nullable_to_non_nullable
as double?,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
