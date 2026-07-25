// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_ingredient_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeIngredientCache _$RecipeIngredientCacheFromJson(
  Map<String, dynamic> json,
) => _RecipeIngredientCache(
  name: json['name'] as String,
  barcode: json['barcode'] as String?,
  quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
  unit: json['unit'] as String? ?? 'pieces',
);

Map<String, dynamic> _$RecipeIngredientCacheToJson(
  _RecipeIngredientCache instance,
) => <String, dynamic>{
  'name': instance.name,
  'barcode': ?instance.barcode,
  'quantity': instance.quantity,
  'unit': instance.unit,
};
