// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) =>
    _InventoryItem(
      id: (json['id'] as num?)?.toInt(),
      barcode: json['barcode'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] as String? ?? 'pcs',
      expiryDate: json['expiryDate'] as String?,
      location: json['location'] as String? ?? 'pantry',
      notes: json['notes'] as String?,
      dateAdded: (json['dateAdded'] as num?)?.toInt(),
    );

Map<String, dynamic> _$InventoryItemToJson(_InventoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'barcode': instance.barcode,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'expiryDate': instance.expiryDate,
      'location': instance.location,
      'notes': instance.notes,
      'dateAdded': instance.dateAdded,
    };
