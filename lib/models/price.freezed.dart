// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Price {

/// The product barcode this price is associated with.
 String get barcode;/// The monetary amount (taxes included).
 double get price;/// ISO 4217 currency code (e.g. 'BRL', 'USD', 'EUR').
///
/// Defaults to 'USD'; auto-detected from locale on first launch.
 String get currency;/// Auto-increment primary key.
 int? get id;/// Free-form store or supermarket name.
 String? get store;/// Whether this is a discounted / sale price.
 bool get isDiscounted;/// Original price before discount, if [isDiscounted] is true.
 double? get regularPrice;/// Epoch timestamp (milliseconds since Unix epoch) of the purchase.
///
/// Defaults to the current time when no value is provided.
 int? get datePurchased;/// Open prices sync status.
///
/// - [priceSyncLocalOnly] — not shared (no proof photo).
/// - [priceSyncPending] — queued for sync.
/// - [priceSyncSynced] — successfully synced.
/// - [priceSyncFailed] — sync failed.
 String get syncStatus;/// Remote ID on Open Prices after successful sync.
 int? get openPricesId;/// OpenStreetMap node/way ID for the store location.
 String? get locationOsmId;/// OpenStreetMap location type (NODE, WAY, or RELATION).
 String? get locationOsmType;/// NFC-e receipt series (reserved for future tax receipt integration).
 String? get receiptSeries;/// NFC-e receipt number (reserved for future tax receipt integration).
 String? get receiptNumber;/// NFC-e line-item index (reserved for future tax receipt integration).
 int? get receiptItemIndex;/// Free-form notes about this price observation.
 String? get notes;/// Epoch timestamp (milliseconds since Unix epoch) of when this record
/// was created locally.
 int? get dateAdded;
/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceCopyWith<Price> get copyWith => _$PriceCopyWithImpl<Price>(this as Price, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Price&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.id, id) || other.id == id)&&(identical(other.store, store) || other.store == store)&&(identical(other.isDiscounted, isDiscounted) || other.isDiscounted == isDiscounted)&&(identical(other.regularPrice, regularPrice) || other.regularPrice == regularPrice)&&(identical(other.datePurchased, datePurchased) || other.datePurchased == datePurchased)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.openPricesId, openPricesId) || other.openPricesId == openPricesId)&&(identical(other.locationOsmId, locationOsmId) || other.locationOsmId == locationOsmId)&&(identical(other.locationOsmType, locationOsmType) || other.locationOsmType == locationOsmType)&&(identical(other.receiptSeries, receiptSeries) || other.receiptSeries == receiptSeries)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.receiptItemIndex, receiptItemIndex) || other.receiptItemIndex == receiptItemIndex)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dateAdded, dateAdded) || other.dateAdded == dateAdded));
}


@override
int get hashCode => Object.hash(runtimeType,barcode,price,currency,id,store,isDiscounted,regularPrice,datePurchased,syncStatus,openPricesId,locationOsmId,locationOsmType,receiptSeries,receiptNumber,receiptItemIndex,notes,dateAdded);

@override
String toString() {
  return 'Price(barcode: $barcode, price: $price, currency: $currency, id: $id, store: $store, isDiscounted: $isDiscounted, regularPrice: $regularPrice, datePurchased: $datePurchased, syncStatus: $syncStatus, openPricesId: $openPricesId, locationOsmId: $locationOsmId, locationOsmType: $locationOsmType, receiptSeries: $receiptSeries, receiptNumber: $receiptNumber, receiptItemIndex: $receiptItemIndex, notes: $notes, dateAdded: $dateAdded)';
}


}

/// @nodoc
abstract mixin class $PriceCopyWith<$Res>  {
  factory $PriceCopyWith(Price value, $Res Function(Price) _then) = _$PriceCopyWithImpl;
@useResult
$Res call({
 String barcode, double price, String currency, int? id, String? store, bool isDiscounted, double? regularPrice, int? datePurchased, String syncStatus, int? openPricesId, String? locationOsmId, String? locationOsmType, String? receiptSeries, String? receiptNumber, int? receiptItemIndex, String? notes, int? dateAdded
});




}
/// @nodoc
class _$PriceCopyWithImpl<$Res>
    implements $PriceCopyWith<$Res> {
  _$PriceCopyWithImpl(this._self, this._then);

  final Price _self;
  final $Res Function(Price) _then;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? barcode = null,Object? price = null,Object? currency = null,Object? id = freezed,Object? store = freezed,Object? isDiscounted = null,Object? regularPrice = freezed,Object? datePurchased = freezed,Object? syncStatus = null,Object? openPricesId = freezed,Object? locationOsmId = freezed,Object? locationOsmType = freezed,Object? receiptSeries = freezed,Object? receiptNumber = freezed,Object? receiptItemIndex = freezed,Object? notes = freezed,Object? dateAdded = freezed,}) {
  return _then(_self.copyWith(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,isDiscounted: null == isDiscounted ? _self.isDiscounted : isDiscounted // ignore: cast_nullable_to_non_nullable
as bool,regularPrice: freezed == regularPrice ? _self.regularPrice : regularPrice // ignore: cast_nullable_to_non_nullable
as double?,datePurchased: freezed == datePurchased ? _self.datePurchased : datePurchased // ignore: cast_nullable_to_non_nullable
as int?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as String,openPricesId: freezed == openPricesId ? _self.openPricesId : openPricesId // ignore: cast_nullable_to_non_nullable
as int?,locationOsmId: freezed == locationOsmId ? _self.locationOsmId : locationOsmId // ignore: cast_nullable_to_non_nullable
as String?,locationOsmType: freezed == locationOsmType ? _self.locationOsmType : locationOsmType // ignore: cast_nullable_to_non_nullable
as String?,receiptSeries: freezed == receiptSeries ? _self.receiptSeries : receiptSeries // ignore: cast_nullable_to_non_nullable
as String?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,receiptItemIndex: freezed == receiptItemIndex ? _self.receiptItemIndex : receiptItemIndex // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dateAdded: freezed == dateAdded ? _self.dateAdded : dateAdded // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Price].
extension PricePatterns on Price {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Price value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Price() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Price value)  $default,){
final _that = this;
switch (_that) {
case _Price():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Price value)?  $default,){
final _that = this;
switch (_that) {
case _Price() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String barcode,  double price,  String currency,  int? id,  String? store,  bool isDiscounted,  double? regularPrice,  int? datePurchased,  String syncStatus,  int? openPricesId,  String? locationOsmId,  String? locationOsmType,  String? receiptSeries,  String? receiptNumber,  int? receiptItemIndex,  String? notes,  int? dateAdded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Price() when $default != null:
return $default(_that.barcode,_that.price,_that.currency,_that.id,_that.store,_that.isDiscounted,_that.regularPrice,_that.datePurchased,_that.syncStatus,_that.openPricesId,_that.locationOsmId,_that.locationOsmType,_that.receiptSeries,_that.receiptNumber,_that.receiptItemIndex,_that.notes,_that.dateAdded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String barcode,  double price,  String currency,  int? id,  String? store,  bool isDiscounted,  double? regularPrice,  int? datePurchased,  String syncStatus,  int? openPricesId,  String? locationOsmId,  String? locationOsmType,  String? receiptSeries,  String? receiptNumber,  int? receiptItemIndex,  String? notes,  int? dateAdded)  $default,) {final _that = this;
switch (_that) {
case _Price():
return $default(_that.barcode,_that.price,_that.currency,_that.id,_that.store,_that.isDiscounted,_that.regularPrice,_that.datePurchased,_that.syncStatus,_that.openPricesId,_that.locationOsmId,_that.locationOsmType,_that.receiptSeries,_that.receiptNumber,_that.receiptItemIndex,_that.notes,_that.dateAdded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String barcode,  double price,  String currency,  int? id,  String? store,  bool isDiscounted,  double? regularPrice,  int? datePurchased,  String syncStatus,  int? openPricesId,  String? locationOsmId,  String? locationOsmType,  String? receiptSeries,  String? receiptNumber,  int? receiptItemIndex,  String? notes,  int? dateAdded)?  $default,) {final _that = this;
switch (_that) {
case _Price() when $default != null:
return $default(_that.barcode,_that.price,_that.currency,_that.id,_that.store,_that.isDiscounted,_that.regularPrice,_that.datePurchased,_that.syncStatus,_that.openPricesId,_that.locationOsmId,_that.locationOsmType,_that.receiptSeries,_that.receiptNumber,_that.receiptItemIndex,_that.notes,_that.dateAdded);case _:
  return null;

}
}

}

/// @nodoc


class _Price implements Price {
  const _Price({required this.barcode, required this.price, this.currency = 'USD', this.id, this.store, this.isDiscounted = false, this.regularPrice, this.datePurchased, this.syncStatus = priceSyncLocalOnly, this.openPricesId, this.locationOsmId, this.locationOsmType, this.receiptSeries, this.receiptNumber, this.receiptItemIndex, this.notes, this.dateAdded});
  

/// The product barcode this price is associated with.
@override final  String barcode;
/// The monetary amount (taxes included).
@override final  double price;
/// ISO 4217 currency code (e.g. 'BRL', 'USD', 'EUR').
///
/// Defaults to 'USD'; auto-detected from locale on first launch.
@override@JsonKey() final  String currency;
/// Auto-increment primary key.
@override final  int? id;
/// Free-form store or supermarket name.
@override final  String? store;
/// Whether this is a discounted / sale price.
@override@JsonKey() final  bool isDiscounted;
/// Original price before discount, if [isDiscounted] is true.
@override final  double? regularPrice;
/// Epoch timestamp (milliseconds since Unix epoch) of the purchase.
///
/// Defaults to the current time when no value is provided.
@override final  int? datePurchased;
/// Open prices sync status.
///
/// - [priceSyncLocalOnly] — not shared (no proof photo).
/// - [priceSyncPending] — queued for sync.
/// - [priceSyncSynced] — successfully synced.
/// - [priceSyncFailed] — sync failed.
@override@JsonKey() final  String syncStatus;
/// Remote ID on Open Prices after successful sync.
@override final  int? openPricesId;
/// OpenStreetMap node/way ID for the store location.
@override final  String? locationOsmId;
/// OpenStreetMap location type (NODE, WAY, or RELATION).
@override final  String? locationOsmType;
/// NFC-e receipt series (reserved for future tax receipt integration).
@override final  String? receiptSeries;
/// NFC-e receipt number (reserved for future tax receipt integration).
@override final  String? receiptNumber;
/// NFC-e line-item index (reserved for future tax receipt integration).
@override final  int? receiptItemIndex;
/// Free-form notes about this price observation.
@override final  String? notes;
/// Epoch timestamp (milliseconds since Unix epoch) of when this record
/// was created locally.
@override final  int? dateAdded;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceCopyWith<_Price> get copyWith => __$PriceCopyWithImpl<_Price>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Price&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.id, id) || other.id == id)&&(identical(other.store, store) || other.store == store)&&(identical(other.isDiscounted, isDiscounted) || other.isDiscounted == isDiscounted)&&(identical(other.regularPrice, regularPrice) || other.regularPrice == regularPrice)&&(identical(other.datePurchased, datePurchased) || other.datePurchased == datePurchased)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.openPricesId, openPricesId) || other.openPricesId == openPricesId)&&(identical(other.locationOsmId, locationOsmId) || other.locationOsmId == locationOsmId)&&(identical(other.locationOsmType, locationOsmType) || other.locationOsmType == locationOsmType)&&(identical(other.receiptSeries, receiptSeries) || other.receiptSeries == receiptSeries)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.receiptItemIndex, receiptItemIndex) || other.receiptItemIndex == receiptItemIndex)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dateAdded, dateAdded) || other.dateAdded == dateAdded));
}


@override
int get hashCode => Object.hash(runtimeType,barcode,price,currency,id,store,isDiscounted,regularPrice,datePurchased,syncStatus,openPricesId,locationOsmId,locationOsmType,receiptSeries,receiptNumber,receiptItemIndex,notes,dateAdded);

@override
String toString() {
  return 'Price(barcode: $barcode, price: $price, currency: $currency, id: $id, store: $store, isDiscounted: $isDiscounted, regularPrice: $regularPrice, datePurchased: $datePurchased, syncStatus: $syncStatus, openPricesId: $openPricesId, locationOsmId: $locationOsmId, locationOsmType: $locationOsmType, receiptSeries: $receiptSeries, receiptNumber: $receiptNumber, receiptItemIndex: $receiptItemIndex, notes: $notes, dateAdded: $dateAdded)';
}


}

/// @nodoc
abstract mixin class _$PriceCopyWith<$Res> implements $PriceCopyWith<$Res> {
  factory _$PriceCopyWith(_Price value, $Res Function(_Price) _then) = __$PriceCopyWithImpl;
@override @useResult
$Res call({
 String barcode, double price, String currency, int? id, String? store, bool isDiscounted, double? regularPrice, int? datePurchased, String syncStatus, int? openPricesId, String? locationOsmId, String? locationOsmType, String? receiptSeries, String? receiptNumber, int? receiptItemIndex, String? notes, int? dateAdded
});




}
/// @nodoc
class __$PriceCopyWithImpl<$Res>
    implements _$PriceCopyWith<$Res> {
  __$PriceCopyWithImpl(this._self, this._then);

  final _Price _self;
  final $Res Function(_Price) _then;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? barcode = null,Object? price = null,Object? currency = null,Object? id = freezed,Object? store = freezed,Object? isDiscounted = null,Object? regularPrice = freezed,Object? datePurchased = freezed,Object? syncStatus = null,Object? openPricesId = freezed,Object? locationOsmId = freezed,Object? locationOsmType = freezed,Object? receiptSeries = freezed,Object? receiptNumber = freezed,Object? receiptItemIndex = freezed,Object? notes = freezed,Object? dateAdded = freezed,}) {
  return _then(_Price(
barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,isDiscounted: null == isDiscounted ? _self.isDiscounted : isDiscounted // ignore: cast_nullable_to_non_nullable
as bool,regularPrice: freezed == regularPrice ? _self.regularPrice : regularPrice // ignore: cast_nullable_to_non_nullable
as double?,datePurchased: freezed == datePurchased ? _self.datePurchased : datePurchased // ignore: cast_nullable_to_non_nullable
as int?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as String,openPricesId: freezed == openPricesId ? _self.openPricesId : openPricesId // ignore: cast_nullable_to_non_nullable
as int?,locationOsmId: freezed == locationOsmId ? _self.locationOsmId : locationOsmId // ignore: cast_nullable_to_non_nullable
as String?,locationOsmType: freezed == locationOsmType ? _self.locationOsmType : locationOsmType // ignore: cast_nullable_to_non_nullable
as String?,receiptSeries: freezed == receiptSeries ? _self.receiptSeries : receiptSeries // ignore: cast_nullable_to_non_nullable
as String?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,receiptItemIndex: freezed == receiptItemIndex ? _self.receiptItemIndex : receiptItemIndex // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dateAdded: freezed == dateAdded ? _self.dateAdded : dateAdded // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
