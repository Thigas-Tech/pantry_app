// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'produce_cache_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProduceCacheEntry _$ProduceCacheEntryFromJson(Map<String, dynamic> json) =>
    _ProduceCacheEntry(
      fdcId: (json['fdcId'] as num).toInt(),
      name: json['name'] as String,
      nutrition: (json['nutrition'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      createdAt: (json['createdAt'] as num).toInt(),
      lastRefreshedAt: (json['lastRefreshedAt'] as num).toInt(),
      nextRefreshAt: (json['nextRefreshAt'] as num).toInt(),
      localizedNames:
          (json['localizedNames'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      pluCodes:
          (json['pluCodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      category: json['category'] as String?,
      servingSizeG: (json['servingSizeG'] as num?)?.toDouble(),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$ProduceCacheEntryToJson(_ProduceCacheEntry instance) =>
    <String, dynamic>{
      'fdcId': instance.fdcId,
      'name': instance.name,
      'nutrition': instance.nutrition,
      'createdAt': instance.createdAt,
      'lastRefreshedAt': instance.lastRefreshedAt,
      'nextRefreshAt': instance.nextRefreshAt,
      'localizedNames': instance.localizedNames,
      'pluCodes': instance.pluCodes,
      'category': ?instance.category,
      'servingSizeG': ?instance.servingSizeG,
      'schemaVersion': instance.schemaVersion,
    };
