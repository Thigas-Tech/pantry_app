// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_nutrient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductNutrient _$ProductNutrientFromJson(Map<String, dynamic> json) =>
    _ProductNutrient(
      offTag: json['offTag'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$ProductNutrientToJson(_ProductNutrient instance) =>
    <String, dynamic>{
      'offTag': instance.offTag,
      'value': instance.value,
      'unit': instance.unit,
    };
