// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_ingredient_cache.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeIngredientCache {

/// Ingredient display name.
 String get name;/// Optional product barcode for price/nutrition lookup.
@JsonKey(includeIfNull: false) String? get barcode;/// Quantity, defaults to 1.
 double get quantity;/// Unit of measurement, defaults to 'pieces'.
 String get unit;
/// Create a copy of RecipeIngredientCache
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeIngredientCacheCopyWith<RecipeIngredientCache> get copyWith => _$RecipeIngredientCacheCopyWithImpl<RecipeIngredientCache>(this as RecipeIngredientCache, _$identity);

  /// Serializes this RecipeIngredientCache to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeIngredientCache&&(identical(other.name, name) || other.name == name)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,barcode,quantity,unit);

@override
String toString() {
  return 'RecipeIngredientCache(name: $name, barcode: $barcode, quantity: $quantity, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $RecipeIngredientCacheCopyWith<$Res>  {
  factory $RecipeIngredientCacheCopyWith(RecipeIngredientCache value, $Res Function(RecipeIngredientCache) _then) = _$RecipeIngredientCacheCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(includeIfNull: false) String? barcode, double quantity, String unit
});




}
/// @nodoc
class _$RecipeIngredientCacheCopyWithImpl<$Res>
    implements $RecipeIngredientCacheCopyWith<$Res> {
  _$RecipeIngredientCacheCopyWithImpl(this._self, this._then);

  final RecipeIngredientCache _self;
  final $Res Function(RecipeIngredientCache) _then;

/// Create a copy of RecipeIngredientCache
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? barcode = freezed,Object? quantity = null,Object? unit = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeIngredientCache].
extension RecipeIngredientCachePatterns on RecipeIngredientCache {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeIngredientCache value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeIngredientCache() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeIngredientCache value)  $default,){
final _that = this;
switch (_that) {
case _RecipeIngredientCache():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeIngredientCache value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeIngredientCache() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(includeIfNull: false)  String? barcode,  double quantity,  String unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeIngredientCache() when $default != null:
return $default(_that.name,_that.barcode,_that.quantity,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(includeIfNull: false)  String? barcode,  double quantity,  String unit)  $default,) {final _that = this;
switch (_that) {
case _RecipeIngredientCache():
return $default(_that.name,_that.barcode,_that.quantity,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(includeIfNull: false)  String? barcode,  double quantity,  String unit)?  $default,) {final _that = this;
switch (_that) {
case _RecipeIngredientCache() when $default != null:
return $default(_that.name,_that.barcode,_that.quantity,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeIngredientCache extends RecipeIngredientCache {
  const _RecipeIngredientCache({required this.name, @JsonKey(includeIfNull: false) this.barcode, this.quantity = 1.0, this.unit = 'pieces'}): super._();
  factory _RecipeIngredientCache.fromJson(Map<String, dynamic> json) => _$RecipeIngredientCacheFromJson(json);

/// Ingredient display name.
@override final  String name;
/// Optional product barcode for price/nutrition lookup.
@override@JsonKey(includeIfNull: false) final  String? barcode;
/// Quantity, defaults to 1.
@override@JsonKey() final  double quantity;
/// Unit of measurement, defaults to 'pieces'.
@override@JsonKey() final  String unit;

/// Create a copy of RecipeIngredientCache
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeIngredientCacheCopyWith<_RecipeIngredientCache> get copyWith => __$RecipeIngredientCacheCopyWithImpl<_RecipeIngredientCache>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeIngredientCacheToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeIngredientCache&&(identical(other.name, name) || other.name == name)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,barcode,quantity,unit);

@override
String toString() {
  return 'RecipeIngredientCache(name: $name, barcode: $barcode, quantity: $quantity, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$RecipeIngredientCacheCopyWith<$Res> implements $RecipeIngredientCacheCopyWith<$Res> {
  factory _$RecipeIngredientCacheCopyWith(_RecipeIngredientCache value, $Res Function(_RecipeIngredientCache) _then) = __$RecipeIngredientCacheCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(includeIfNull: false) String? barcode, double quantity, String unit
});




}
/// @nodoc
class __$RecipeIngredientCacheCopyWithImpl<$Res>
    implements _$RecipeIngredientCacheCopyWith<$Res> {
  __$RecipeIngredientCacheCopyWithImpl(this._self, this._then);

  final _RecipeIngredientCache _self;
  final $Res Function(_RecipeIngredientCache) _then;

/// Create a copy of RecipeIngredientCache
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? barcode = freezed,Object? quantity = null,Object? unit = null,}) {
  return _then(_RecipeIngredientCache(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
