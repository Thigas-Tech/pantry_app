// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_nutrient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductNutrient {

/// The Open Food Facts nutrient tag (e.g. 'vitamin-c', 'sodium').
 String get offTag;/// The nutrient value in [unit].
 double get value;/// The app-canonical unit ([OffUnitCatalog]) the [value] uses.
 String get unit;
/// Create a copy of ProductNutrient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductNutrientCopyWith<ProductNutrient> get copyWith => _$ProductNutrientCopyWithImpl<ProductNutrient>(this as ProductNutrient, _$identity);

  /// Serializes this ProductNutrient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductNutrient&&(identical(other.offTag, offTag) || other.offTag == offTag)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,offTag,value,unit);

@override
String toString() {
  return 'ProductNutrient(offTag: $offTag, value: $value, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $ProductNutrientCopyWith<$Res>  {
  factory $ProductNutrientCopyWith(ProductNutrient value, $Res Function(ProductNutrient) _then) = _$ProductNutrientCopyWithImpl;
@useResult
$Res call({
 String offTag, double value, String unit
});




}
/// @nodoc
class _$ProductNutrientCopyWithImpl<$Res>
    implements $ProductNutrientCopyWith<$Res> {
  _$ProductNutrientCopyWithImpl(this._self, this._then);

  final ProductNutrient _self;
  final $Res Function(ProductNutrient) _then;

/// Create a copy of ProductNutrient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? offTag = null,Object? value = null,Object? unit = null,}) {
  return _then(_self.copyWith(
offTag: null == offTag ? _self.offTag : offTag // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductNutrient].
extension ProductNutrientPatterns on ProductNutrient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductNutrient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductNutrient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductNutrient value)  $default,){
final _that = this;
switch (_that) {
case _ProductNutrient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductNutrient value)?  $default,){
final _that = this;
switch (_that) {
case _ProductNutrient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String offTag,  double value,  String unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductNutrient() when $default != null:
return $default(_that.offTag,_that.value,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String offTag,  double value,  String unit)  $default,) {final _that = this;
switch (_that) {
case _ProductNutrient():
return $default(_that.offTag,_that.value,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String offTag,  double value,  String unit)?  $default,) {final _that = this;
switch (_that) {
case _ProductNutrient() when $default != null:
return $default(_that.offTag,_that.value,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductNutrient implements ProductNutrient {
  const _ProductNutrient({required this.offTag, required this.value, required this.unit});
  factory _ProductNutrient.fromJson(Map<String, dynamic> json) => _$ProductNutrientFromJson(json);

/// The Open Food Facts nutrient tag (e.g. 'vitamin-c', 'sodium').
@override final  String offTag;
/// The nutrient value in [unit].
@override final  double value;
/// The app-canonical unit ([OffUnitCatalog]) the [value] uses.
@override final  String unit;

/// Create a copy of ProductNutrient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductNutrientCopyWith<_ProductNutrient> get copyWith => __$ProductNutrientCopyWithImpl<_ProductNutrient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductNutrientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductNutrient&&(identical(other.offTag, offTag) || other.offTag == offTag)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,offTag,value,unit);

@override
String toString() {
  return 'ProductNutrient(offTag: $offTag, value: $value, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$ProductNutrientCopyWith<$Res> implements $ProductNutrientCopyWith<$Res> {
  factory _$ProductNutrientCopyWith(_ProductNutrient value, $Res Function(_ProductNutrient) _then) = __$ProductNutrientCopyWithImpl;
@override @useResult
$Res call({
 String offTag, double value, String unit
});




}
/// @nodoc
class __$ProductNutrientCopyWithImpl<$Res>
    implements _$ProductNutrientCopyWith<$Res> {
  __$ProductNutrientCopyWithImpl(this._self, this._then);

  final _ProductNutrient _self;
  final $Res Function(_ProductNutrient) _then;

/// Create a copy of ProductNutrient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? offTag = null,Object? value = null,Object? unit = null,}) {
  return _then(_ProductNutrient(
offTag: null == offTag ? _self.offTag : offTag // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
