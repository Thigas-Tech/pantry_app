import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/models/pantry_stats.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';

/// Aggregated statistics for the active pantry inventory.
///
/// Computed from SQL aggregation queries in [ProductDao] and
/// [InventoryDao]. Depends on [activeInventoryProvider] so it
/// refreshes when the user switches pantries. Uses [FutureProvider.autoDispose]
/// to release memory when leaving the Stats tab.
// ignore: specify_nonobvious_property_types
final statsProvider = FutureProvider.autoDispose<PantryStats>((ref) async {
  final activeId = ref.watch(activeInventoryProvider);
  final db = ref.watch(databaseProvider);
  final expiringSoonDays = ref.watch(
    settingsProvider.select((s) => s.expiringSoonDays),
  );
  final baseCurrency = ref.watch(
    settingsProvider.select((s) => s.baseCurrency),
  );
  final priceRepo = ref.read(priceRepositoryProvider);
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
      expiringSoonDays: expiringSoonDays,
    ),
    db.inventoryDao.weeklyAdditions(database, inventoryId: activeId),
    db.productDao.productsWithCategories(database),
  ]);

  final prodCount = results[0] as int;
  final itemCount = results[1] as int;
  final nutriDist = results[2] as Map<String, int>;
  final srcDist = results[4] as Map<String, int>;
  final localPhoto = results[5] as Map<String, int>;
  final offPhoto = results[6] as Map<String, int>;
  final locDist = results[7] as Map<String, int>;
  final expiryDist = results[8] as Map<String, int>;
  final weekly = results[9] as List<Map<String, dynamic>>;
  final productCategories = results[10] as List<Map<String, dynamic>>;

  // Compute parent categories from hierarchy data.
  final parentCounts = <String, int>{};
  for (final row in productCategories) {
    final parent = parentCategory(
      row['category'] as String?,
      row['categories_hierarchy'] as String?,
    );
    if (parent != null) {
      parentCounts[parent] = (parentCounts[parent] ?? 0) + 1;
    }
  }
  final sortedParents = parentCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

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
    totalValue:
        await priceRepo.totalInventoryValue(
          activeId,
          baseCurrency: baseCurrency,
        ) ??
        0,
    averagePrice:
        await priceRepo.averageItemPrice(
          activeId,
          baseCurrency: baseCurrency,
        ) ??
        0,
    pricedItemCount: await priceRepo.pricedItemCount(activeId),
    expiredCount: expiryDist['expired'] ?? 0,
    expiringSoonCount: expiryDist['expiring'] ?? 0,
    goodCount: expiryDist['good'] ?? 0,
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
    categoriesTop: sortedParents
        .take(10)
        .map(
          (e) => CategoryCount(category: e.key, count: e.value),
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

/// Returns a broad parent category from OFF hierarchy data.
///
/// When [hierarchyJson] is available, picks the 3rd-level English entry
/// (e.g. `en:eggs` from `[en:products, en:eggs-and-their-products,
/// en:eggs, en:chicken-eggs]`). When not available, falls back to the
/// first non‑language‑tagged word of [rawCategory]. Returns `null` when
/// both inputs are unavailable.
String? parentCategory(String? rawCategory, String? hierarchyJson) {
  if (hierarchyJson != null && hierarchyJson.isNotEmpty) {
    try {
      final hierarchy = (jsonDecode(hierarchyJson) as List).cast<String>();
      if (hierarchy.isNotEmpty) {
        final enEntries = hierarchy.where((t) => t.startsWith('en:')).toList();
        if (enEntries.isNotEmpty) {
          final idx = (enEntries.length - 2).clamp(0, enEntries.length - 1);
          var name = enEntries[idx].substring(3);
          name = name.replaceAll('-', ' ');
          return name[0].toUpperCase() + name.substring(1);
        }
      }
    } on Exception {
      // Fall through to rawCategory fallback.
    }
  }
  if (rawCategory != null && rawCategory.isNotEmpty) {
    final parts = rawCategory.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (!trimmed.contains(':')) return trimmed;
    }
  }
  return null;
}
