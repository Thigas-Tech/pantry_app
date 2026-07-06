import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/pantry_stats.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';

/// Aggregated statistics for the active pantry inventory.
///
/// Computed from SQL aggregation queries in `ProductDao` and
/// `InventoryDao`. Depends on `activeInventoryProvider` so it
/// refreshes when the user switches pantries. Uses `autoDispose`
/// to release memory when leaving the Stats tab.
// ignore: specify_nonobvious_property_types
final statsProvider = FutureProvider.autoDispose<PantryStats>((ref) async {
  final activeId = ref.watch(activeInventoryProvider);
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsProvider);
  final database = await db.database;

  final results = await Future.wait([
    db.productDao.count(database),
    db.inventoryDao.count(database, inventoryId: activeId),
    db.productDao.nutriscoreDistribution(database),
    db.productDao.categoryDistribution(database),
    db.productDao.sourceDistribution(database),
    db.productDao.photoCompleteness(database),
    db.productDao.offPhotoCompleteness(database),
    db.inventoryDao.locationDistribution(database, inventoryId: activeId),
    db.inventoryDao.expiryDistribution(
      database,
      inventoryId: activeId,
      expiringSoonDays: settings.expiringSoonDays,
    ),
    db.inventoryDao.weeklyAdditions(database, inventoryId: activeId),
  ]);

  final prodCount = results[0] as int;
  final itemCount = results[1] as int;
  final nutriDist = results[2] as Map<String, int>;
  final catDist = results[3] as List<Map<String, dynamic>>;
  final srcDist = results[4] as Map<String, int>;
  final localPhoto = results[5] as Map<String, int>;
  final offPhoto = results[6] as Map<String, int>;
  final locDist = results[7] as Map<String, int>;
  final expiryDist = results[8] as Map<String, int>;
  final weekly = results[9] as List<Map<String, dynamic>>;

  const gradeValues = {'a': 5, 'b': 4, 'c': 3, 'd': 2, 'e': 1};
  var nutriSum = 0;
  var nutriCount = 0;
  for (final entry in nutriDist.entries) {
    final val = gradeValues[entry.key.toLowerCase()];
    if (val != null) {
      nutriSum += val * entry.value;
      nutriCount += entry.value;
    }
  }
  final avgNutri = nutriCount > 0 ? nutriSum / nutriCount : 0.0;

  var addedAll = 0;
  for (final w in weekly) {
    addedAll += w['cnt'] as int;
  }

  return PantryStats(
    totalProducts: prodCount,
    totalItems: itemCount,
    averageNutriscoreNumeric: avgNutri,
    expiredCount: expiryDist['expired'] ?? 0,
    expiringSoonCount: expiryDist['expiring'] ?? 0,
    goodCount:
        (expiryDist['good'] ?? 0) +
        (expiryDist['expired'] ?? 0) +
        (expiryDist['expiring'] ?? 0),
    addedThisWeek: addedAll,
    addedThisMonth: addedAll,
    weeklyAdditions: weekly
        .map(
          (w) => WeeklyCount(
            weekLabel: w['week'] as String,
            count: w['cnt'] as int,
          ),
        )
        .toList(),
    itemsByLocation: locDist,
    categoriesTop: catDist
        .map(
          (c) => CategoryCount(
            category: c['category'] as String,
            count: c['cnt'] as int,
          ),
        )
        .toList(),
    nutriscoreDistribution: nutriDist,
    itemsBySource: srcDist,
    localPhotos: PhotoStats(
      total: localPhoto['total'] ?? 0,
      withNutrition: localPhoto['nutrition'] ?? 0,
      withIngredients: localPhoto['ingredients'] ?? 0,
      withProduct: localPhoto['product'] ?? 0,
    ),
    offPhotos: PhotoStats(
      total: offPhoto['total'] ?? 0,
      withNutrition: offPhoto['nutrition'] ?? 0,
      withIngredients: offPhoto['ingredients'] ?? 0,
      withProduct: offPhoto['product'] ?? 0,
    ),
  );
});
