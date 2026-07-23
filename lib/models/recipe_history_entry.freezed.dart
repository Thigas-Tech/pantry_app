// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecipeHistoryEntry {

/// Auto-increment primary key from the recipe_history table.
 int? get id;/// Foreign key referencing the cooked recipe.
 int get recipeId;/// Epoch millis timestamp of when the recipe was made.
 int get madeAt;/// Total recipe cost computed at cook time.
 double get costAtTime;/// JSON-encoded snapshot of `[{barcode, name, quantity, unit}]` at cook
/// time, so the entry is accurate even if the recipe changes later.
 String get ingredientSnapshot;
/// Create a copy of RecipeHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeHistoryEntryCopyWith<RecipeHistoryEntry> get copyWith => _$RecipeHistoryEntryCopyWithImpl<RecipeHistoryEntry>(this as RecipeHistoryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeHistoryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.madeAt, madeAt) || other.madeAt == madeAt)&&(identical(other.costAtTime, costAtTime) || other.costAtTime == costAtTime)&&(identical(other.ingredientSnapshot, ingredientSnapshot) || other.ingredientSnapshot == ingredientSnapshot));
}


@override
int get hashCode => Object.hash(runtimeType,id,recipeId,madeAt,costAtTime,ingredientSnapshot);

@override
String toString() {
  return 'RecipeHistoryEntry(id: $id, recipeId: $recipeId, madeAt: $madeAt, costAtTime: $costAtTime, ingredientSnapshot: $ingredientSnapshot)';
}


}

/// @nodoc
abstract mixin class $RecipeHistoryEntryCopyWith<$Res>  {
  factory $RecipeHistoryEntryCopyWith(RecipeHistoryEntry value, $Res Function(RecipeHistoryEntry) _then) = _$RecipeHistoryEntryCopyWithImpl;
@useResult
$Res call({
 int? id, int recipeId, int madeAt, double costAtTime, String ingredientSnapshot
});




}
/// @nodoc
class _$RecipeHistoryEntryCopyWithImpl<$Res>
    implements $RecipeHistoryEntryCopyWith<$Res> {
  _$RecipeHistoryEntryCopyWithImpl(this._self, this._then);

  final RecipeHistoryEntry _self;
  final $Res Function(RecipeHistoryEntry) _then;

/// Create a copy of RecipeHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? recipeId = null,Object? madeAt = null,Object? costAtTime = null,Object? ingredientSnapshot = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,recipeId: null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as int,madeAt: null == madeAt ? _self.madeAt : madeAt // ignore: cast_nullable_to_non_nullable
as int,costAtTime: null == costAtTime ? _self.costAtTime : costAtTime // ignore: cast_nullable_to_non_nullable
as double,ingredientSnapshot: null == ingredientSnapshot ? _self.ingredientSnapshot : ingredientSnapshot // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeHistoryEntry].
extension RecipeHistoryEntryPatterns on RecipeHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _RecipeHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  int recipeId,  int madeAt,  double costAtTime,  String ingredientSnapshot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeHistoryEntry() when $default != null:
return $default(_that.id,_that.recipeId,_that.madeAt,_that.costAtTime,_that.ingredientSnapshot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  int recipeId,  int madeAt,  double costAtTime,  String ingredientSnapshot)  $default,) {final _that = this;
switch (_that) {
case _RecipeHistoryEntry():
return $default(_that.id,_that.recipeId,_that.madeAt,_that.costAtTime,_that.ingredientSnapshot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  int recipeId,  int madeAt,  double costAtTime,  String ingredientSnapshot)?  $default,) {final _that = this;
switch (_that) {
case _RecipeHistoryEntry() when $default != null:
return $default(_that.id,_that.recipeId,_that.madeAt,_that.costAtTime,_that.ingredientSnapshot);case _:
  return null;

}
}

}

/// @nodoc


class _RecipeHistoryEntry implements RecipeHistoryEntry {
  const _RecipeHistoryEntry({this.id, required this.recipeId, required this.madeAt, this.costAtTime = 0.0, required this.ingredientSnapshot});
  

/// Auto-increment primary key from the recipe_history table.
@override final  int? id;
/// Foreign key referencing the cooked recipe.
@override final  int recipeId;
/// Epoch millis timestamp of when the recipe was made.
@override final  int madeAt;
/// Total recipe cost computed at cook time.
@override@JsonKey() final  double costAtTime;
/// JSON-encoded snapshot of `[{barcode, name, quantity, unit}]` at cook
/// time, so the entry is accurate even if the recipe changes later.
@override final  String ingredientSnapshot;

/// Create a copy of RecipeHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeHistoryEntryCopyWith<_RecipeHistoryEntry> get copyWith => __$RecipeHistoryEntryCopyWithImpl<_RecipeHistoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeHistoryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.madeAt, madeAt) || other.madeAt == madeAt)&&(identical(other.costAtTime, costAtTime) || other.costAtTime == costAtTime)&&(identical(other.ingredientSnapshot, ingredientSnapshot) || other.ingredientSnapshot == ingredientSnapshot));
}


@override
int get hashCode => Object.hash(runtimeType,id,recipeId,madeAt,costAtTime,ingredientSnapshot);

@override
String toString() {
  return 'RecipeHistoryEntry(id: $id, recipeId: $recipeId, madeAt: $madeAt, costAtTime: $costAtTime, ingredientSnapshot: $ingredientSnapshot)';
}


}

/// @nodoc
abstract mixin class _$RecipeHistoryEntryCopyWith<$Res> implements $RecipeHistoryEntryCopyWith<$Res> {
  factory _$RecipeHistoryEntryCopyWith(_RecipeHistoryEntry value, $Res Function(_RecipeHistoryEntry) _then) = __$RecipeHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 int? id, int recipeId, int madeAt, double costAtTime, String ingredientSnapshot
});




}
/// @nodoc
class __$RecipeHistoryEntryCopyWithImpl<$Res>
    implements _$RecipeHistoryEntryCopyWith<$Res> {
  __$RecipeHistoryEntryCopyWithImpl(this._self, this._then);

  final _RecipeHistoryEntry _self;
  final $Res Function(_RecipeHistoryEntry) _then;

/// Create a copy of RecipeHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? recipeId = null,Object? madeAt = null,Object? costAtTime = null,Object? ingredientSnapshot = null,}) {
  return _then(_RecipeHistoryEntry(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,recipeId: null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as int,madeAt: null == madeAt ? _self.madeAt : madeAt // ignore: cast_nullable_to_non_nullable
as int,costAtTime: null == costAtTime ? _self.costAtTime : costAtTime // ignore: cast_nullable_to_non_nullable
as double,ingredientSnapshot: null == ingredientSnapshot ? _self.ingredientSnapshot : ingredientSnapshot // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
