// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  barcode: json['barcode'] as String,
  name: json['name'] as String,
  brand: json['brand'] as String?,
  imageUrl: json['imageUrl'] as String?,
  category: json['category'] as String?,
  ingredients: json['ingredients'] as String?,
  servingSize: json['servingSize'] as String?,
  energyKcal: (json['energyKcal'] as num?)?.toDouble(),
  proteinG: (json['proteinG'] as num?)?.toDouble(),
  carbsG: (json['carbsG'] as num?)?.toDouble(),
  fatG: (json['fatG'] as num?)?.toDouble(),
  fiberG: (json['fiberG'] as num?)?.toDouble(),
  saltG: (json['saltG'] as num?)?.toDouble(),
  lastSynced: (json['lastSynced'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'barcode': instance.barcode,
  'name': instance.name,
  'brand': instance.brand,
  'imageUrl': instance.imageUrl,
  'category': instance.category,
  'ingredients': instance.ingredients,
  'servingSize': instance.servingSize,
  'energyKcal': instance.energyKcal,
  'proteinG': instance.proteinG,
  'carbsG': instance.carbsG,
  'fatG': instance.fatG,
  'fiberG': instance.fiberG,
  'saltG': instance.saltG,
  'lastSynced': instance.lastSynced,
};
