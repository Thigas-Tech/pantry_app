// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_cache_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeCacheEntry {

/// Random UUID4 used as the Firestore doc ID.
 String get recipeId;/// Recipe display name.
 String get name;/// Free-text preparation instructions.
 String get instructions;/// Number of servings this recipe yields.
 int get servings;/// Anonymized ingredient list (no local IDs).
@JsonKey(fromJson: _ingredientsFromJson, toJson: _ingredientsToJson) List<RecipeIngredientCache> get ingredients;/// Epoch ms of first creation (copied from original recipe).
 int get createdAt;/// Epoch ms of last refresh.
 int get lastRefreshedAt;/// Epoch ms of next scheduled refresh.
 int get nextRefreshAt;/// Anonymous-auth uid of the user who shared the recipe.
///
/// Used by Firestore rules to scope create/update/delete of
/// recipe_cache documents to their author. Empty when not signed in.
 String get ingestedBy;/// Optional Firebase Storage URL for the recipe photo.
///
/// Null when no photo has been uploaded. Never a local file path.
@JsonKey(includeIfNull: false) String? get imageUrl;/// Schema version for forward compatibility.
 int get schemaVersion;
/// Create a copy of RecipeCacheEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeCacheEntryCopyWith<RecipeCacheEntry> get copyWith => _$RecipeCacheEntryCopyWithImpl<RecipeCacheEntry>(this as RecipeCacheEntry, _$identity);

  /// Serializes this RecipeCacheEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeCacheEntry&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.servings, servings) || other.servings == servings)&&const DeepCollectionEquality().equals(other.ingredients, ingredients)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastRefreshedAt, lastRefreshedAt) || other.lastRefreshedAt == lastRefreshedAt)&&(identical(other.nextRefreshAt, nextRefreshAt) || other.nextRefreshAt == nextRefreshAt)&&(identical(other.ingestedBy, ingestedBy) || other.ingestedBy == ingestedBy)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recipeId,name,instructions,servings,const DeepCollectionEquality().hash(ingredients),createdAt,lastRefreshedAt,nextRefreshAt,ingestedBy,imageUrl,schemaVersion);

@override
String toString() {
  return 'RecipeCacheEntry(recipeId: $recipeId, name: $name, instructions: $instructions, servings: $servings, ingredients: $ingredients, createdAt: $createdAt, lastRefreshedAt: $lastRefreshedAt, nextRefreshAt: $nextRefreshAt, ingestedBy: $ingestedBy, imageUrl: $imageUrl, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $RecipeCacheEntryCopyWith<$Res>  {
  factory $RecipeCacheEntryCopyWith(RecipeCacheEntry value, $Res Function(RecipeCacheEntry) _then) = _$RecipeCacheEntryCopyWithImpl;
@useResult
$Res call({
 String recipeId, String name, String instructions, int servings,@JsonKey(fromJson: _ingredientsFromJson, toJson: _ingredientsToJson) List<RecipeIngredientCache> ingredients, int createdAt, int lastRefreshedAt, int nextRefreshAt, String ingestedBy,@JsonKey(includeIfNull: false) String? imageUrl, int schemaVersion
});




}
/// @nodoc
class _$RecipeCacheEntryCopyWithImpl<$Res>
    implements $RecipeCacheEntryCopyWith<$Res> {
  _$RecipeCacheEntryCopyWithImpl(this._self, this._then);

  final RecipeCacheEntry _self;
  final $Res Function(RecipeCacheEntry) _then;

/// Create a copy of RecipeCacheEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recipeId = null,Object? name = null,Object? instructions = null,Object? servings = null,Object? ingredients = null,Object? createdAt = null,Object? lastRefreshedAt = null,Object? nextRefreshAt = null,Object? ingestedBy = null,Object? imageUrl = freezed,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
recipeId: null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredientCache>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,lastRefreshedAt: null == lastRefreshedAt ? _self.lastRefreshedAt : lastRefreshedAt // ignore: cast_nullable_to_non_nullable
as int,nextRefreshAt: null == nextRefreshAt ? _self.nextRefreshAt : nextRefreshAt // ignore: cast_nullable_to_non_nullable
as int,ingestedBy: null == ingestedBy ? _self.ingestedBy : ingestedBy // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeCacheEntry].
extension RecipeCacheEntryPatterns on RecipeCacheEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeCacheEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeCacheEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeCacheEntry value)  $default,){
final _that = this;
switch (_that) {
case _RecipeCacheEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeCacheEntry value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeCacheEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String recipeId,  String name,  String instructions,  int servings, @JsonKey(fromJson: _ingredientsFromJson, toJson: _ingredientsToJson)  List<RecipeIngredientCache> ingredients,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt,  String ingestedBy, @JsonKey(includeIfNull: false)  String? imageUrl,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeCacheEntry() when $default != null:
return $default(_that.recipeId,_that.name,_that.instructions,_that.servings,_that.ingredients,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.ingestedBy,_that.imageUrl,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String recipeId,  String name,  String instructions,  int servings, @JsonKey(fromJson: _ingredientsFromJson, toJson: _ingredientsToJson)  List<RecipeIngredientCache> ingredients,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt,  String ingestedBy, @JsonKey(includeIfNull: false)  String? imageUrl,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _RecipeCacheEntry():
return $default(_that.recipeId,_that.name,_that.instructions,_that.servings,_that.ingredients,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.ingestedBy,_that.imageUrl,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String recipeId,  String name,  String instructions,  int servings, @JsonKey(fromJson: _ingredientsFromJson, toJson: _ingredientsToJson)  List<RecipeIngredientCache> ingredients,  int createdAt,  int lastRefreshedAt,  int nextRefreshAt,  String ingestedBy, @JsonKey(includeIfNull: false)  String? imageUrl,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _RecipeCacheEntry() when $default != null:
return $default(_that.recipeId,_that.name,_that.instructions,_that.servings,_that.ingredients,_that.createdAt,_that.lastRefreshedAt,_that.nextRefreshAt,_that.ingestedBy,_that.imageUrl,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeCacheEntry extends RecipeCacheEntry {
  const _RecipeCacheEntry({required this.recipeId, required this.name, required this.instructions, required this.servings, @JsonKey(fromJson: _ingredientsFromJson, toJson: _ingredientsToJson) required final  List<RecipeIngredientCache> ingredients, required this.createdAt, required this.lastRefreshedAt, required this.nextRefreshAt, this.ingestedBy = '', @JsonKey(includeIfNull: false) this.imageUrl, this.schemaVersion = 1}): _ingredients = ingredients,super._();
  factory _RecipeCacheEntry.fromJson(Map<String, dynamic> json) => _$RecipeCacheEntryFromJson(json);

/// Random UUID4 used as the Firestore doc ID.
@override final  String recipeId;
/// Recipe display name.
@override final  String name;
/// Free-text preparation instructions.
@override final  String instructions;
/// Number of servings this recipe yields.
@override final  int servings;
/// Anonymized ingredient list (no local IDs).
 final  List<RecipeIngredientCache> _ingredients;
/// Anonymized ingredient list (no local IDs).
@override@JsonKey(fromJson: _ingredientsFromJson, toJson: _ingredientsToJson) List<RecipeIngredientCache> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}

/// Epoch ms of first creation (copied from original recipe).
@override final  int createdAt;
/// Epoch ms of last refresh.
@override final  int lastRefreshedAt;
/// Epoch ms of next scheduled refresh.
@override final  int nextRefreshAt;
/// Anonymous-auth uid of the user who shared the recipe.
///
/// Used by Firestore rules to scope create/update/delete of
/// recipe_cache documents to their author. Empty when not signed in.
@override@JsonKey() final  String ingestedBy;
/// Optional Firebase Storage URL for the recipe photo.
///
/// Null when no photo has been uploaded. Never a local file path.
@override@JsonKey(includeIfNull: false) final  String? imageUrl;
/// Schema version for forward compatibility.
@override@JsonKey() final  int schemaVersion;

/// Create a copy of RecipeCacheEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeCacheEntryCopyWith<_RecipeCacheEntry> get copyWith => __$RecipeCacheEntryCopyWithImpl<_RecipeCacheEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeCacheEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeCacheEntry&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.servings, servings) || other.servings == servings)&&const DeepCollectionEquality().equals(other._ingredients, _ingredients)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastRefreshedAt, lastRefreshedAt) || other.lastRefreshedAt == lastRefreshedAt)&&(identical(other.nextRefreshAt, nextRefreshAt) || other.nextRefreshAt == nextRefreshAt)&&(identical(other.ingestedBy, ingestedBy) || other.ingestedBy == ingestedBy)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recipeId,name,instructions,servings,const DeepCollectionEquality().hash(_ingredients),createdAt,lastRefreshedAt,nextRefreshAt,ingestedBy,imageUrl,schemaVersion);

@override
String toString() {
  return 'RecipeCacheEntry(recipeId: $recipeId, name: $name, instructions: $instructions, servings: $servings, ingredients: $ingredients, createdAt: $createdAt, lastRefreshedAt: $lastRefreshedAt, nextRefreshAt: $nextRefreshAt, ingestedBy: $ingestedBy, imageUrl: $imageUrl, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$RecipeCacheEntryCopyWith<$Res> implements $RecipeCacheEntryCopyWith<$Res> {
  factory _$RecipeCacheEntryCopyWith(_RecipeCacheEntry value, $Res Function(_RecipeCacheEntry) _then) = __$RecipeCacheEntryCopyWithImpl;
@override @useResult
$Res call({
 String recipeId, String name, String instructions, int servings,@JsonKey(fromJson: _ingredientsFromJson, toJson: _ingredientsToJson) List<RecipeIngredientCache> ingredients, int createdAt, int lastRefreshedAt, int nextRefreshAt, String ingestedBy,@JsonKey(includeIfNull: false) String? imageUrl, int schemaVersion
});




}
/// @nodoc
class __$RecipeCacheEntryCopyWithImpl<$Res>
    implements _$RecipeCacheEntryCopyWith<$Res> {
  __$RecipeCacheEntryCopyWithImpl(this._self, this._then);

  final _RecipeCacheEntry _self;
  final $Res Function(_RecipeCacheEntry) _then;

/// Create a copy of RecipeCacheEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recipeId = null,Object? name = null,Object? instructions = null,Object? servings = null,Object? ingredients = null,Object? createdAt = null,Object? lastRefreshedAt = null,Object? nextRefreshAt = null,Object? ingestedBy = null,Object? imageUrl = freezed,Object? schemaVersion = null,}) {
  return _then(_RecipeCacheEntry(
recipeId: null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredientCache>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,lastRefreshedAt: null == lastRefreshedAt ? _self.lastRefreshedAt : lastRefreshedAt // ignore: cast_nullable_to_non_nullable
as int,nextRefreshAt: null == nextRefreshAt ? _self.nextRefreshAt : nextRefreshAt // ignore: cast_nullable_to_non_nullable
as int,ingestedBy: null == ingestedBy ? _self.ingestedBy : ingestedBy // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
