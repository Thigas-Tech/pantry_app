# Firebase Product Cache — Implementation Plan

## Unified Cache for OFF Barcoded + USDA Produce

## Per-Document 180-Day Rolling Refresh

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [New Files](#2-new-files)
3. [Modified Files](#3-modified-files)
4. [Database Schema: `firebase_cache_meta` Table (v24)](#4-database-schema-firebase_cache_meta-table-v24)
5. [Freezed Models](#5-freezed-models)
6. [DAO: `FirebaseCacheMetaDao`](#6-dao-firebasecachemetadao)
7. [Firestore Client: `FirebaseCacheClient`](#7-firestore-client-firebasecacheclient)
8. [Orchestrator: `FirebaseCacheService`](#8-orchestrator-firebasecacheservice)
9. [Integration with `ProductRepository`](#9-integration-with-productrepository)
10. [Providers](#10-providers)
11. [main.dart Changes](#11-maindart-changes)
12. [TDD Test Plan](#12-tdd-test-plan)
13. [Database Migration Test](#13-database-migration-test)
14. [Firestore Security Rules](#14-firestore-security-rules)
15. [Edge Cases & Pitfalls](#15-edge-cases--pitfalls)
16. [Implementation Order](#16-implementation-order)
17. [Rollout Plan](#17-rollout-plan)
18. [Firestore Cost Analysis](#18-firestore-cost-analysis)

---

## 1. Architecture Overview

```
+--------------------------------------------------------------------+
|                          UI Layer                                  |
|   ScannerScreen / AddToInventory / ProduceQuickAdd / Settings      |
+---------------------------+----------------------------------------+
                            |
+---------------------------v----------------------------------------+
|                    ProductRepository (Facade)                       |
|                                                                     |
|  getProduct(barcode)         resolveProduceProduct(name)            |
|  addProduceToInventory(...)  cacheProduct(...)                      |
|  refreshInventoryProducts(invId)                                    |
+------+------------------------------------------+------------------+
       |                                          |
       v                                          v
+--------------+  +------------------+  +-------------------+  +------------------+
| Products     |  | FirebaseCache    |  |  OffAdapter       |  |  UsdaApiClient   |
| Table (SQLite)|  | Service          |  |  (OFF API)        |  |  (USDA API)      |
+--------------+  +-------+----------+  +-------------------+  +------------------+
                          |
                  +-------+--------+
                  |                |
          +-------v---+    +------v-----------+
          |  Firestore |    |  Firestore       |
          |  produce_  |    |  product_        |
          |  cache/    |    |  cache/          |
          |  {name}    |    |  {barcode}       |
          +------------+    +------------------+

          +-----------------------------------------------------+
          | firebase_cache_meta (SQLite)                        |
          | cache_key | cache_type | fdc_id | last_refreshed_at |
          |           |            |        | next_refresh_at   |
          +-----------------------------------------------------+
```

### Lookup flow for barcoded product:

```
getProduct("7622210449283")
  |
  +-- 1. SQLite products table -> hit? return Product
  |
  +-- 2. Firestore product_cache/7622210449283 -> hit?
  |       +-- Deserialize -> ProductCacheEntry -> Product
  |       +-- Insert into SQLite products table
  |       +-- Upsert firebase_cache_meta (type='barcoded')
  |       +-- return Product
  |
  +-- 3. OFF API (OffAdapter.getByBarcode)
  |       +-- Insert into SQLite products table
  |       +-- Serialize Product -> ProductCacheEntry
  |       +-- Set Firestore product_cache/7622210449283
  |       +-- Upsert firebase_cache_meta (type='barcoded')
  |       +-- return Product
  |
  +-- 4. Fallback API -> existing behavior (ProductNotFoundException / FetchFailedException)
```

### Lookup flow for produce:

```
resolveProduceProduct("Apple")
  |
  +-- 1. (Caller already checks products table for "produce-Apple")
  |
  +-- 2. Firestore produce_cache/apple -> hit?
  |       +-- Deserialize -> ProduceCacheEntry -> Product
  |       +-- Insert into SQLite products table
  |       +-- Upsert firebase_cache_meta (type='produce')
  |       +-- return Product
  |
  +-- 3. USDA API (UsdaApiClient.searchFood)
  |       +-- Serialize Product -> ProduceCacheEntry
  |       +-- Set Firestore produce_cache/apple
  |       +-- Insert into SQLite products table
  |       +-- Upsert firebase_cache_meta (type='produce')
  |       +-- return Product
  |
  +-- 4. Hardcoded fallback (ProduceNutritionFallback) -> existing
  |
  +-- 5. Minimal product -> existing
```

### 180-day refresh flow:

```
refreshStaleEntries()
  |
  +-- 1. Query firebase_cache_meta WHERE next_refresh_at < now
  |       +-- If empty, return 0
  |
  +-- 2. For each stale entry (sequentially, 500ms delay, max 20):
  |
  |     For type='barcoded':
  |       +-- Call OFF API (OffAdapter.getByBarcode)
  |       +-- Serialize -> ProductCacheEntry (preserve createdAt)
  |       +-- Write to Firestore product_cache/{barcode}
  |       +-- Update firebase_cache_meta (new lastRefreshedAt, nextRefreshAt)
  |       +-- Update SQLite products table with fresh data
  |
  |     For type='produce':
  |       +-- Call USDA API (UsdaApiClient.searchFood)
  |       +-- Serialize -> ProduceCacheEntry (preserve createdAt)
  |       +-- Write to Firestore produce_cache/{name}
  |       +-- Update firebase_cache_meta (new lastRefreshedAt, nextRefreshAt)
  |       +-- Update SQLite products table with fresh data
  |
  +-- 3. Return count of successfully refreshed entries
```

---

## 2. New Files

```
lib/
  models/product_cache_entry.dart         # Freezed: Firestore doc for barcoded products
  models/produce_cache_entry.dart         # Freezed: Firestore doc for produce
  database/firebase_cache_meta_dao.dart   # SQLite DAO for refresh tracking
  services/firebase_cache_client.dart     # Firestore CRUD (two collections) + abstract FirestoreClient interface
  services/firebase_firestore_client_adapter.dart  # Concrete FirestoreClient backed by FirebaseFirestore
  services/firebase_cache_service.dart    # Orchestrator: lookup + refresh
  providers/firebase_cache_provider.dart  # Riverpod wiring

test/
  models/product_cache_entry_test.dart
  models/produce_cache_entry_test.dart
  database/firebase_cache_meta_dao_test.dart
  services/firebase_cache_client_test.dart
  services/firebase_cache_service_test.dart
```

---

## 3. Modified Files

| File                                                  | Change Type                        | Specific Change                                                                                                                                                                                                |
| ----------------------------------------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pubspec.yaml`                                        | Add dependencies                   | `firebase_core: ^3.12.0`, `cloud_firestore: ^5.6.0`                                                                                                                                                            |
| `lib/config.dart`                                     | Add getter                         | `static bool get firebaseEnabled`                                                                                                                                                                              |
| `.env.example`                                        | Add key                            | `FIREBASE_ENABLED=false`                                                                                                                                                                                       |
| `lib/database/database_helper.dart`                   | Add table + migration              | Version 24: create `firebase_cache_meta` table. Expose `FirebaseCacheMetaDao` as public final field. Add table creation in `_onCreate`.                                                                        |
| `lib/services/firebase_cache_client.dart`             | Abstract interface                 | `FirestoreClient`, `FirestoreDocument`, `FirestoreSnapshot` interfaces for testability                                                                                                                         |
| `lib/services/firebase_firestore_client_adapter.dart` | NEW                                | Concrete `FirestoreClient` backed by `FirebaseFirestore`                                                                                                                                                       |
| `lib/services/product_repository.dart`                | New param + two integration points | 1. Constructor: optional `FirebaseCacheService?`. 2. `getProduct()`: insert Firebase check after local cache miss, before OFF API call. 3. `_resolveProduceProduct()`: insert Firebase check before USDA call. |
| `lib/providers/product_repository_provider.dart`      | Wire new dependency                | Add `firebaseCacheProvider` read, pass to `ProductRepository`                                                                                                                                                  |
| `lib/main.dart`                                       | Init + scheduling                  | 1. Conditional `Firebase.initializeApp()` in `main()`. 2. Call `refreshStaleEntries()` in `_runPostInitTasks()`.                                                                                               |

---

## 4. Database Schema: `firebase_cache_meta` Table (v24)

### DDL

```sql
CREATE TABLE IF NOT EXISTS firebase_cache_meta (
  cache_key TEXT PRIMARY KEY,          -- barcode (barcoded) or "produce:<name>" (produce)
  cache_type TEXT NOT NULL,            -- 'barcoded' or 'produce'
  fdc_id INTEGER,                      -- only for produce type
  last_refreshed_at INTEGER,           -- epoch ms
  next_refresh_at INTEGER              -- epoch ms (= last_refreshed_at + 180 days)
);

CREATE INDEX IF NOT EXISTS idx_cache_type ON firebase_cache_meta(cache_type);
CREATE INDEX IF NOT EXISTS idx_next_refresh ON firebase_cache_meta(next_refresh_at);
```

### Design rationale

- **Single table** for both types with `cache_type` discriminator: one DAO, one refresh loop, less code.
- **`cache_key` for barcoded** = the barcode itself (e.g. `"7622210449283"`).
- **`cache_key` for produce** = `"produce:<lowercase_name>"` (e.g. `"produce:apple"`). The prefix avoids collisions with numeric-only barcodes.
- **`fdc_id`** is nullable, only populated for produce entries.
- **Indexes**: `idx_cache_type` for type-filtered queries, `idx_next_refresh` for the stale-entry query which is the most performance-sensitive operation.

### Table purpose

This is a **lightweight index only**. It tracks which products have been cached in Firestore and when they need refresh. The actual nutrition/product data lives in Firestore documents and the SQLite `products` table. The meta table exists to:

1. Avoid scanning Firestore to find stale documents (costs reads).
2. Maintain a local index even when Firebase is temporarily unavailable.
3. Enable offline awareness of what's cached remotely.

### Migration v23->v24 in `_onUpgrade`

```dart
if (oldVersion < 24) {
  try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS firebase_cache_meta (
        cache_key TEXT PRIMARY KEY,
        cache_type TEXT NOT NULL,
        fdc_id INTEGER,
        last_refreshed_at INTEGER,
        next_refresh_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cache_type '
      'ON firebase_cache_meta(cache_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_next_refresh '
      'ON firebase_cache_meta(next_refresh_at)',
    );
    logInfo('Migration to version 24 (firebase_cache_meta) completed');
  } on Exception catch (e) {
    logWarning('Migration v24 failed: $e');
  }
}
```

### `_onCreate` addition

```dart
await db.execute('''
  CREATE TABLE IF NOT EXISTS firebase_cache_meta (
    cache_key TEXT PRIMARY KEY,
    cache_type TEXT NOT NULL,
    fdc_id INTEGER,
    last_refreshed_at INTEGER,
    next_refresh_at INTEGER
  )
''');
await db.execute(
  'CREATE INDEX IF NOT EXISTS idx_cache_type '
  'ON firebase_cache_meta(cache_type)',
);
await db.execute(
  'CREATE INDEX IF NOT EXISTS idx_next_refresh '
  'ON firebase_cache_meta(next_refresh_at)',
);
```

### `DatabaseHelper` property

```dart
/// DAO for the `firebase_cache_meta` table.
final FirebaseCacheMetaDao firebaseCacheMetaDao = const FirebaseCacheMetaDao();
```

No new convenience methods on `DatabaseHelper`; consumers use `firebaseCacheMetaDao` directly (same pattern as all other DAOs: `inventoryDao`, `priceDao`, etc.).

---

## 5. Freezed Models

### 5.1 `ProduceCacheEntry` (USDA produce -- Firestore collection `produce_cache/{name}`)

```dart
// lib/models/produce_cache_entry.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';

part 'produce_cache_entry.freezed.dart';
part 'produce_cache_entry.g.dart';

/// 180 days in milliseconds.
const int _produceRefreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

@freezed
class ProduceCacheEntry with _$ProduceCacheEntry {
  const factory ProduceCacheEntry({
    required int fdcId,
    required String name,
    @Default({}) Map<String, String> localizedNames,
    required Map<String, double> nutrition,
    double? servingSizeG,
    @Default([]) List<String> pluCodes,
    String? category,
    @Default(1) int schemaVersion,
    required int createdAt,
    required int lastRefreshedAt,
    required int nextRefreshAt,
  }) = _ProduceCacheEntry;

  factory ProduceCacheEntry.fromJson(Map<String, dynamic> json) =>
      _$ProduceCacheEntryFromJson(json);
}

/// Extension providing conversions to/from [Product].
extension ProduceCacheEntryConversions on ProduceCacheEntry {
  /// Creates a cache entry from a USDA [Product].
  static ProduceCacheEntry fromProduct(
    Product product,
    int fdcId, {
    required String englishName,
    int? createdAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ProduceCacheEntry(
      fdcId: fdcId,
      name: englishName,
      nutrition: {
        if (product.energyKcal != null) 'energyKcal': product.energyKcal!,
        if (product.proteinG != null) 'proteinG': product.proteinG!,
        if (product.carbsG != null) 'carbsG': product.carbsG!,
        if (product.fatG != null) 'fatG': product.fatG!,
        if (product.fiberG != null) 'fiberG': product.fiberG!,
      },
      servingSizeG: null,
      pluCodes: [],
      category: product.category,
      createdAt: createdAt ?? now,
      lastRefreshedAt: now,
      nextRefreshAt: now + _produceRefreshIntervalMs,
    );
  }

  /// Converts back to a local [Product].
  Product toProduct({required String barcode}) {
    return Product(
      barcode: barcode,
      name: name,
      category: category,
      productType: ProductType.produce,
      source: 'manual',
      energyKcal: nutrition['energyKcal'],
      proteinG: nutrition['proteinG'],
      carbsG: nutrition['carbsG'],
      fatG: nutrition['fatG'],
      fiberG: nutrition['fiberG'],
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Creates a refreshed copy preserving the original [createdAt].
  ProduceCacheEntry withRefreshedData(ProduceCacheEntry fresh) {
    return fresh.copyWith(createdAt: createdAt);
  }
}
```

### 5.2 `ProductCacheEntry` (OFF barcoded -- Firestore collection `product_cache/{barcode}`)

```dart
// lib/models/product_cache_entry.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/models/product.dart';

part 'product_cache_entry.freezed.dart';
part 'product_cache_entry.g.dart';

/// 180 days in milliseconds.
const int _productRefreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

@freezed
class ProductCacheEntry with _$ProductCacheEntry {
  const factory ProductCacheEntry({
    required String barcode,
    required String name,
    String? brand,
    String? category,
    List<String>? categoriesHierarchy,
    String? ingredients,
    String? servingSize,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    double? saltG,
    String? nutriscoreGrade,
    String? imageUrl,
    String? offNutritionImageUrl,
    String? offIngredientsImageUrl,
    String? offProductImageUrl,
    @Default('en') String languageCode,
    @Default(1) int schemaVersion,
    required int createdAt,
    required int lastRefreshedAt,
    required int nextRefreshAt,
  }) = _ProductCacheEntry;

  factory ProductCacheEntry.fromJson(Map<String, dynamic> json) =>
      _$ProductCacheEntryFromJson(json);
}

/// Extension providing conversions to/from [Product].
extension ProductCacheEntryConversions on ProductCacheEntry {
  /// Creates a cache entry from a [Product] fetched from OFF API.
  static ProductCacheEntry fromProduct(
    Product product, {
    int? createdAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ProductCacheEntry(
      barcode: product.barcode,
      name: product.name,
      brand: product.brand,
      category: product.category,
      categoriesHierarchy: product.categoriesHierarchy,
      ingredients: product.ingredients,
      servingSize: product.servingSize,
      energyKcal: product.energyKcal,
      proteinG: product.proteinG,
      carbsG: product.carbsG,
      fatG: product.fatG,
      fiberG: product.fiberG,
      saltG: product.saltG,
      nutriscoreGrade: product.nutriscoreGrade,
      imageUrl: product.imageUrl,
      offNutritionImageUrl: product.offNutritionImageUrl,
      offIngredientsImageUrl: product.offIngredientsImageUrl,
      offProductImageUrl: product.offProductImageUrl,
      languageCode: product.languageCode,
      createdAt: createdAt ?? now,
      lastRefreshedAt: now,
      nextRefreshAt: now + _productRefreshIntervalMs,
    );
  }

  /// Converts back to a local [Product].
  Product toProduct() {
    return Product(
      barcode: barcode,
      name: name,
      brand: brand,
      category: category,
      categoriesHierarchy: categoriesHierarchy,
      ingredients: ingredients,
      servingSize: servingSize,
      energyKcal: energyKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      saltG: saltG,
      nutriscoreGrade: nutriscoreGrade,
      imageUrl: imageUrl,
      offNutritionImageUrl: offNutritionImageUrl,
      offIngredientsImageUrl: offIngredientsImageUrl,
      offProductImageUrl: offProductImageUrl,
      languageCode: languageCode,
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Creates a refreshed copy preserving the original [createdAt].
  ProductCacheEntry withRefreshedData(ProductCacheEntry fresh) {
    return fresh.copyWith(createdAt: createdAt);
  }
}
```

### Fields intentionally excluded from `ProductCacheEntry`

The following `Product` fields are NOT stored in Firestore because they are local-only or transient:

| Field                  | Reason for Exclusion                                     |
| ---------------------- | -------------------------------------------------------- |
| `nutritionImagePath`   | Local file path, not portable                            |
| `ingredientsImagePath` | Local file path, not portable                            |
| `productImagePath`     | Local file path, not portable                            |
| `source`               | Always `'api'` for OFF products; irrelevant for cache    |
| `submissionStatus`     | Transient submission state, not cacheable                |
| `productType`          | All entries in `product_cache` are implicitly `barcoded` |
| `pluCode`              | Only applies to produce                                  |
| `lastSynced`           | Replaced by `lastRefreshedAt` in the cache entry         |

---

## 6. DAO: `FirebaseCacheMetaDao`

```dart
// lib/database/firebase_cache_meta_dao.dart

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the `firebase_cache_meta` table.
///
/// Tracks which products have been cached in Firestore and when each
/// document needs its next refresh (180-day rolling cycle).
class FirebaseCacheMetaDao {
  const FirebaseCacheMetaDao();

  /// Creates the `firebase_cache_meta` table.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS firebase_cache_meta (
        cache_key TEXT PRIMARY KEY,
        cache_type TEXT NOT NULL,
        fdc_id INTEGER,
        last_refreshed_at INTEGER,
        next_refresh_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cache_type '
      'ON firebase_cache_meta(cache_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_next_refresh '
      'ON firebase_cache_meta(next_refresh_at)',
    );
  }

  /// Upserts a cache metadata row.
  Future<void> upsert(
    Database db,
    String cacheKey,
    String cacheType, {
    int? fdcId,
    required int lastRefreshedAt,
    required int nextRefreshAt,
  }) async {
    try {
      await db.insert(
        'firebase_cache_meta',
        {
          'cache_key': cacheKey,
          'cache_type': cacheType,
          'fdc_id': fdcId,
          'last_refreshed_at': lastRefreshedAt,
          'next_refresh_at': nextRefreshAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on Exception catch (e) {
      logError('Failed to upsert cache meta for $cacheKey: $e');
      rethrow;
    }
  }

  /// Retrieves a single entry by [cacheKey].
  Future<Map<String, dynamic>?> get(Database db, String cacheKey) async {
    final result = await db.query(
      'firebase_cache_meta',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Returns all entries where `next_refresh_at < [nowInMs]`.
  ///
  /// Optionally filter by [cacheType] ('barcoded' | 'produce').
  Future<List<Map<String, dynamic>>> getStaleEntries(
    Database db, {
    String? cacheType,
    required int nowInMs,
  }) async {
    final where = <String>['next_refresh_at < ?'];
    final args = <dynamic>[nowInMs];

    if (cacheType != null) {
      where.add('cache_type = ?');
      args.add(cacheType);
    }

    return db.query(
      'firebase_cache_meta',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'next_refresh_at ASC',
    );
  }

  /// Returns all cache keys, optionally filtered by [cacheType].
  Future<List<String>> getAllKeys(
    Database db, {
    String? cacheType,
  }) async {
    final where = cacheType != null ? 'cache_type = ?' : null;
    final args = cacheType != null ? <dynamic>[cacheType] : null;

    final result = await db.query(
      'firebase_cache_meta',
      columns: ['cache_key'],
      where: where,
      whereArgs: args,
    );
    return result.map((r) => r['cache_key'] as String).toList();
  }

  /// Deletes an entry by [cacheKey].
  Future<void> remove(Database db, String cacheKey) async {
    await db.delete(
      'firebase_cache_meta',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
  }

  /// Updates only the refresh timestamps for an existing entry.
  ///
  /// Preserves all other columns (cache_key, cache_type, fdc_id).
  Future<void> updateRefreshTimestamps(
    Database db,
    String cacheKey, {
    required int lastRefreshedAt,
    required int nextRefreshAt,
  }) async {
    await db.update(
      'firebase_cache_meta',
      {
        'last_refreshed_at': lastRefreshedAt,
        'next_refresh_at': nextRefreshAt,
      },
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
  }

  /// Counts entries, optionally filtered by [cacheType].
  Future<int> count(
    Database db, {
    String? cacheType,
  }) async {
    final where = cacheType != null ? 'cache_type = ?' : null;
    final args = cacheType != null ? <dynamic>[cacheType] : null;

    return Sqflite.firstIntValue(
          await db.query(
            'firebase_cache_meta',
            columns: ['COUNT(*)'],
            where: where,
            whereArgs: args,
          ),
        ) ??
        0;
  }
}
```

---

## 7. Firestore Client: `FirebaseCacheClient`

> **Implementation note**: The actual code in `firebase_cache_client.dart` uses abstract
> `FirestoreClient`/`FirestoreDocument`/`FirestoreSnapshot` interfaces instead of `dynamic`
> for the `firestore` parameter. This enables mock-free testing and avoids a hard
> `cloud_firestore` import. The concrete adapter `FirebaseFirestoreClientAdapter` (in
> `firebase_firestore_client_adapter.dart`) wraps `FirebaseFirestore.instance`. The
> code sample below reflects the `dynamic` approach from the original design; see the
> actual source for the current interface-based design.

```dart
// lib/services/firebase_cache_client.dart

import 'dart:async';

import 'package:pantry_app/models/product_cache_entry.dart';
import 'package:pantry_app/models/produce_cache_entry.dart';
import 'package:pantry_app/utils/logger.dart';

/// Low-level Firestore client for product and produce caches.
///
/// Wraps two Firestore collections:
///   - `produce_cache/{name}`  -- USDA produce data (ProduceCacheEntry)
///   - `product_cache/{barcode}` -- OFF barcoded product data (ProductCacheEntry)
///
/// ## Graceful degradation
///
/// When [isAvailable] is false, all get* methods return null and all set*
/// methods return false. This allows the app to function without Firebase
/// (e.g. development builds, missing google-services.json).
class FirebaseCacheClient {
  /// Injected Firestore instance. Null when Firebase is unavailable.
  final dynamic _firestore;

  /// Whether caching is enabled.
  final bool _enabled;

  FirebaseCacheClient({
    // Use `dynamic` to avoid a hard import of FirebaseFirestore here
    // when the feature flag is off. In practice this will be a
    // FirebaseFirestore instance or null.
    dynamic firestore,
    bool enabled = false,
  })  : _firestore = firestore,
        _enabled = enabled;

  static const _produceCollection = 'produce_cache';
  static const _productCollection = 'product_cache';

  /// Whether Firebase operations are available.
  bool get isAvailable => _firestore != null && _enabled;

  // =================================================================
  //  Produce cache (USDA)
  // =================================================================

  /// Fetches a produce entry from Firestore by canonical English [name].
  ///
  /// Returns null on miss, on unavailable Firebase, or on any Firestore error.
  Future<ProduceCacheEntry?> getProduce(String name) async {
    if (!isAvailable) return null;
    try {
      final doc = await _firestore
          .collection(_produceCollection)
          .doc(name)
          .get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      return ProduceCacheEntry.fromJson(data);
    } on Exception catch (e) {
      logWarning('Firestore getProduce failed for "$name": $e');
      return null;
    }
  }

  /// Stores a produce entry in Firestore.
  ///
  /// Returns true on success, false on unavailable or error.
  Future<bool> setProduce(ProduceCacheEntry entry) async {
    if (!isAvailable) return false;
    try {
      await _firestore
          .collection(_produceCollection)
          .doc(entry.name)
          .set(entry.toJson());
      return true;
    } on Exception catch (e) {
      logWarning('Firestore setProduce failed for "${entry.name}": $e');
      return false;
    }
  }

  /// Deletes a produce entry from Firestore.
  Future<void> deleteProduce(String name) async {
    if (!isAvailable) return;
    try {
      await _firestore.collection(_produceCollection).doc(name).delete();
    } on Exception catch (e) {
      logWarning('Firestore deleteProduce failed for "$name": $e');
    }
  }

  // =================================================================
  //  Product cache (OFF barcoded)
  // =================================================================

  /// Fetches a barcoded product entry from Firestore by [barcode].
  ///
  /// Returns null on miss, on unavailable Firebase, or on any Firestore error.
  Future<ProductCacheEntry?> getProduct(String barcode) async {
    if (!isAvailable) return null;
    try {
      final doc = await _firestore
          .collection(_productCollection)
          .doc(barcode)
          .get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      return ProductCacheEntry.fromJson(data);
    } on Exception catch (e) {
      logWarning('Firestore getProduct failed for "$barcode": $e');
      return null;
    }
  }

  /// Stores a barcoded product entry in Firestore.
  ///
  /// Returns true on success, false on unavailable or error.
  Future<bool> setProduct(ProductCacheEntry entry) async {
    if (!isAvailable) return false;
    try {
      await _firestore
          .collection(_productCollection)
          .doc(entry.barcode)
          .set(entry.toJson());
      return true;
    } on Exception catch (e) {
      logWarning(
        'Firestore setProduct failed for "${entry.barcode}": $e',
      );
      return false;
    }
  }

  /// Deletes a barcoded product entry from Firestore.
  Future<void> deleteProduct(String barcode) async {
    if (!isAvailable) return;
    try {
      await _firestore.collection(_productCollection).doc(barcode).delete();
    } on Exception catch (e) {
      logWarning('Firestore deleteProduct failed for "$barcode": $e');
    }
  }
}
```

### Firestore document structures

#### `produce_cache/{name}`

```json
{
  "fdcId": 1750339,
  "name": "Apple",
  "localizedNames": { "pt": "Mac-a", "es": "Manzana" },
  "nutrition": {
    "energyKcal": 52,
    "proteinG": 0.26,
    "carbsG": 13.81,
    "fatG": 0.17,
    "fiberG": 2.4
  },
  "servingSizeG": null,
  "pluCodes": [],
  "category": "Fruit",
  "schemaVersion": 1,
  "createdAt": 1700000000000,
  "lastRefreshedAt": 1700000000000,
  "nextRefreshAt": 1700000000000
}
```

#### `product_cache/{barcode}`

```json
{
  "barcode": "7622210449283",
  "name": "Nutella",
  "brand": "Ferrero",
  "category": "Spreads, Sweet spreads",
  "categoriesHierarchy": ["en:spreads", "en:sweet-spreads"],
  "ingredients": "Sugar, palm oil, hazelnuts...",
  "servingSize": "15 g",
  "nutrition": {
    "energyKcal": 539,
    "proteinG": 6.3,
    "carbsG": 57.5,
    "fatG": 31.5,
    "fiberG": 1.3,
    "saltG": 0.1
  },
  "nutriscoreGrade": "e",
  "imageUrl": "https://images.openfoodfacts.org/...",
  "offNutritionImageUrl": "https://...",
  "offIngredientsImageUrl": "https://...",
  "offProductImageUrl": "https://...",
  "languageCode": "en",
  "schemaVersion": 1,
  "createdAt": 1700000000000,
  "lastRefreshedAt": 1700000000000,
  "nextRefreshAt": 1700000000000
}
```

---

## 8. Orchestrator: `FirebaseCacheService`

```dart
// lib/services/firebase_cache_service.dart

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_cache_entry.dart';
import 'package:pantry_app/models/produce_cache_entry.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/firebase_cache_client.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:pantry_app/utils/logger.dart';

/// Coordinates the two-level cache for product data.
///
/// ## Lookup chain (barcoded)
///
/// 1. Firebase Firestore (product_cache/{barcode}) -- shared cloud cache
/// 2. OFF API (OffAdapter) -- authoritative source
///
/// ## Lookup chain (produce)
///
/// 1. Firebase Firestore (produce_cache/{name}) -- shared cloud cache
/// 2. USDA API (UsdaApiClient) -- authoritative source
///
/// ## 180-day refresh
///
/// [refreshStaleEntries] queries the SQLite firebase_cache_meta table for
/// entries where next_refresh_at < now, then re-fetches each entry from its
/// source API and updates both Firestore and SQLite. This is a rolling,
/// per-document refresh -- no bulk operations.
class FirebaseCacheService {
  final DatabaseHelper _db;
  final FirebaseCacheClient _firebaseClient;
  final UsdaApiClient _usdaClient;
  final OffAdapter _offAdapter;
  final FirebaseCacheMetaDao _metaDao;

  FirebaseCacheService({
    required DatabaseHelper db,
    required FirebaseCacheClient firebaseClient,
    required UsdaApiClient usdaClient,
    required OffAdapter offAdapter,
    FirebaseCacheMetaDao? metaDao,
  })  : _db = db,
        _firebaseClient = firebaseClient,
        _usdaClient = usdaClient,
        _offAdapter = offAdapter,
        _metaDao = metaDao ?? const FirebaseCacheMetaDao();

  /// Whether Firebase caching is available.
  bool get isAvailable => _firebaseClient.isAvailable;

  // =================================================================
  //  Barcoded product lookup
  // =================================================================

  /// Resolves a barcoded product: Firebase -> OFF API -> cache both.
  ///
  /// Returns the [Product] if found anywhere, or null if not found in
  /// any source (caller should throw ProductNotFoundException).
  Future<Product?> resolveBarcodedProduct(
    String barcode, {
    required String languageCode,
  }) async {
    // 1. Try Firebase
    if (isAvailable) {
      try {
        final cached = await _firebaseClient.getProduct(barcode);
        if (cached != null) {
          logInfo('Firebase cache hit for barcode $barcode');
          await _db.insertProduct(cached.toProduct());
          await _upsertMeta(
            barcode,
            'barcoded',
            fdcId: null,
          );
          return cached.toProduct();
        }
      } on Exception catch (e) {
        logWarning('Firebase read failed for $barcode: $e');
      }
    }

    // 2. Try OFF API
    try {
      final product = await _offAdapter.getByBarcode(
        barcode,
        languageCode: languageCode,
      );
      // Fire-and-forget cache in Firebase + SQLite meta
      unawaited(_cacheBarcodedProduct(product));
      return product;
    } on ProductNotFoundException {
      return null;
    } on Exception catch (e) {
      logWarning('OFF API failed for $barcode: $e');
      return null;
    }
  }

  /// Fire-and-forget cache write for an already-fetched barcoded product.
  Future<void> cacheBarcodedProduct(Product product) async {
    if (!isAvailable) return;
    try {
      final entry = ProductCacheEntryConversions.fromProduct(product);
      await _firebaseClient.setProduct(entry);
      await _upsertMeta(
        product.barcode,
        'barcoded',
        fdcId: null,
      );
    } on Exception catch (e) {
      logWarning('Firebase cache write failed for ${product.barcode}: $e');
    }
  }

  // =================================================================
  //  Produce lookup
  // =================================================================

  /// Resolves a produce product: Firebase -> USDA -> cache both.
  ///
  /// Returns the [Product] if found in Firebase or USDA, or null if not
  /// found (caller falls through to hardcoded fallback data).
  Future<Product?> resolveProduceProduct(String produceName) async {
    if (produceName.trim().isEmpty) return null;
    final lowerName = produceName.toLowerCase();

    // 1. Try Firebase
    if (isAvailable) {
      try {
        final cached = await _firebaseClient.getProduce(lowerName);
        if (cached != null) {
          logInfo('Firebase produce cache hit for "$produceName"');
          final product = cached.toProduct(
            barcode: 'produce-$produceName',
          );
          await _db.insertProduct(product);
          await _upsertMeta(
            'produce:$lowerName',
            'produce',
            fdcId: cached.fdcId,
          );
          return product;
        }
      } on Exception catch (e) {
        logWarning('Firebase produce read failed for "$produceName": $e');
      }
    }

    // 2. Try USDA
    try {
      final results = await _usdaClient.searchFood(produceName);
      if (results.isNotEmpty) {
        final usdaProduct = results.first;
        final fdcId = int.tryParse(
          usdaProduct.barcode.replaceFirst('plu-', ''),
        );
        // Fire-and-forget cache in Firebase
        unawaited(_cacheProduceProduct(
          usdaProduct.copyWith(name: produceName),
          produceName,
          fdcId: fdcId,
        ));
        return usdaProduct.copyWith(
          name: produceName,
        );
      }
    } on Exception catch (e) {
      logWarning('USDA lookup failed for "$produceName": $e');
    }

    return null;
  }

  /// Fire-and-forget cache write for an already-fetched produce product.
  Future<void> cacheProduceProduct(
    Product product,
    String produceName, {
    int? fdcId,
  }) async {
    if (!isAvailable) return;
    try {
      final lowerName = produceName.toLowerCase();
      final entry = ProduceCacheEntryConversions.fromProduct(
        product,
        fdcId ?? 0,
        englishName: lowerName,
      );
      await _firebaseClient.setProduce(entry);
      await _upsertMeta(
        'produce:$lowerName',
        'produce',
        fdcId: fdcId,
      );
    } on Exception catch (e) {
      logWarning('Firebase produce cache write failed for "$produceName": $e');
    }
  }

  // =================================================================
  //  180-day refresh
  // =================================================================

  /// Max entries to refresh in a single run.
  static const int _defaultMaxBatchSize = 20;

  /// Delay between individual API calls during refresh.
  static const Duration _refreshDelay = Duration(milliseconds: 500);

  /// Refreshes stale cache entries by re-fetching from the source API.
  ///
  /// Returns the number of successfully refreshed entries.
  ///
  /// ## Behaviour
  ///
  /// - Queries SQLite for entries where next_refresh_at < now.
  /// - Processes up to [maxBatchSize] entries sequentially.
  /// - 500ms delay between consecutive API calls (rate limiting).
  /// - On failure (API error, network error), the entry is skipped and its
  ///   next_refresh_at is left unchanged so it will be retried next time.
  /// - On success, both Firestore and SQLite meta are updated.
  /// - Original createdAt is preserved on refresh.
  Future<int> refreshStaleEntries({int maxBatchSize = _defaultMaxBatchSize}) async {
    if (!isAvailable) {
      logInfo('Firebase cache refresh skipped: not available');
      return 0;
    }

    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final stale = await _metaDao.getStaleEntries(db, nowInMs: now);

    if (stale.isEmpty) {
      logInfo('No stale Firebase cache entries to refresh');
      return 0;
    }

    logInfo('Refreshing ${stale.length} stale Firebase cache entries '
        '(max batch: $maxBatchSize)');

    var refreshed = 0;
    var index = 0;

    for (final row in stale) {
      if (index >= maxBatchSize) break;
      if (index > 0) await Future<void>.delayed(_refreshDelay);

      final cacheKey = row['cache_key'] as String;
      final cacheType = row['cache_type'] as String;

      try {
        final success = await _refreshSingleEntry(cacheKey, cacheType);
        if (success) refreshed++;
      } on Exception catch (e) {
        logWarning('Refresh failed for "$cacheKey": $e');
      }
      index++;
    }

    logInfo('Firebase cache refresh: $refreshed / ${stale.length} entries');
    return refreshed;
  }

  /// Refreshes a single cache entry by re-fetching from its source API.
  Future<bool> _refreshSingleEntry(String cacheKey, String cacheType) async {
    final db = await _db.database;

    if (cacheType == 'produce') {
      return _refreshProduceEntry(db, cacheKey);
    } else {
      return _refreshBarcodedEntry(db, cacheKey);
    }
  }

  Future<bool> _refreshProduceEntry(Database db, String cacheKey) async {
    // Extract name from "produce:<name>"
    const prefix = 'produce:';
    final name = cacheKey.startsWith(prefix)
        ? cacheKey.substring(prefix.length)
        : cacheKey;

    final results = await _usdaClient.searchFood(name);
    if (results.isEmpty) return false;

    final usdaProduct = results.first;
    final fdcId = int.tryParse(
      usdaProduct.barcode.replaceFirst('plu-', ''),
    );

    // Get existing entry to preserve createdAt
    final existing = await _firebaseClient.getProduce(name);
    final entry = ProduceCacheEntryConversions.fromProduct(
      usdaProduct.copyWith(name: name),
      fdcId ?? 0,
      englishName: name,
      createdAt: existing?.createdAt,
    );

    final stored = await _firebaseClient.setProduce(entry);
    if (!stored) return false;

    await _metaDao.updateRefreshTimestamps(
      db,
      cacheKey,
      lastRefreshedAt: entry.lastRefreshedAt,
      nextRefreshAt: entry.nextRefreshAt,
    );

    // Also update local products table
    final localProduct = entry.toProduct(barcode: 'produce-$name');
    await _db.insertProduct(localProduct);

    logInfo('Refreshed produce entry "$name" (FDC $fdcId)');
    return true;
  }

  Future<bool> _refreshBarcodedEntry(Database db, String cacheKey) async {
    try {
      final product = await _offAdapter.getByBarcode(cacheKey);
      final existing = await _firebaseClient.getProduct(cacheKey);
      final entry = ProductCacheEntryConversions.fromProduct(
        product,
        createdAt: existing?.createdAt,
      );

      final stored = await _firebaseClient.setProduct(entry);
      if (!stored) return false;

      await _metaDao.updateRefreshTimestamps(
        db,
        cacheKey,
        lastRefreshedAt: entry.lastRefreshedAt,
        nextRefreshAt: entry.nextRefreshAt,
      );

      await _db.insertProduct(product);
      logInfo('Refreshed barcoded entry $cacheKey');
      return true;
    } on ProductNotFoundException {
      logWarning('Refresh: product $cacheKey not found in OFF, skipping');
      return false;
    }
  }

  // =================================================================
  //  Internal helpers
  // =================================================================

  Future<void> _upsertMeta(
    String cacheKey,
    String cacheType, {
    int? fdcId,
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await _metaDao.upsert(
        db,
        cacheKey,
        cacheType,
        fdcId: fdcId,
        lastRefreshedAt: now,
        nextRefreshAt: now + _refreshIntervalMs,
      );
    } on Exception catch (e) {
      logWarning('Failed to upsert cache meta: $e');
    }
  }

  static const int _refreshIntervalMs = 180 * 24 * 60 * 60 * 1000; // 180 days
}
```

---

## 9. Integration with `ProductRepository`

> **Implementation note**: The actual code restructures the fallback flow to avoid
> a redundant second OFF/USDA call. When `FirebaseCacheService.resolveBarcodedProduct`
> returns null, the service already tried OFF internally, so `ProductRepository.getProduct`
> skips the direct OFF call and proceeds directly to the fallback API chain. The same
> applies to `_resolveProduceProduct` (skips direct USDA call when Firebase resolves
> to null). See `_fallbackOrThrow` and `_produceFallbackOrMinimal` helpers in the
> actual source.

### 9.1 Constructor change

```dart
class ProductRepository {
  ProductRepository(
    this._db,
    this._api, {
    this._fallbackApi,
    this._usdaClient,
    this._prefs,
    this._firebaseCache,     // NEW
  });

  final DatabaseHelper _db;
  final OffAdapter _api;
  final OffAdapter? _fallbackApi;
  final UsdaApiClient? _usdaClient;
  final SharedPreferences? _prefs;
  final FirebaseCacheService? _firebaseCache;  // NEW
  // ...
```

### 9.2 `getProduct` -- insert Firebase check

```dart
Future<Product> getProduct(String barcode, {String? languageCode}) async {
  logInfo('Looking up $barcode');
  final lang = languageCode ?? _currentLanguageCode();

  // 1. Local cache (existing)
  final cached = await _db.getProduct(barcode);
  if (cached != null) {
    logInfo('Cache hit for $barcode');
    return cached;
  }

  // NEW: 1.5 Firebase cache
  if (_firebaseCache != null && _firebaseCache.isAvailable) {
    try {
      final fbProduct = await _firebaseCache.resolveBarcodedProduct(
        barcode,
        languageCode: lang,
      );
      if (fbProduct != null) {
        logInfo('Firebase cache hit for $barcode');
        return fbProduct;
      }
    } on Exception catch (e) {
      logWarning('Firebase cache lookup failed for $barcode: $e');
    }
  }

  // 2. Try primary API (existing)
  try {
    logInfo('Fetching $barcode from primary API');
    final remote = await _api.getByBarcode(barcode, languageCode: lang);
    await _db.insertProduct(remote);
    // Fire-and-forget Firebase cache write
    unawaited(_firebaseCache?.cacheBarcodedProduct(remote));
    logInfo('Fetched and cached $barcode');
    return remote;
  } on ProductNotFoundException {
    // ... existing fallback logic unchanged
  }
}
```

### 9.3 `_resolveProduceProduct` -- insert Firebase check

```dart
Future<Product> _resolveProduceProduct(
  String produceName,
  String barcode,
) async {
  // NEW: 1. Firebase cache first
  if (_firebaseCache != null) {
    try {
      final cached = await _firebaseCache.resolveProduceProduct(produceName);
      if (cached != null) {
        logInfo('Firebase produce cache hit for "$produceName"');
        return cached.copyWith(
          barcode: barcode,
          productType: ProductType.produce,
          source: 'manual',
          category: ProduceCategoryMapper.forName(produceName),
          lastSynced: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } on Exception catch (e) {
      logWarning('Firebase produce cache lookup failed: $e');
    }
  }

  // 2. USDA API (existing)
  if (_usdaClient != null) {
    try {
      final usdaResults = await _usdaClient.searchFood(produceName);
      if (usdaResults.isNotEmpty) {
        final usda = usdaResults.first;
        // Fire-and-forget Firebase cache write
        unawaited(_firebaseCache?.cacheProduceProduct(
          usda.copyWith(name: produceName),
          produceName,
        ));
        return usda.copyWith(
          barcode: barcode,
          name: produceName,
          productType: ProductType.produce,
          source: 'manual',
          category: ProduceCategoryMapper.forName(produceName),
          lastSynced: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } on Exception catch (e) {
      logWarning('USDA lookup failed for "$produceName": $e');
    }
  }

  // 3. Hardcoded fallback (existing)
  final fallback = ProduceNutritionFallback.forName(produceName);
  if (fallback != null) {
    return Product(
      barcode: barcode,
      name: produceName,
      productType: ProductType.produce,
      source: 'manual',
      category: ProduceCategoryMapper.forName(produceName),
      energyKcal: fallback.energyKcal,
      proteinG: fallback.proteinG,
      carbsG: fallback.carbsG,
      fatG: fallback.fatG,
      fiberG: fallback.fiberG,
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // 4. Minimal product (existing)
  return Product(
    barcode: barcode,
    name: produceName,
    productType: ProductType.produce,
    source: 'manual',
    category: ProduceCategoryMapper.forName(produceName),
    lastSynced: DateTime.now().millisecondsSinceEpoch,
  );
}
```

### 9.4 `addProduceToInventory` -- no change needed

The `addProduceToInventory` method already checks `_db.getProduct(barcode)` before calling `_resolveProduceProduct`. Since `_resolveProduceProduct` now checks Firebase, the flow is:

```
addProduceToInventory("Apple", inventoryId: 1)
  -> _db.getProduct("produce-Apple") -- local SQLite check (existing)
  -> null (first time)
  -> _resolveProduceProduct("Apple", "produce-Apple")
       -> Firebase cache check (NEW)
       -> USDA API (existing)
  -> cacheProduct(product) -- stores in SQLite (existing)
  -> insert or merge inventory item (existing)
```

---

## 10. Providers

### 10.1 `firebaseCacheProvider`

```dart
// lib/providers/firebase_cache_provider.dart

import 'package:pantry_app/config.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/firebase_cache_client.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [FirebaseCacheService] singleton.
///
/// If [AppConfig.firebaseEnabled] is false, the service is created with
/// [FirebaseCacheClient.isAvailable] returning false, making all
/// operations no-ops. This allows the entire caching layer to be merged
/// and tested before the Firebase project is configured.
final firebaseCacheProvider = Provider<FirebaseCacheService>((ref) {
  final db = ref.read(databaseProvider);
  final api = ref.read(apiServiceProvider);

  dynamic firestore;
  if (AppConfig.firebaseEnabled) {
    try {
      // Lazy import: FirebaseFirestore is only required when enabled.
      // ignore: unused_import, depend_on_referenced_packages
      firestore = FirebaseFirestore.instance;
    } on Exception catch (e) {
      logWarning('Firestore unavailable, caching disabled: $e');
    }
  }

  final client = FirebaseCacheClient(
    firestore: firestore,
    enabled: firestore != null,
  );

  return FirebaseCacheService(
    db: db,
    firebaseClient: client,
    usdaClient: UsdaApiClient(),
    offAdapter: api,
  );
});
```

### 10.2 `productRepositoryProvider` change

```dart
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.read(databaseProvider);
  final api = ref.read(apiServiceProvider);
  final firebaseCache = ref.read(firebaseCacheProvider);
  return ProductRepository(
    db,
    api,
    usdaClient: UsdaApiClient(),
    firebaseCache: firebaseCache,     // NEW
  );
});
```

---

## 11. `main.dart` Changes

### 11.1 Firebase initialization in `main()`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SnackbarHelper.messengerKey = rootMessengerKey;

  if (kDebugMode) {
    SemanticsBinding.instance.ensureSemantics();
  }

  await dotenv.load();
  logInfo('Environment loaded');

  // NEW: Firebase initialization
  if (AppConfig.firebaseEnabled) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logInfo('Firebase initialized successfully');
    } on Exception catch (e) {
      logWarning('Firebase init failed (graceful degradation): $e');
    }
  }

  // ... rest of existing main() unchanged ...
```

### 11.2 Background refresh scheduling in `_runPostInitTasks()`

```dart
void _runPostInitTasks() {
  // ... existing tasks ...

  // NEW: Firebase cache refresh
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 8),
      _refreshFirebaseCache,
    ),
  );
}

Future<void> _refreshFirebaseCache() async {
  try {
    final cacheService = appContainer.read(firebaseCacheProvider);
    if (cacheService.isAvailable) {
      final refreshed = await cacheService.refreshStaleEntries();
      if (refreshed > 0) {
        logInfo('Firebase cache: $refreshed entries refreshed');
      }
    }
  } on Exception catch (e) {
    logWarning('Firebase cache refresh failed: $e');
  }
}
```

The 8-second delay ensures the refresh runs after:

- Database initialization (frame 0)
- Database cleanup (200ms)
- Feedback queue flush (400ms)
- Notification scheduling (600ms)
- Product submission flush (800ms)
- Initial cache refresh (runs immediately)

This avoids competing for network bandwidth with the more time-sensitive startup tasks.

---

## 12. TDD Test Plan

All tests follow the existing codebase conventions: `mocktail` for mocks, `sqflite_common_ffi` for in-memory SQLite, 80-char lines, single quotes. Red-Green-Refactor per test.

### 12.1 Step 1: `ProduceCacheEntry` tests

**File**: `test/models/produce_cache_entry_test.dart` (10 tests)

| #   | Test Name                                              | What It Verifies                                                             |
| --- | ------------------------------------------------------ | ---------------------------------------------------------------------------- |
| 1   | `fromJson deserializes valid map`                      | All fields correctly parsed from a representative JSON map                   |
| 2   | `toJson serializes to expected map`                    | Round-trip: toJson -> fromJson -> same object                                |
| 3   | `fromProduct creates entry with 180-day nextRefreshAt` | `nextRefreshAt - lastRefreshedAt == 180 * 86400000` (within 100ms tolerance) |
| 4   | `fromProduct sets createdAt == lastRefreshedAt == now` | All three timestamps are within 100ms of each other                          |
| 5   | `fromProduct copies nutrition fields`                  | Maps energyKcal, proteinG, carbsG, fatG, fiberG from Product                 |
| 6   | `fromProduct handles null nutrition gracefully`        | Empty nutrition map when all fields are null                                 |
| 7   | `fromProduct preserves category`                       | Category string transferred from Product                                     |
| 8   | `toProduct creates valid Product`                      | Returns Product with correct barcode, name, ProductType.produce              |
| 9   | `toProduct handles empty nutrition`                    | All nutrition fields are null on the resulting Product                       |
| 10  | `withRefreshedData preserves createdAt`                | Created entry, refreshed, createdAt matches original                         |

### 12.2 Step 2: `ProductCacheEntry` tests

**File**: `test/models/product_cache_entry_test.dart` (12 tests)

| #   | Test Name                                              | What It Verifies                                                                                                                    |
| --- | ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `fromJson deserializes valid map`                      | All fields correctly parsed                                                                                                         |
| 2   | `toJson produces expected map`                         | Round-trip: toJson -> fromJson -> same object                                                                                       |
| 3   | `fromProduct creates entry with 180-day nextRefreshAt` | `nextRefreshAt - lastRefreshedAt == 180 * 86400000`                                                                                 |
| 4   | `fromProduct copies all relevant fields`               | barcode, name, brand, nutrition, category, categoriesHierarchy, ingredients, servingSize, nutriscoreGrade, image URLs, languageCode |
| 5   | `fromProduct excludes local-only fields`               | `nutritionImagePath`, `submissionStatus`, `source` NOT present in toJson output                                                     |
| 6   | `toProduct reconstructs equivalent Product`            | Round-trip: Product -> fromProduct -> toProduct -> same fields (except local-only)                                                  |
| 7   | `toProduct sets lastSynced to approx now`              | Within 100ms of current time                                                                                                        |
| 8   | `fromProduct handles null nutrition fields`            | Null fields omitted from output map                                                                                                 |
| 9   | `fromProduct handles null image URLs`                  | Null image URLs produce null in output                                                                                              |
| 10  | `fromProduct handles null categoriesHierarchy`         | Handles null list gracefully                                                                                                        |
| 11  | `fromProduct handles null ingredients`                 | ingredients field is null in output                                                                                                 |
| 12  | `withRefreshedData preserves createdAt`                | Created entry, refreshed, createdAt matches original                                                                                |

### 12.3 Step 3: `FirebaseCacheMetaDao` tests

**File**: `test/database/firebase_cache_meta_dao_test.dart` (14 tests)

**Setup**: `sqfliteFfiInit()` in `setUpAll`, in-memory database via `DatabaseHelper.withPath(inMemoryDatabasePath)`.

| #   | Test Name                                                   | What It Verifies                                         |
| --- | ----------------------------------------------------------- | -------------------------------------------------------- |
| 1   | `upsert creates row for barcoded type`                      | Row exists with correct cache_key, cache_type='barcoded' |
| 2   | `upsert creates row for produce type`                       | cache_key starts with 'produce:', cache_type='produce'   |
| 3   | `upsert overwrites existing row`                            | Insert same key with new data, verified via get          |
| 4   | `get retrieves by cache_key`                                | Returns correct row                                      |
| 5   | `get returns null for missing key`                          | Non-existent key returns null                            |
| 6   | `getStaleEntries returns entries with past next_refresh_at` | Entries with `next_refresh_at < now` are returned        |
| 7   | `getStaleEntries excludes future entries`                   | Entries with `next_refresh_at >= now` are NOT returned   |
| 8   | `getStaleEntries filters by cacheType`                      | Only matching type returned                              |
| 9   | `getAllKeys returns all cache keys`                         | Count and content verify                                 |
| 10  | `getAllKeys filters by cacheType`                           | Only matching type keys returned                         |
| 11  | `remove deletes the entry`                                  | Row gone, get returns null                               |
| 12  | `updateRefreshTimestamps updates only time columns`         | Other columns (cache_key, cache_type, fdc_id) unchanged  |
| 13  | `count returns correct total`                               | 3 entries of type 'barcoded' + 2 of 'produce' = 5 total  |
| 14  | `count filters by cacheType`                                | 3 for 'barcoded', 2 for 'produce'                        |

### 12.4 Step 4: `FirebaseCacheClient` tests

**File**: `test/services/firebase_cache_client_test.dart` (16 tests)

**Setup**: Mock FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot.

| #   | Test Name                                               | What It Verifies                                |
| --- | ------------------------------------------------------- | ----------------------------------------------- |
| 1   | `getProduce returns entry when doc exists`              | Returns ProduceCacheEntry with correct fields   |
| 2   | `getProduce returns null when doc missing`              | Document exists=false -> null                   |
| 3   | `getProduce returns null when not available`            | isAvailable=false -> null                       |
| 4   | `getProduce returns null on Firestore error`            | Exception thrown -> null (graceful)             |
| 5   | `setProduce writes to Firestore and returns true`       | Verify correct collection/doc path, return true |
| 6   | `setProduce returns false when not available`           | isAvailable=false -> false                      |
| 7   | `setProduce returns false on Firestore error`           | Exception on set -> false                       |
| 8   | `getProduct (barcoded) returns entry when doc exists`   | Returns ProductCacheEntry                       |
| 9   | `getProduct returns null on miss / unavailable / error` | All three paths return null                     |
| 10  | `setProduct writes to Firestore and returns true`       | Verify correct collection/doc path              |
| 11  | `deleteProduce calls delete on correct doc`             | Verify correct Firestore path called            |
| 12  | `deleteProduct calls delete on correct doc`             | Verify correct Firestore path called            |
| 13  | `isAvailable true when firestore injected and enabled`  | Both conditions met                             |
| 14  | `isAvailable false when enabled=false`                  | Feature flag off                                |
| 15  | `isAvailable false when firestore=null`                 | No Firebase instance                            |
| 16  | `_produceCollection and _productCollection are correct` | Verify collection names match expectations      |

### 12.5 Step 5: `FirebaseCacheService` tests

**File**: `test/services/firebase_cache_service_test.dart` (22 tests)

**Setup**: Mock `DatabaseHelper`, `FirebaseCacheClient`, `UsdaApiClient`, `OffAdapter`, `FirebaseCacheMetaDao`. Register fallback values for `Product`, `ProduceCacheEntry`, `ProductCacheEntry`.

#### Lookup tests for `resolveBarcodedProduct`:

| #   | Test Name                                                        | What It Verifies                                                                                    |
| --- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| 1   | **Firebase hit**: returns Product, no OFF call                   | Firebase returns entry -> converted to Product -> cached locally + meta updated -> OFF never called |
| 2   | **Firebase miss, OFF hit**: returns Product, caches in Firebase  | Firebase returns null -> OFF returns Product -> product cached in Firebase + local + meta           |
| 3   | **Both miss**: returns null                                      | Firebase null, OFF throws ProductNotFoundException -> null                                          |
| 4   | **Firebase unavailable**: skips to OFF immediately               | isAvailable=false -> directly calls OFF                                                             |
| 5   | **Firebase get throws**: falls through to OFF                    | Firestore exception -> OFF called as fallback                                                       |
| 6   | **Firebase set throws after OFF success**: still returns Product | Firestore write failure logged but product still returned (local cache works)                       |

#### Lookup tests for `resolveProduceProduct`:

| #   | Test Name                                                        | What It Verifies                                                                    |
| --- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| 7   | **Firebase hit**: returns Product, no USDA call                  | Firebase returns entry -> converted -> cached locally -> USDA not called            |
| 8   | **Firebase miss, USDA hit**: returns Product, caches in Firebase | Firebase null -> USDA returns -> cached in Firebase + local + meta                  |
| 9   | **Both miss**: returns null                                      | Firebase null, USDA returns empty -> null                                           |
| 10  | **Firebase unavailable**: skips to USDA                          | isAvailable=false -> directly calls USDA                                            |
| 11  | **USDA returns product with null nutrition**: still cached       | Nutrition fields null -> entry created with empty nutrition map -> product returned |

#### Refresh tests:

| #   | Test Name                                                    | What It Verifies                                                                                              |
| --- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| 12  | **No stale entries**: returns 0                              | Meta query returns empty -> no API calls -> returns 0                                                         |
| 13  | **One stale barcoded**: refreshes successfully               | OFF called -> Firestore updated -> meta timestamps updated -> returns 1                                       |
| 14  | **One stale produce**: refreshes successfully                | USDA called -> Firestore updated -> meta timestamps updated -> returns 1                                      |
| 15  | **Multiple stale (mixed types)**: all refreshed sequentially | 3 entries, each with 500ms delay, all succeed -> returns 3                                                    |
| 16  | **Stale, API fails (network)**: skipped, continues           | OFF/USDA throws -> entry skipped (nextRefreshAt unchanged) -> continues to next -> returns count of successes |
| 17  | **Stale, API fails (not found)**: skipped                    | ProductNotFoundException -> entry skipped -> continues                                                        |
| 18  | **createdAt preserved on refresh**                           | Original createdAt value persists after refresh call                                                          |
| 19  | **maxBatchSize respected**                                   | 25 stale entries, maxBatchSize=20 -> only 20 processed                                                        |
| 20  | **Firebase unavailable during refresh**: returns 0           | isAvailable=false -> no operations -> returns 0                                                               |

#### Edge case tests:

| #   | Test Name                                       | What It Verifies                                                         |
| --- | ----------------------------------------------- | ------------------------------------------------------------------------ |
| 21  | **Produce entry with empty name**: returns null | Empty/whitespace input -> null                                           |
| 22  | **Concurrent lookup and refresh**: no errors    | Lookup reads current state while refresh writes -> no crash, no deadlock |

### 12.6 Step 6: `ProductRepository` integration tests

**File**: Existing `test/services/product_repository_test.dart` extended (+5 tests)

| #   | Test Name                                                       | What It Verifies                                                                 |
| --- | --------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| 1   | `getProduct checks Firebase after local miss`                   | FirebaseCacheService.resolveBarcodedProduct called when local cache returns null |
| 2   | `getProduct does not call Firebase on local hit`                | Local cache returns product -> Firebase NOT called                               |
| 3   | `getProduct falls through to OFF when Firebase miss`            | Firebase returns null -> OFF API called                                          |
| 4   | `resolveProduceProduct checks Firebase before USDA`             | Firebase called first when firebaseCache is available                            |
| 5   | `resolveProduceProduct does not call Firebase when unavailable` | Firebase not available -> directly calls USDA                                    |

---

## 13. Database Migration Test

**File**: `test/database/database_helper_test.dart` (append to existing)

```dart
group('Migration v23 -> v24', () {
  test('creates firebase_cache_meta table and preserves existing data', () async {
    final tempDir = Directory.systemTemp.createTempSync('pantry_v23_');
    final v23Path = '${tempDir.path}/pantry.db';

    // Create a v23 database with the same schema as current _onCreate
    final v23Db = await openDatabase(v23Path, version: 23,
      onCreate: (db, _) async {
        // Create all v23 tables (products, inventories, inventory,
        // product_submission_queue, prices,
        // shopping_list, stores)
        await db.execute('''
          CREATE TABLE products (
            barcode TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            brand TEXT,
            image_url TEXT,
            category TEXT,
            ingredients TEXT,
            serving_size TEXT,
            energy_kcal REAL,
            protein_g REAL,
            carbs_g REAL,
            fat_g REAL,
            fiber_g REAL,
            salt_g REAL,
            last_synced INTEGER,
            nutriscore_grade TEXT,
            nutriscore_not_applicable_category TEXT,
            source TEXT NOT NULL DEFAULT 'api',
            nutrition_image_path TEXT,
            ingredients_image_path TEXT,
            product_image_path TEXT,
            submission_status TEXT NOT NULL DEFAULT 'not_submitted',
            off_nutrition_image_url TEXT,
            off_ingredients_image_url TEXT,
            off_product_image_url TEXT,
            categories_hierarchy TEXT,
            language_code TEXT NOT NULL DEFAULT 'en',
            search_text TEXT,
            plu_code TEXT,
            product_type TEXT NOT NULL DEFAULT 'barcoded'
          )
        ''');
        // ... inventories, inventory,
        //     product_submission_queue, prices,
        //     shopping_list, stores tables ...
        await db.execute('''
          CREATE TABLE inventories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode TEXT NOT NULL,
            quantity REAL DEFAULT 1,
            unit TEXT DEFAULT 'pieces',
            expiry_date TEXT,
            location TEXT DEFAULT 'pantry',
            notes TEXT,
            date_added INTEGER,
            inventory_id INTEGER NOT NULL DEFAULT 1,
            serving_weight_g REAL,
            FOREIGN KEY(barcode) REFERENCES products(barcode),
            FOREIGN KEY(inventory_id) REFERENCES inventories(id)
          )
        ''');
        // Insert test data
        await db.insert('inventories', {
          'id': 1, 'name': 'Home', 'created_at': 1000,
        });
        await db.insert('products', {
          'barcode': 'test123',
          'name': 'Test Product',
          'product_type': 'barcoded',
        });
        await db.insert('inventory', {
          'barcode': 'test123',
          'inventory_id': 1,
        });
      },
    );
    await v23Db.close();

    // Open with v24 DatabaseHelper -- migration runs automatically
    final dbHelper = DatabaseHelper.withPath(v23Path);
    await dbHelper.database;

    // Verify firebase_cache_meta table exists
    final db = await dbHelper.database;
    final tableResult = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type='table' AND name='firebase_cache_meta'",
    );
    expect(tableResult, isNotEmpty);

    // Verify migration is idempotent (closing and reopening doesn't error)
    await db.close();
    final dbHelper2 = DatabaseHelper.withPath(v23Path);
    await dbHelper2.database;

    // Verify existing data is intact
    final product = await dbHelper2.getProduct('test123');
    expect(product, isNotNull);
    expect(product!.name, 'Test Product');

    // Verify we can insert into the new table
    final metaDb = await dbHelper2.database;
    await FirebaseCacheMetaDao().upsert(
      metaDb,
      'test123',
      'barcoded',
      lastRefreshedAt: 1000,
      nextRefreshAt: 1000 + (180 * 86400000),
    );
    final metaEntry = await FirebaseCacheMetaDao().get(metaDb, 'test123');
    expect(metaEntry, isNotNull);
    expect(metaEntry!['cache_type'], 'barcoded');

    await metaDb.close();
    tempDir.deleteSync(recursive: true);
  });
});
```

---

## 14. Firestore Security Rules

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // =============================================================
    //  Produce cache — USDA nutrition data
    // =============================================================
    // Readable by anyone (anonymous users can look up produce nutrition).
    // Writable only by authenticated users (prevents abuse).
    match /produce_cache/{document} {

      allow read: if true;

      allow create: if request.auth != null
        && request.resource.data.keys().hasAll([
          'fdcId', 'name', 'nutrition',
          'createdAt', 'lastRefreshedAt', 'nextRefreshAt',
        ]);

      allow update: if request.auth != null
        && request.resource.data.lastRefreshedAt
             > resource.data.lastRefreshedAt;

      allow delete: if request.auth != null;
    }

    // =============================================================
    //  Product cache — OFF barcoded product data
    // =============================================================
    match /product_cache/{document} {

      allow read: if true;

      allow create: if request.auth != null
        && request.resource.data.keys().hasAll([
          'barcode', 'name',
          'createdAt', 'lastRefreshedAt', 'nextRefreshAt',
        ]);

      allow update: if request.auth != null
        && request.resource.data.lastRefreshedAt
             > resource.data.lastRefreshedAt;

      allow delete: if request.auth != null;
    }
  }
}
```

**Security rule rationale:**

| Rule                              | Rationale                                                                                                                                                             |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `read: if true`                   | Nutrition data is public information. No auth required to read. This also enables anonymous users (first-time app users) to benefit from the cache.                   |
| `create: if request.auth != null` | Only authenticated users can add new data. Prevents anonymous abuse.                                                                                                  |
| `lastRefreshedAt` check on update | Prevents accidentally overwriting fresh data with stale data. If two devices refresh the same document simultaneously, the one with the newer `lastRefreshedAt` wins. |
| Required fields on create         | Enforces document schema at the Firestore level. Prevents malformed documents.                                                                                        |

---

## 15. Edge Cases & Pitfalls

### 15.1 Firebase configuration and initialization

| #   | Pitfall                                                                           | Severity | Mitigation                                                                                                                                                           |
| --- | --------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **No `google-services.json`** — app crashes on `Firebase.initializeApp()`         | High     | Wrapped in try/catch in `main.dart`. If init fails, `firebaseEnabled` flag stays false. `FirebaseCacheClient.isAvailable` returns false. App works exactly as today. |
| 2   | **Firestore init succeeds but first read/write fails** (bad rules, wrong project) | Medium   | Every `FirebaseCacheClient` method catches `FirebaseException` and returns `null`/`false`. Graceful degradation.                                                     |
| 3   | **`FIREBASE_ENABLED=true` but no `.env` entry**                                   | Low      | `AppConfig.firebaseEnabled` returns `false` (?? operator). Safe default.                                                                                             |
| 4   | **Firebase configured for wrong platform** (e.g., Android project on iOS)         | Medium   | `Firebase.initializeApp()` throws `FirebaseException`. Caught at startup. Feature flag degrades.                                                                     |

### 15.2 Cache consistency and staleness

| #   | Pitfall                                                                              | Severity | Mitigation                                                                                                                                                                                                                                      |
| --- | ------------------------------------------------------------------------------------ | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5   | **OFF product data changes between refreshes** (ingredients updated, image replaced) | Low      | 180-day refresh will pick up changes. Data is typically stable for OFF. Users who need instant freshness can use pull-to-refresh (existing `refreshInventoryProducts` flow, which hits OFF API directly).                                       |
| 6   | **USDA produce data changes** (rare, but possible with new nutritional research)     | Low      | 180-day refresh picks up changes. USDA Foundation Foods are well-established and rarely change.                                                                                                                                                 |
| 7   | **Firestore doc deleted manually** (from Firebase Console)                           | Low      | On next lookup, `getProduce`/`getProduct` returns null. Falls through to source API. Re-creates doc. SQLite meta table still references it -> next refresh cycle re-creates the Firestore doc.                                                  |
| 8   | **Stale data served because app hasn't been opened in 200 days**                     | Low      | On first startup after 200 days, ALL entries are stale. `refreshStaleEntries` refreshes up to 20 per run. Remaining entries refresh on subsequent startups. During the transition period, stale but valid data is served (better than no data). |

### 15.3 Refresh mechanics

| #   | Pitfall                                                                      | Severity | Mitigation                                                                                                                                                                                                                                     |
| --- | ---------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 9   | **App killed during refresh**                                                | Low      | Unprocessed entries retain old `nextRefreshAt`. On next startup, `refreshStaleEntries` picks them up. Already-refreshed entries have new timestamps. No partial state corruption because each entry is processed independently in a try/catch. |
| 10  | **Refresh hits USDA rate limit** (360 req/min)                               | Medium   | 500ms delay = 2 req/sec = 120 req/min. Well under limit. Even in worst case (batch of 20), it takes ~10 seconds = 20 requests.                                                                                                                 |
| 11  | **Refresh hits OFF rate limit** (unknown, but typically generous)            | Low      | Same 500ms delay pattern. If OFF returns 429, the entry fails and is skipped. Retried next startup.                                                                                                                                            |
| 12  | **Hundreds of stale entries on first launch** (after months without opening) | Low      | Max batch of 20 per run. Remaining entries refresh over subsequent app launches. Each batch takes ~10 seconds. Users won't notice since it runs in the background.                                                                             |
| 13  | **`createdAt` gets overwritten on refresh**                                  | Medium   | Explicitly preserved: refresh reads existing Firestore doc, extracts `createdAt`, passes it to `fromProduct`. Test #18 verifies this.                                                                                                          |

### 15.4 Race conditions

| #   | Pitfall                                                              | Severity | Mitigation                                                                                                                                                                                                    |
| --- | -------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 14  | **User scans barcode while refresh is updating same Firestore doc**  | Low      | `resolveBarcodedProduct` reads Firestore. If refresh hasn't written yet, reads current data. If refresh has written, reads new data. No inconsistency because refresh writes complete documents atomically.   |
| 15  | **Two app instances refresh the same document simultaneously**       | Low      | Last-writer-wins with `set()`. Since both instances fetch from the same source API (OFF/USDA), the data is identical. The `lastRefreshedAt` timestamp ensures the later write has a slightly later timestamp. |
| 16  | **Lookup writes SQLite while refresh reads SQLite** (different rows) | Low      | SQLite handles concurrent reads/writes via its internal lock. Even if they touch the same row, the lookup is a simple read (no transaction) and the refresh is a write. sqflite serializes these.             |
| 17  | **User adds produce while refresh is processing**                    | Low      | `addProduceToInventory` calls `_resolveProduceProduct` which reads Firebase. The refresh writes USDA data. Both are idempotent operations that don't interfere.                                               |

### 15.5 Data integrity

| #   | Pitfall                                                                                         | Severity       | Mitigation                                                                                                                                                                                                                                                                                   |
| --- | ----------------------------------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 18  | **PLU codes not stored in produce cache entry** (defaults to empty list)                        | Low            | `PluService` is the authoritative PLU source. The cache entry's `pluCodes` is supplementary. Future enhancement: populate during refresh by matching name against `PluService`.                                                                                                              |
| 19  | **Local-only Product fields not in Firestore** (`nutritionImagePath`, `submissionStatus`, etc.) | None by design | These fields are intentionally excluded from `ProductCacheEntry`. `toProduct()` sets them to defaults. The local SQLite `products` table is the authoritiative store for these fields.                                                                                                       |
| 20  | **Product name differs between OFF and cached Firestore version**                               | Low            | The cache stores whatever OFF returned. If OFF updates the name, the 180-day refresh picks it up. Meanwhile, the old name is still valid for the user's inventory (they added it with that name).                                                                                            |
| 21  | **`source` field on cached Product**: Firebase cache entries set `source: 'manual'`             | Low            | This is consistent with existing produce handling (`_resolveProduceProduct` sets `source: 'manual'`). The `source` field indicates "this product came from a fallback source, not OFF API." Barcoded products from Firebase will also have `source: 'api'` after the OFF API call in step 3. |

### 15.6 Firestore costs

| #   | Pitfall                                                           | Severity | Mitigation                                                                                                                                                                                                             |
| --- | ----------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 22  | **Firestore read cost scales with user base**                     | Medium   | Each produce/product lookup that misses the local `products` table but hits Firebase costs 1 Firestore read. For a typical session (adding 10 items to inventory), this is 10 reads. Free tier is 50K/day.             |
| 23  | **Firestore write cost from 180-day refresh**                     | Low      | ~1 write per unique product every 180 days. For a user with 100 unique products, that's ~200 writes/year = ~0.55/day. Free tier is 20K/day.                                                                            |
| 24  | **`refreshStaleEntries` querying Firestore for each stale entry** | Low      | The method does NOT scan Firestore. It queries SQLite `firebase_cache_meta` (free), then does one Firestore `get` (to read `createdAt`) and one `set` per stale entry. For a batch of 20, that's 20 reads + 20 writes. |

### 15.7 Privacy

| #   | Pitfall                                                                        | Severity | Mitigation                                                                                                                                                                                                                          |
| --- | ------------------------------------------------------------------------------ | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 25  | **Firestore stores product barcodes** — could be used to track what users scan | Low      | Barcodes are public information (anyone can look up a barcode on OFF). Nutrition data is public. No PII is stored. The Firestore rules require auth for writes but allow public reads, which is standard for shared-cache patterns. |
| 26  | **Firestore stores produce names** — could indicate dietary preferences        | Low      | Produce names like "Apple", "Banana" are not PII. No user-specific data (UID, device ID, location) is stored in the cache documents.                                                                                                |

### 15.8 Testing

| #   | Pitfall                                                     | Severity | Mitigation                                                                                                                                                                                                                                                                          |
| --- | ----------------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 27  | **Mocking FirebaseFirestore is complex**                    | Medium   | The `FirebaseCacheClient` constructor accepts `dynamic firestore`, making it trivial to inject mocks. The mock just needs to support `collection().doc().get()` and `collection().doc().set()` — three levels of method chaining. mocktail handles this with `when().thenAnswer()`. |
| 28  | **Time-sensitive tests** (timestamps, 180-day calculations) | Low      | Use `clock` package or inject a time source. In practice, asserting with tolerances (e.g., within 100ms) is sufficient.                                                                                                                                                             |
| 29  | **In-memory SQLite for DAO tests**                          | None     | Already the established pattern in the codebase (`sqflite_common_ffi` + `inMemoryDatabasePath`).                                                                                                                                                                                    |
| 30  | **Existing test suite regression**                          | High     | Run `flutter test --concurrency=2` before and after changes. Ensure all existing tests still pass. The integration is additive (new optional parameter, new optional checks) so no existing test should break.                                                                      |

---

## 16. Implementation Order

### Phase 1: Models and DAO (database layer)

| Step | Action                                                                | Files                                                                                          |
| ---- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| 1.1  | Write `ProduceCacheEntry` model + tests                               | `lib/models/produce_cache_entry.dart`, `test/models/produce_cache_entry_test.dart`             |
| 1.2  | Write `ProductCacheEntry` model + tests                               | `lib/models/product_cache_entry.dart`, `test/models/product_cache_entry_test.dart`             |
| 1.3  | Write `FirebaseCacheMetaDao` + tests                                  | `lib/database/firebase_cache_meta_dao.dart`, `test/database/firebase_cache_meta_dao_test.dart` |
| 1.4  | Add v24 migration + DAO property to `DatabaseHelper` + migration test | `lib/database/database_helper.dart`, extend `test/database/database_helper_test.dart`          |
| 1.5  | Run `dart run build_runner build --delete-conflicting-outputs`        | Generate `.g.dart` and `.freezed.dart` files                                                   |
| 1.6  | Run `flutter test --concurrency=2`                                    | Pass: 14 DAO tests + 22 model tests + 1 migration test                                         |

### Phase 2: Firestore client

| Step | Action                                               | Files                                                                                      |
| ---- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| 2.1  | Write `FirebaseCacheClient` + tests (mock Firestore) | `lib/services/firebase_cache_client.dart`, `test/services/firebase_cache_client_test.dart` |
| 2.2  | Run `flutter test --concurrency=2`                   | Pass: 16 client tests                                                                      |

### Phase 3: Cache service

| Step | Action                                               | Files                                                                                        |
| ---- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| 3.1  | Write `FirebaseCacheService` + tests (mock all deps) | `lib/services/firebase_cache_service.dart`, `test/services/firebase_cache_service_test.dart` |
| 3.2  | Run `flutter test --concurrency=2`                   | Pass: 22 service tests                                                                       |

### Phase 4: Integration

| Step | Action                                                        | Files                                            |
| ---- | ------------------------------------------------------------- | ------------------------------------------------ |
| 4.1  | Add `firebaseCache` parameter to `ProductRepository`          | `lib/services/product_repository.dart`           |
| 4.2  | Modify `getProduct` to check Firebase before OFF API          | `lib/services/product_repository.dart`           |
| 4.3  | Modify `_resolveProduceProduct` to check Firebase before USDA | `lib/services/product_repository.dart`           |
| 4.4  | Extend `product_repository_test.dart` with integration tests  | `test/services/product_repository_test.dart`     |
| 4.5  | Write `firebaseCacheProvider`                                 | `lib/providers/firebase_cache_provider.dart`     |
| 4.6  | Wire provider into `productRepositoryProvider`                | `lib/providers/product_repository_provider.dart` |
| 4.7  | Run `flutter test --concurrency=2`                            | Pass: all 5 integration tests + no regressions   |

### Phase 5: App initialization

| Step | Action                                                           | Files                             |
| ---- | ---------------------------------------------------------------- | --------------------------------- |
| 5.1  | Add `firebaseEnabled` to `AppConfig` + `.env.example`            | `lib/config.dart`, `.env.example` |
| 5.2  | Add `firebase_core` and `cloud_firestore` to `pubspec.yaml`      | `pubspec.yaml`                    |
| 5.3  | Run `flutter pub get`                                            | Resolve dependencies              |
| 5.4  | Add Firebase init + background refresh scheduling to `main.dart` | `lib/main.dart`                   |
| 5.5  | Run `dart analyze --fatal-infos --fatal-warnings`                | Zero warnings                     |
| 5.6  | Run `flutter test --concurrency=2`                               | All ~60+ tests pass               |

### Phase 6: Firebase project setup (manual, parallel)

| Step | Action                                          | Notes                                                            |
| ---- | ----------------------------------------------- | ---------------------------------------------------------------- |
| 6.1  | Create Firebase project in Firebase Console     | Use existing Google account                                      |
| 6.2  | Enable Firestore (native mode, choose region)   | us-central1 recommended for lowest latency                       |
| 6.3  | Deploy security rules from Section 14           | Via Firebase Console or `firebase deploy --only firestore:rules` |
| 6.4  | Run `flutterfire configure`                     | Generates `google-services.json`, `firebase_options.dart`        |
| 6.5  | Add `FIREBASE_ENABLED=true` to `.env` on device | Enable caching                                                   |

### Phase 7: QA

| Step | Action                                       | Expected Result                                                     |
| ---- | -------------------------------------------- | ------------------------------------------------------------------- |
| 7.1  | `flutter run` on emulator                    | App starts without Firebase crash                                   |
| 7.2  | Scan a barcode                               | Product cached in `product_cache/{barcode}` in Firestore Console    |
| 7.3  | Add "Apple" to inventory                     | Entry appears in `produce_cache/apple` in Firestore Console         |
| 7.4  | Kill app, reopen, check logs                 | `refreshStaleEntries` runs after 8 seconds                          |
| 7.5  | Turn off network, scan same barcode again    | Served from local SQLite (existing behaviour, unchanged)            |
| 7.6  | Turn off network, add "Banana" (new produce) | Falls through to hardcoded fallback (existing behaviour, unchanged) |

---

## 17. Rollout Plan

### Phase A — Feature flag off (merge safe)

```env
FIREBASE_ENABLED=false
```

- `Firebase.initializeApp()` is never called (conditional on the flag)
- `FirebaseCacheProvider` creates a disabled `FirebaseCacheClient` with `isAvailable: false`
- `ProductRepository` gets `firebaseCache: null` (not passed from provider)
- Actually, let me be precise: the provider is always created, but with `isAvailable: false`
- All cache operations resolve to no-ops immediately
- All tests pass without any Firebase setup
- Full `dart analyze` and `flutter test` pass
- Safe to merge at any time — zero risk, zero new runtime dependencies activated

### Phase B — Firebase project setup (parallel, independent)

1. Developer creates Firebase project in Console
2. Developer runs `flutterfire configure` → generates `google-services.json` + `firebase_options.dart`
3. Developer deploys Firestore security rules
4. These files are committed (standard for Flutter projects)
5. No app code changes needed

### Phase C — Feature flag on + QA

```env
FIREBASE_ENABLED=true
```

1. App calls `Firebase.initializeApp()` on startup
2. All cache operations become live
3. Run QA checklist from Phase 7
4. Verify Firestore Console shows documents being created
5. Verify no regression in existing functionality

---

## 18. Firestore Cost Analysis

### Assumptions

- **Average user**: 60 unique OFF products + 40 unique produce items = 100 total cache entries
- **Firestore free tier**: 50,000 reads/day, 20,000 writes/day, 1 GiB stored
- **180-day refresh**: each entry refreshed once per 180 days

### Estimated costs per user per month

| Operation                     | Frequency                                                      | Firestore Ops                | Cost Tier                             |
| ----------------------------- | -------------------------------------------------------------- | ---------------------------- | ------------------------------------- |
| **Lookup (read)**             | ~2 per add-to-inventory session, ~20 sessions/month = 40 reads | 40 reads                     | Free                                  |
| **New product cache (write)** | ~10 new products/month                                         | 10 writes                    | Free                                  |
| **180-day refresh**           | 100 entries / 6 months = ~17 entries/month                     | 17 reads + 17 writes         | Free                                  |
| **Total**                     |                                                                | ~40 reads + ~27 writes/month | Free tier (50K reads, 20K writes/day) |

### Scaling

Even at 10,000 users, the cache layer would generate:

- **Reads**: 10,000 x 40 = 400,000 reads/month = ~13,333 reads/day (well under 50K/day free tier)
- **Writes**: 10,000 x 27 = 270,000 writes/month = ~9,000 writes/day (well under 20K/day free tier)

**Conclusion**: This cache design will comfortably stay within the Firestore free tier for the foreseeable future. No Blaze plan required.

### Storage estimate

- Average document size: ~500 bytes (ProduceCacheEntry) to ~800 bytes (ProductCacheEntry with all fields)
- Storage per user: 100 docs x 800 bytes = 80 KB
- 10,000 users: 800 MB
- Firestore free tier: 1 GiB storage

**Conclusion**: Storage is also within free tier limits for a mid-size user base.

---

## Appendix: Key Constants

| Constant                       | Value                                           | Location                                                       |
| ------------------------------ | ----------------------------------------------- | -------------------------------------------------------------- |
| 180-day interval               | `180 * 24 * 60 * 60 * 1000` = 15,552,000,000 ms | `_refreshIntervalMs` in both models and `FirebaseCacheService` |
| Max batch size                 | 20                                              | `_defaultMaxBatchSize` in `FirebaseCacheService`               |
| Refresh delay                  | 500 ms                                          | `_refreshDelay` in `FirebaseCacheService`                      |
| Startup refresh delay          | 8 seconds                                       | `main.dart` `_runPostInitTasks()`                              |
| Firestore collection (produce) | `produce_cache`                                 | `FirebaseCacheClient._produceCollection`                       |
| Firestore collection (product) | `product_cache`                                 | `FirebaseCacheClient._productCollection`                       |
| Produce cache key prefix       | `produce:`                                      | `FirebaseCacheService`                                         |
| Database version               | 24                                              | `DatabaseHelper._initDatabase()`                               |

---

## Appendix: Glossary

| Term                      | Definition                                                                                                              |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Firestore**             | Google Cloud Firestore, a NoSQL document database used as the shared remote cache                                       |
| **Firebase**              | Google's mobile development platform; we use Firebase Auth (future) and Firestore                                       |
| **OFF**                   | Open Food Facts, the primary data source for barcoded products                                                          |
| **USDA**                  | United States Department of Agriculture, FoodData Central API, source for produce nutrition data                        |
| **PLU code**              | Price Look-Up code, the 4-5 digit number on produce stickers (e.g., 4011 for banana)                                    |
| **`firebase_cache_meta`** | SQLite table that tracks which products have Firestore cache entries and when they need refresh                         |
| **`product_cache`**       | Firestore collection storing OFF barcoded product data, keyed by barcode                                                |
| **`produce_cache`**       | Firestore collection storing USDA produce data, keyed by canonical English name                                         |
| **180-day refresh**       | Per-document rolling refresh: each Firestore document is re-fetched from its source API 180 days after its last refresh |
| **Stale entry**           | A `firebase_cache_meta` row where `next_refresh_at < now`                                                               |
| **Graceful degradation**  | When Firebase is unavailable, the app continues working exactly as before (OFF API + USDA API + hardcoded fallbacks)    |
