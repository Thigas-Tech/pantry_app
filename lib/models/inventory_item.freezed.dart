// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InventoryItem {

/// The barcode of the product (e.g. EAN‑13, UPC).
///
/// This is a foreign key referencing [Product.barcode] and must match an
/// existing product in the `products` table (or be added to it).
 String get barcode;/// The auto‑generated primary key from the database.
///
/// Set to `null` for items that have not yet been inserted. After
/// [DatabaseHelper.insertInventoryItem] returns, the generated ID is
/// available in the returned integer (the caller should update this field
/// if needed).
 int? get id;/// The quantity of the item, expressed in the given [unit].
///
/// The value is stored as a [double] to support fractional quantities
/// (e.g., `0.5` for half a pack). Defaults to `1`.
 double get quantity;/// The unit of measurement for [quantity].
///
/// Common values: `'pieces'`, `'g'`, `'kg'`, `'ml'`, `'L'`.
/// Defaults to `'pieces'`.
 String get unit;/// The expiry date in ISO 8601 format (`YYYY-MM-DD`).
///
/// May be `null` if the user has not set an expiry date. When present,
/// the date is treated as the last day the item is safe to consume
/// (inclusive).
///
/// The home screen uses this value to group items into expired /
/// expiring soon / good categories.
@JsonKey(name: 'expiry_date') String? get expiryDate;/// The storage location of the item.
///
/// Common values: `'pantry'`, `'fridge'`, `'freezer'`.
/// Defaults to `'pantry'`.
 String get location;/// Optional free‑form notes about this item.
 String? get notes;/// Epoch timestamp (milliseconds since Unix epoch) of when the item
/// was first added.
///
/// Set automatically when the user creates the item. Used by the
/// database cleanup routine to purge old entries after 60 days.
@JsonKey(name: 'date_added') int? get dateAdded;/// The ID of the inventory (pantry) this item belongs to.
///
/// This is a foreign key referencing the `inventories` table.
/// Defaults to `1` (the default "Home" inventory).
@JsonKey(name: 'inventory_id') int get inventoryId;/// The weight in grams of one serving unit.
///
/// Only meaningful for produce items added in unit mode (e.g. `182` for
/// "1 medium apple"). `null` for weight-mode items, non-produce items,
/// and legacy items without serving data.
@JsonKey(name: 'serving_weight_g') double? get servingWeightG;
/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryItemCopyWith<InventoryItem> get copyWith => _$InventoryItemCopyWithImpl<InventoryItem>(this as InventoryItem, _$identity);

  /// Serializes this InventoryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryItem&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.id, id) || other.id == id)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.location, location) || other.location == location)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dateAdded, dateAdded) || other.dateAdded == dateAdded)&&(identical(other.inventoryId, inventoryId) || other.inventoryId == inventoryId)&&(identical(other.servingWeightG, servingWeightG) || other.servingWeightG == servingWeightG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,barcode,id,quantity,unit,expiryDate,location,notes,dateAdded,inventoryId,servingWeightG);

@override
String toString() {
  return 'InventoryItem(barcode: $barcode, id: $id, quantity: $quantity, unit: $unit, expiryDate: $expiryDate, location: $location, notes: $notes, dateAdded: $dateAdded, inventoryId: $inventoryId, servingWeightG: $servingWeightG)';
}


}

/// @nodoc
abstract mixin class $InventoryItemCopyWith<$Res>  {
  factory $InventoryItemCopyWith(InventoryItem value, $Res Function(InventoryItem) _then) = _$InventoryItemCopyWithImpl;
@useResult
$Res call({
 String barcode, int? id, double quantity, String unit,@JsonKey(name: 'expiry_date') String? expiryDate, String location, String? notes,@JsonKey(name: 'date_added') int? dateAdded,@JsonKey(name: 'inventory_id') int inventoryId,@JsonKey(name: 'serving_weight_g') double? servingWeightG
});




}
/// @nodoc
class _$InventoryItemCopyWithImpl<$Res>
    implements $InventoryItemCopyWith<$Res> {
  _$InventoryItemCopyWithImpl(this._self, this._then);

  final InventoryItem _self;
  final $Res Function(InventoryItem) _then;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? barcode = null,Object? id = freezed,Object? quantity = null,Object? unit = null,Object? expiryDate = freezed,Object? location = null,Object? notes = freezed,Object? dateAdded = freezed,Object? inventoryId = null,Object? servingWeightG = freezed,}) {
  return _then(_self.copyWith(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dateAdded: freezed == dateAdded ? _self.dateAdded : dateAdded // ignore: cast_nullable_to_non_nullable
as int?,inventoryId: null == inventoryId ? _self.inventoryId : inventoryId // ignore: cast_nullable_to_non_nullable
as int,servingWeightG: freezed == servingWeightG ? _self.servingWeightG : servingWeightG // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryItem].
extension InventoryItemPatterns on InventoryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryItem value)  $default,){
final _that = this;
switch (_that) {
case _InventoryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryItem value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String barcode,  int? id,  double quantity,  String unit, @JsonKey(name: 'expiry_date')  String? expiryDate,  String location,  String? notes, @JsonKey(name: 'date_added')  int? dateAdded, @JsonKey(name: 'inventory_id')  int inventoryId, @JsonKey(name: 'serving_weight_g')  double? servingWeightG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryItem() when $default != null:
return $default(_that.barcode,_that.id,_that.quantity,_that.unit,_that.expiryDate,_that.location,_that.notes,_that.dateAdded,_that.inventoryId,_that.servingWeightG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String barcode,  int? id,  double quantity,  String unit, @JsonKey(name: 'expiry_date')  String? expiryDate,  String location,  String? notes, @JsonKey(name: 'date_added')  int? dateAdded, @JsonKey(name: 'inventory_id')  int inventoryId, @JsonKey(name: 'serving_weight_g')  double? servingWeightG)  $default,) {final _that = this;
switch (_that) {
case _InventoryItem():
return $default(_that.barcode,_that.id,_that.quantity,_that.unit,_that.expiryDate,_that.location,_that.notes,_that.dateAdded,_that.inventoryId,_that.servingWeightG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String barcode,  int? id,  double quantity,  String unit, @JsonKey(name: 'expiry_date')  String? expiryDate,  String location,  String? notes, @JsonKey(name: 'date_added')  int? dateAdded, @JsonKey(name: 'inventory_id')  int inventoryId, @JsonKey(name: 'serving_weight_g')  double? servingWeightG)?  $default,) {final _that = this;
switch (_that) {
case _InventoryItem() when $default != null:
return $default(_that.barcode,_that.id,_that.quantity,_that.unit,_that.expiryDate,_that.location,_that.notes,_that.dateAdded,_that.inventoryId,_that.servingWeightG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InventoryItem implements InventoryItem {
  const _InventoryItem({required this.barcode, this.id, this.quantity = 1, this.unit = 'pieces', @JsonKey(name: 'expiry_date') this.expiryDate, this.location = 'pantry', this.notes, @JsonKey(name: 'date_added') this.dateAdded, @JsonKey(name: 'inventory_id') this.inventoryId = 1, @JsonKey(name: 'serving_weight_g') this.servingWeightG});
  factory _InventoryItem.fromJson(Map<String, dynamic> json) => _$InventoryItemFromJson(json);

/// The barcode of the product (e.g. EAN‑13, UPC).
///
/// This is a foreign key referencing [Product.barcode] and must match an
/// existing product in the `products` table (or be added to it).
@override final  String barcode;
/// The auto‑generated primary key from the database.
///
/// Set to `null` for items that have not yet been inserted. After
/// [DatabaseHelper.insertInventoryItem] returns, the generated ID is
/// available in the returned integer (the caller should update this field
/// if needed).
@override final  int? id;
/// The quantity of the item, expressed in the given [unit].
///
/// The value is stored as a [double] to support fractional quantities
/// (e.g., `0.5` for half a pack). Defaults to `1`.
@override@JsonKey() final  double quantity;
/// The unit of measurement for [quantity].
///
/// Common values: `'pieces'`, `'g'`, `'kg'`, `'ml'`, `'L'`.
/// Defaults to `'pieces'`.
@override@JsonKey() final  String unit;
/// The expiry date in ISO 8601 format (`YYYY-MM-DD`).
///
/// May be `null` if the user has not set an expiry date. When present,
/// the date is treated as the last day the item is safe to consume
/// (inclusive).
///
/// The home screen uses this value to group items into expired /
/// expiring soon / good categories.
@override@JsonKey(name: 'expiry_date') final  String? expiryDate;
/// The storage location of the item.
///
/// Common values: `'pantry'`, `'fridge'`, `'freezer'`.
/// Defaults to `'pantry'`.
@override@JsonKey() final  String location;
/// Optional free‑form notes about this item.
@override final  String? notes;
/// Epoch timestamp (milliseconds since Unix epoch) of when the item
/// was first added.
///
/// Set automatically when the user creates the item. Used by the
/// database cleanup routine to purge old entries after 60 days.
@override@JsonKey(name: 'date_added') final  int? dateAdded;
/// The ID of the inventory (pantry) this item belongs to.
///
/// This is a foreign key referencing the `inventories` table.
/// Defaults to `1` (the default "Home" inventory).
@override@JsonKey(name: 'inventory_id') final  int inventoryId;
/// The weight in grams of one serving unit.
///
/// Only meaningful for produce items added in unit mode (e.g. `182` for
/// "1 medium apple"). `null` for weight-mode items, non-produce items,
/// and legacy items without serving data.
@override@JsonKey(name: 'serving_weight_g') final  double? servingWeightG;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryItemCopyWith<_InventoryItem> get copyWith => __$InventoryItemCopyWithImpl<_InventoryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InventoryItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryItem&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.id, id) || other.id == id)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.location, location) || other.location == location)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dateAdded, dateAdded) || other.dateAdded == dateAdded)&&(identical(other.inventoryId, inventoryId) || other.inventoryId == inventoryId)&&(identical(other.servingWeightG, servingWeightG) || other.servingWeightG == servingWeightG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,barcode,id,quantity,unit,expiryDate,location,notes,dateAdded,inventoryId,servingWeightG);

@override
String toString() {
  return 'InventoryItem(barcode: $barcode, id: $id, quantity: $quantity, unit: $unit, expiryDate: $expiryDate, location: $location, notes: $notes, dateAdded: $dateAdded, inventoryId: $inventoryId, servingWeightG: $servingWeightG)';
}


}

/// @nodoc
abstract mixin class _$InventoryItemCopyWith<$Res> implements $InventoryItemCopyWith<$Res> {
  factory _$InventoryItemCopyWith(_InventoryItem value, $Res Function(_InventoryItem) _then) = __$InventoryItemCopyWithImpl;
@override @useResult
$Res call({
 String barcode, int? id, double quantity, String unit,@JsonKey(name: 'expiry_date') String? expiryDate, String location, String? notes,@JsonKey(name: 'date_added') int? dateAdded,@JsonKey(name: 'inventory_id') int inventoryId,@JsonKey(name: 'serving_weight_g') double? servingWeightG
});




}
/// @nodoc
class __$InventoryItemCopyWithImpl<$Res>
    implements _$InventoryItemCopyWith<$Res> {
  __$InventoryItemCopyWithImpl(this._self, this._then);

  final _InventoryItem _self;
  final $Res Function(_InventoryItem) _then;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? barcode = null,Object? id = freezed,Object? quantity = null,Object? unit = null,Object? expiryDate = freezed,Object? location = null,Object? notes = freezed,Object? dateAdded = freezed,Object? inventoryId = null,Object? servingWeightG = freezed,}) {
  return _then(_InventoryItem(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dateAdded: freezed == dateAdded ? _self.dateAdded : dateAdded // ignore: cast_nullable_to_non_nullable
as int?,inventoryId: null == inventoryId ? _self.inventoryId : inventoryId // ignore: cast_nullable_to_non_nullable
as int,servingWeightG: freezed == servingWeightG ? _self.servingWeightG : servingWeightG // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
