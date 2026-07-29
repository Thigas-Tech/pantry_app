// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_cache_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductCacheEntry _$ProductCacheEntryFromJson(Map<String, dynamic> json) =>
    _ProductCacheEntry(
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      lastRefreshedAt: (json['lastRefreshedAt'] as num).toInt(),
      nextRefreshAt: (json['nextRefreshAt'] as num).toInt(),
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      categoriesHierarchy: (json['categoriesHierarchy'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      ingredients: json['ingredients'] as String?,
      servingSize: json['servingSize'] as String?,
      servingQuantity: (json['servingQuantity'] as num?)?.toDouble(),
      quantity: json['quantity'] as String?,
      productQuantity: (json['productQuantity'] as num?)?.toDouble(),
      energyKcal: (json['energyKcal'] as num?)?.toDouble(),
      proteinG: (json['proteinG'] as num?)?.toDouble(),
      carbsG: (json['carbsG'] as num?)?.toDouble(),
      fatG: (json['fatG'] as num?)?.toDouble(),
      fiberG: (json['fiberG'] as num?)?.toDouble(),
      saltG: (json['saltG'] as num?)?.toDouble(),
      nutriscoreGrade: json['nutriscoreGrade'] as String?,
      imageUrl: json['imageUrl'] as String?,
      offNutritionImageUrl: json['offNutritionImageUrl'] as String?,
      offIngredientsImageUrl: json['offIngredientsImageUrl'] as String?,
      offProductImageUrl: json['offProductImageUrl'] as String?,
      languageCode: json['languageCode'] as String? ?? 'en',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      usdaServingAmount: (json['usdaServingAmount'] as num?)?.toDouble(),
      usdaServingUnit: json['usdaServingUnit'] as String?,
      usdaGramWeight: (json['usdaGramWeight'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ProductCacheEntryToJson(_ProductCacheEntry instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'name': instance.name,
      'createdAt': instance.createdAt,
      'lastRefreshedAt': instance.lastRefreshedAt,
      'nextRefreshAt': instance.nextRefreshAt,
      'brand': ?instance.brand,
      'category': ?instance.category,
      'categoriesHierarchy': ?instance.categoriesHierarchy,
      'ingredients': ?instance.ingredients,
      'servingSize': ?instance.servingSize,
      'servingQuantity': ?instance.servingQuantity,
      'quantity': ?instance.quantity,
      'productQuantity': ?instance.productQuantity,
      'energyKcal': ?instance.energyKcal,
      'proteinG': ?instance.proteinG,
      'carbsG': ?instance.carbsG,
      'fatG': ?instance.fatG,
      'fiberG': ?instance.fiberG,
      'saltG': ?instance.saltG,
      'nutriscoreGrade': ?instance.nutriscoreGrade,
      'imageUrl': ?instance.imageUrl,
      'offNutritionImageUrl': ?instance.offNutritionImageUrl,
      'offIngredientsImageUrl': ?instance.offIngredientsImageUrl,
      'offProductImageUrl': ?instance.offProductImageUrl,
      'languageCode': instance.languageCode,
      'schemaVersion': instance.schemaVersion,
      'usdaServingAmount': ?instance.usdaServingAmount,
      'usdaServingUnit': ?instance.usdaServingUnit,
      'usdaGramWeight': ?instance.usdaGramWeight,
    };
