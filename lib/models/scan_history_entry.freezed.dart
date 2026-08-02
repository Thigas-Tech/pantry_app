// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScanHistoryEntry {

/// The scanned product's barcode or PLU code.
 String get barcode;/// The product name known at scan time.
 String get name;/// Epoch millis timestamp of when the scan happened.
 int get scannedAt;/// Auto-increment primary key from the scan_history table.
 int? get id;/// Optional product image URL for display in recent-scans lists.
 String? get imageUrl;
/// Create a copy of ScanHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanHistoryEntryCopyWith<ScanHistoryEntry> get copyWith => _$ScanHistoryEntryCopyWithImpl<ScanHistoryEntry>(this as ScanHistoryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanHistoryEntry&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.scannedAt, scannedAt) || other.scannedAt == scannedAt)&&(identical(other.id, id) || other.id == id)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,barcode,name,scannedAt,id,imageUrl);

@override
String toString() {
  return 'ScanHistoryEntry(barcode: $barcode, name: $name, scannedAt: $scannedAt, id: $id, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $ScanHistoryEntryCopyWith<$Res>  {
  factory $ScanHistoryEntryCopyWith(ScanHistoryEntry value, $Res Function(ScanHistoryEntry) _then) = _$ScanHistoryEntryCopyWithImpl;
@useResult
$Res call({
 String barcode, String name, int scannedAt, int? id, String? imageUrl
});




}
/// @nodoc
class _$ScanHistoryEntryCopyWithImpl<$Res>
    implements $ScanHistoryEntryCopyWith<$Res> {
  _$ScanHistoryEntryCopyWithImpl(this._self, this._then);

  final ScanHistoryEntry _self;
  final $Res Function(ScanHistoryEntry) _then;

/// Create a copy of ScanHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? barcode = null,Object? name = null,Object? scannedAt = null,Object? id = freezed,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,scannedAt: null == scannedAt ? _self.scannedAt : scannedAt // ignore: cast_nullable_to_non_nullable
as int,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanHistoryEntry].
extension ScanHistoryEntryPatterns on ScanHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _ScanHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ScanHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String barcode,  String name,  int scannedAt,  int? id,  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanHistoryEntry() when $default != null:
return $default(_that.barcode,_that.name,_that.scannedAt,_that.id,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String barcode,  String name,  int scannedAt,  int? id,  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _ScanHistoryEntry():
return $default(_that.barcode,_that.name,_that.scannedAt,_that.id,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String barcode,  String name,  int scannedAt,  int? id,  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _ScanHistoryEntry() when $default != null:
return $default(_that.barcode,_that.name,_that.scannedAt,_that.id,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _ScanHistoryEntry implements ScanHistoryEntry {
  const _ScanHistoryEntry({required this.barcode, required this.name, required this.scannedAt, this.id, this.imageUrl});
  

/// The scanned product's barcode or PLU code.
@override final  String barcode;
/// The product name known at scan time.
@override final  String name;
/// Epoch millis timestamp of when the scan happened.
@override final  int scannedAt;
/// Auto-increment primary key from the scan_history table.
@override final  int? id;
/// Optional product image URL for display in recent-scans lists.
@override final  String? imageUrl;

/// Create a copy of ScanHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanHistoryEntryCopyWith<_ScanHistoryEntry> get copyWith => __$ScanHistoryEntryCopyWithImpl<_ScanHistoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanHistoryEntry&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.scannedAt, scannedAt) || other.scannedAt == scannedAt)&&(identical(other.id, id) || other.id == id)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,barcode,name,scannedAt,id,imageUrl);

@override
String toString() {
  return 'ScanHistoryEntry(barcode: $barcode, name: $name, scannedAt: $scannedAt, id: $id, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$ScanHistoryEntryCopyWith<$Res> implements $ScanHistoryEntryCopyWith<$Res> {
  factory _$ScanHistoryEntryCopyWith(_ScanHistoryEntry value, $Res Function(_ScanHistoryEntry) _then) = __$ScanHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String barcode, String name, int scannedAt, int? id, String? imageUrl
});




}
/// @nodoc
class __$ScanHistoryEntryCopyWithImpl<$Res>
    implements _$ScanHistoryEntryCopyWith<$Res> {
  __$ScanHistoryEntryCopyWithImpl(this._self, this._then);

  final _ScanHistoryEntry _self;
  final $Res Function(_ScanHistoryEntry) _then;

/// Create a copy of ScanHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? barcode = null,Object? name = null,Object? scannedAt = null,Object? id = freezed,Object? imageUrl = freezed,}) {
  return _then(_ScanHistoryEntry(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,scannedAt: null == scannedAt ? _self.scannedAt : scannedAt // ignore: cast_nullable_to_non_nullable
as int,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
