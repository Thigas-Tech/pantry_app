// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  barcode: json['_id'] as String,
  name: json['product_name'] as String,
  brand: json['brands'] as String?,
  imageUrl: json['image_url'] as String?,
  category: json['category'] as String?,
  ingredients: json['ingredients_text'] as String?,
  servingSize: json['serving_size'] as String?,
  energyKcal: (json['energy_kcal'] as num?)?.toDouble(),
  proteinG: (json['protein_g'] as num?)?.toDouble(),
  carbsG: (json['carbs_g'] as num?)?.toDouble(),
  fatG: (json['fat_g'] as num?)?.toDouble(),
  fiberG: (json['fiber_g'] as num?)?.toDouble(),
  saltG: (json['salt_g'] as num?)?.toDouble(),
  lastSynced: (json['last_synced'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  '_id': instance.barcode,
  'product_name': instance.name,
  'brands': instance.brand,
  'image_url': instance.imageUrl,
  'category': instance.category,
  'ingredients_text': instance.ingredients,
  'serving_size': instance.servingSize,
  'energy_kcal': instance.energyKcal,
  'protein_g': instance.proteinG,
  'carbs_g': instance.carbsG,
  'fat_g': instance.fatG,
  'fiber_g': instance.fiberG,
  'salt_g': instance.saltG,
  'last_synced': instance.lastSynced,
};
