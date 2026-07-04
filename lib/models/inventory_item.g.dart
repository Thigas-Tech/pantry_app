// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) =>
    _InventoryItem(
      barcode: json['barcode'] as String,
      id: (json['id'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] as String? ?? 'pieces',
      expiryDate: json['expiry_date'] as String?,
      location: json['location'] as String? ?? 'pantry',
      notes: json['notes'] as String?,
      dateAdded: (json['date_added'] as num?)?.toInt(),
      inventoryId: (json['inventory_id'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$InventoryItemToJson(_InventoryItem instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'id': instance.id,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'expiry_date': instance.expiryDate,
      'location': instance.location,
      'notes': instance.notes,
      'date_added': instance.dateAdded,
      'inventory_id': instance.inventoryId,
    };
