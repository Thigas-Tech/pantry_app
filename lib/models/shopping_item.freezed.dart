// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShoppingItem {

/// Free-form product name or the linked product's name.
 String get name;/// The linked product barcode, or null for free-text items.
 String? get barcode;/// Desired quantity to purchase. Defaults to 1.0.
 double get quantity;/// Unit for [quantity] (e.g. 'pieces', 'g', 'ml').
 String get unit;/// Whether this item has been purchased.
 bool get isPurchased;/// Auto-increment primary key.
 int? get id;/// Target pantry for move-to-inventory, or null if not set.
 int? get inventoryId;/// Epoch timestamp (milliseconds since Unix epoch) of when the item
/// was added to the shopping list.
 int? get dateAdded;/// Epoch timestamp (milliseconds since Unix epoch) of when the item
/// was marked as purchased.
 int? get datePurchased;/// Price entered while shopping, or null if no price was set.
 double? get priceAmount;/// ISO 4217 currency code for [priceAmount] (e.g. 'USD', 'BRL').
 String? get priceCurrency;/// Store where the item was or will be purchased.
 String? get priceStore;/// Package size the recorded price applies to (e.g. 12 for a dozen
/// eggs). Carried into the prices table when the item is moved to the
/// pantry so unit prices and recipe scaling keep working.
 double? get pricePackageQuantity;/// Unit for [pricePackageQuantity] (e.g. 'pieces', 'g', 'L').
 String? get pricePackageUnit;/// Optional expiry date in ISO 8601 format (YYYY-MM-DD), mirroring
/// [InventoryItem.expiryDate]. Captured for market trip items so it can
/// be carried into the pantry when the trip is finished.
 String? get expiryDate;/// Manual ordering position for pending items. Defaults to 0.
 double get sortOrder;
/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShoppingItemCopyWith<ShoppingItem> get copyWith => _$ShoppingItemCopyWithImpl<ShoppingItem>(this as ShoppingItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingItem&&(identical(other.name, name) || other.name == name)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.isPurchased, isPurchased) || other.isPurchased == isPurchased)&&(identical(other.id, id) || other.id == id)&&(identical(other.inventoryId, inventoryId) || other.inventoryId == inventoryId)&&(identical(other.dateAdded, dateAdded) || other.dateAdded == dateAdded)&&(identical(other.datePurchased, datePurchased) || other.datePurchased == datePurchased)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.priceCurrency, priceCurrency) || other.priceCurrency == priceCurrency)&&(identical(other.priceStore, priceStore) || other.priceStore == priceStore)&&(identical(other.pricePackageQuantity, pricePackageQuantity) || other.pricePackageQuantity == pricePackageQuantity)&&(identical(other.pricePackageUnit, pricePackageUnit) || other.pricePackageUnit == pricePackageUnit)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,name,barcode,quantity,unit,isPurchased,id,inventoryId,dateAdded,datePurchased,priceAmount,priceCurrency,priceStore,pricePackageQuantity,pricePackageUnit,expiryDate,sortOrder);

@override
String toString() {
  return 'ShoppingItem(name: $name, barcode: $barcode, quantity: $quantity, unit: $unit, isPurchased: $isPurchased, id: $id, inventoryId: $inventoryId, dateAdded: $dateAdded, datePurchased: $datePurchased, priceAmount: $priceAmount, priceCurrency: $priceCurrency, priceStore: $priceStore, pricePackageQuantity: $pricePackageQuantity, pricePackageUnit: $pricePackageUnit, expiryDate: $expiryDate, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ShoppingItemCopyWith<$Res>  {
  factory $ShoppingItemCopyWith(ShoppingItem value, $Res Function(ShoppingItem) _then) = _$ShoppingItemCopyWithImpl;
@useResult
$Res call({
 String name, String? barcode, double quantity, String unit, bool isPurchased, int? id, int? inventoryId, int? dateAdded, int? datePurchased, double? priceAmount, String? priceCurrency, String? priceStore, double? pricePackageQuantity, String? pricePackageUnit, String? expiryDate, double sortOrder
});




}
/// @nodoc
class _$ShoppingItemCopyWithImpl<$Res>
    implements $ShoppingItemCopyWith<$Res> {
  _$ShoppingItemCopyWithImpl(this._self, this._then);

  final ShoppingItem _self;
  final $Res Function(ShoppingItem) _then;

/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? barcode = freezed,Object? quantity = null,Object? unit = null,Object? isPurchased = null,Object? id = freezed,Object? inventoryId = freezed,Object? dateAdded = freezed,Object? datePurchased = freezed,Object? priceAmount = freezed,Object? priceCurrency = freezed,Object? priceStore = freezed,Object? pricePackageQuantity = freezed,Object? pricePackageUnit = freezed,Object? expiryDate = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,isPurchased: null == isPurchased ? _self.isPurchased : isPurchased // ignore: cast_nullable_to_non_nullable
as bool,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,inventoryId: freezed == inventoryId ? _self.inventoryId : inventoryId // ignore: cast_nullable_to_non_nullable
as int?,dateAdded: freezed == dateAdded ? _self.dateAdded : dateAdded // ignore: cast_nullable_to_non_nullable
as int?,datePurchased: freezed == datePurchased ? _self.datePurchased : datePurchased // ignore: cast_nullable_to_non_nullable
as int?,priceAmount: freezed == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as double?,priceCurrency: freezed == priceCurrency ? _self.priceCurrency : priceCurrency // ignore: cast_nullable_to_non_nullable
as String?,priceStore: freezed == priceStore ? _self.priceStore : priceStore // ignore: cast_nullable_to_non_nullable
as String?,pricePackageQuantity: freezed == pricePackageQuantity ? _self.pricePackageQuantity : pricePackageQuantity // ignore: cast_nullable_to_non_nullable
as double?,pricePackageUnit: freezed == pricePackageUnit ? _self.pricePackageUnit : pricePackageUnit // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ShoppingItem].
extension ShoppingItemPatterns on ShoppingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShoppingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShoppingItem value)  $default,){
final _that = this;
switch (_that) {
case _ShoppingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShoppingItem value)?  $default,){
final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? barcode,  double quantity,  String unit,  bool isPurchased,  int? id,  int? inventoryId,  int? dateAdded,  int? datePurchased,  double? priceAmount,  String? priceCurrency,  String? priceStore,  double? pricePackageQuantity,  String? pricePackageUnit,  String? expiryDate,  double sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
return $default(_that.name,_that.barcode,_that.quantity,_that.unit,_that.isPurchased,_that.id,_that.inventoryId,_that.dateAdded,_that.datePurchased,_that.priceAmount,_that.priceCurrency,_that.priceStore,_that.pricePackageQuantity,_that.pricePackageUnit,_that.expiryDate,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? barcode,  double quantity,  String unit,  bool isPurchased,  int? id,  int? inventoryId,  int? dateAdded,  int? datePurchased,  double? priceAmount,  String? priceCurrency,  String? priceStore,  double? pricePackageQuantity,  String? pricePackageUnit,  String? expiryDate,  double sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ShoppingItem():
return $default(_that.name,_that.barcode,_that.quantity,_that.unit,_that.isPurchased,_that.id,_that.inventoryId,_that.dateAdded,_that.datePurchased,_that.priceAmount,_that.priceCurrency,_that.priceStore,_that.pricePackageQuantity,_that.pricePackageUnit,_that.expiryDate,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? barcode,  double quantity,  String unit,  bool isPurchased,  int? id,  int? inventoryId,  int? dateAdded,  int? datePurchased,  double? priceAmount,  String? priceCurrency,  String? priceStore,  double? pricePackageQuantity,  String? pricePackageUnit,  String? expiryDate,  double sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
return $default(_that.name,_that.barcode,_that.quantity,_that.unit,_that.isPurchased,_that.id,_that.inventoryId,_that.dateAdded,_that.datePurchased,_that.priceAmount,_that.priceCurrency,_that.priceStore,_that.pricePackageQuantity,_that.pricePackageUnit,_that.expiryDate,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _ShoppingItem implements ShoppingItem {
  const _ShoppingItem({required this.name, this.barcode, this.quantity = 1.0, this.unit = 'pieces', this.isPurchased = false, this.id, this.inventoryId, this.dateAdded, this.datePurchased, this.priceAmount, this.priceCurrency, this.priceStore, this.pricePackageQuantity, this.pricePackageUnit, this.expiryDate, this.sortOrder = 0});
  

/// Free-form product name or the linked product's name.
@override final  String name;
/// The linked product barcode, or null for free-text items.
@override final  String? barcode;
/// Desired quantity to purchase. Defaults to 1.0.
@override@JsonKey() final  double quantity;
/// Unit for [quantity] (e.g. 'pieces', 'g', 'ml').
@override@JsonKey() final  String unit;
/// Whether this item has been purchased.
@override@JsonKey() final  bool isPurchased;
/// Auto-increment primary key.
@override final  int? id;
/// Target pantry for move-to-inventory, or null if not set.
@override final  int? inventoryId;
/// Epoch timestamp (milliseconds since Unix epoch) of when the item
/// was added to the shopping list.
@override final  int? dateAdded;
/// Epoch timestamp (milliseconds since Unix epoch) of when the item
/// was marked as purchased.
@override final  int? datePurchased;
/// Price entered while shopping, or null if no price was set.
@override final  double? priceAmount;
/// ISO 4217 currency code for [priceAmount] (e.g. 'USD', 'BRL').
@override final  String? priceCurrency;
/// Store where the item was or will be purchased.
@override final  String? priceStore;
/// Package size the recorded price applies to (e.g. 12 for a dozen
/// eggs). Carried into the prices table when the item is moved to the
/// pantry so unit prices and recipe scaling keep working.
@override final  double? pricePackageQuantity;
/// Unit for [pricePackageQuantity] (e.g. 'pieces', 'g', 'L').
@override final  String? pricePackageUnit;
/// Optional expiry date in ISO 8601 format (YYYY-MM-DD), mirroring
/// [InventoryItem.expiryDate]. Captured for market trip items so it can
/// be carried into the pantry when the trip is finished.
@override final  String? expiryDate;
/// Manual ordering position for pending items. Defaults to 0.
@override@JsonKey() final  double sortOrder;

/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShoppingItemCopyWith<_ShoppingItem> get copyWith => __$ShoppingItemCopyWithImpl<_ShoppingItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShoppingItem&&(identical(other.name, name) || other.name == name)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.isPurchased, isPurchased) || other.isPurchased == isPurchased)&&(identical(other.id, id) || other.id == id)&&(identical(other.inventoryId, inventoryId) || other.inventoryId == inventoryId)&&(identical(other.dateAdded, dateAdded) || other.dateAdded == dateAdded)&&(identical(other.datePurchased, datePurchased) || other.datePurchased == datePurchased)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.priceCurrency, priceCurrency) || other.priceCurrency == priceCurrency)&&(identical(other.priceStore, priceStore) || other.priceStore == priceStore)&&(identical(other.pricePackageQuantity, pricePackageQuantity) || other.pricePackageQuantity == pricePackageQuantity)&&(identical(other.pricePackageUnit, pricePackageUnit) || other.pricePackageUnit == pricePackageUnit)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,name,barcode,quantity,unit,isPurchased,id,inventoryId,dateAdded,datePurchased,priceAmount,priceCurrency,priceStore,pricePackageQuantity,pricePackageUnit,expiryDate,sortOrder);

@override
String toString() {
  return 'ShoppingItem(name: $name, barcode: $barcode, quantity: $quantity, unit: $unit, isPurchased: $isPurchased, id: $id, inventoryId: $inventoryId, dateAdded: $dateAdded, datePurchased: $datePurchased, priceAmount: $priceAmount, priceCurrency: $priceCurrency, priceStore: $priceStore, pricePackageQuantity: $pricePackageQuantity, pricePackageUnit: $pricePackageUnit, expiryDate: $expiryDate, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ShoppingItemCopyWith<$Res> implements $ShoppingItemCopyWith<$Res> {
  factory _$ShoppingItemCopyWith(_ShoppingItem value, $Res Function(_ShoppingItem) _then) = __$ShoppingItemCopyWithImpl;
@override @useResult
$Res call({
 String name, String? barcode, double quantity, String unit, bool isPurchased, int? id, int? inventoryId, int? dateAdded, int? datePurchased, double? priceAmount, String? priceCurrency, String? priceStore, double? pricePackageQuantity, String? pricePackageUnit, String? expiryDate, double sortOrder
});




}
/// @nodoc
class __$ShoppingItemCopyWithImpl<$Res>
    implements _$ShoppingItemCopyWith<$Res> {
  __$ShoppingItemCopyWithImpl(this._self, this._then);

  final _ShoppingItem _self;
  final $Res Function(_ShoppingItem) _then;

/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? barcode = freezed,Object? quantity = null,Object? unit = null,Object? isPurchased = null,Object? id = freezed,Object? inventoryId = freezed,Object? dateAdded = freezed,Object? datePurchased = freezed,Object? priceAmount = freezed,Object? priceCurrency = freezed,Object? priceStore = freezed,Object? pricePackageQuantity = freezed,Object? pricePackageUnit = freezed,Object? expiryDate = freezed,Object? sortOrder = null,}) {
  return _then(_ShoppingItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,isPurchased: null == isPurchased ? _self.isPurchased : isPurchased // ignore: cast_nullable_to_non_nullable
as bool,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,inventoryId: freezed == inventoryId ? _self.inventoryId : inventoryId // ignore: cast_nullable_to_non_nullable
as int?,dateAdded: freezed == dateAdded ? _self.dateAdded : dateAdded // ignore: cast_nullable_to_non_nullable
as int?,datePurchased: freezed == datePurchased ? _self.datePurchased : datePurchased // ignore: cast_nullable_to_non_nullable
as int?,priceAmount: freezed == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as double?,priceCurrency: freezed == priceCurrency ? _self.priceCurrency : priceCurrency // ignore: cast_nullable_to_non_nullable
as String?,priceStore: freezed == priceStore ? _self.priceStore : priceStore // ignore: cast_nullable_to_non_nullable
as String?,pricePackageQuantity: freezed == pricePackageQuantity ? _self.pricePackageQuantity : pricePackageQuantity // ignore: cast_nullable_to_non_nullable
as double?,pricePackageUnit: freezed == pricePackageUnit ? _self.pricePackageUnit : pricePackageUnit // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
