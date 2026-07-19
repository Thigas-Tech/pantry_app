import 'dart:async';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:pantry_app/models/produce_cache_entry.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_cache_entry.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/firebase_cache_client.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// 180 days in milliseconds — same interval used by the cache entry models.
const int _refreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

/// Orchestrator that coordinates between Firestore, local SQLite, and the
/// source APIs (USDA for produce, OFF for barcoded products).
///
/// ## Responsibilities
///
/// 1. **Lookup** — tries the Firebase cache first, falls through to the
///    source API when the cache misses or is unavailable.
/// 2. **Cache write** — after a successful source-API fetch, the result is
///    written to Firestore asynchronously (fire-and-forget).
/// 3. **Refresh** — iterates stale entries (those whose
///    [ProductCacheEntry.nextRefreshAt] has passed) and re-fetches fresh
///    data from the source APIs.
///
/// ## Graceful degradation
///
/// Every public method guards with [isAvailable]. When Firebase is unavailable
/// (no `google-services.json`, disabled feature flag, or runtime error) the
/// lookup methods bypass Firestore entirely and call the source API directly.
///
/// See [FirebaseCacheClient] for the low-level Firestore abstraction and
/// [FirebaseCacheMetaDao] for the SQLite metadata layer.
class FirebaseCacheService {
  /// Creates a [FirebaseCacheService].
  ///
  /// All dependencies are required except [metaDao]; when omitted the
  /// instance from [db] is used.
  FirebaseCacheService({
    required DatabaseHelper db,
    required this._firebaseClient,
    required this._usdaClient,
    required this._offAdapter,
    FirebaseCacheMetaDao? metaDao,
  }) : _db = db,
       _metaDao = metaDao ?? db.firebaseCacheMetaDao;

  final DatabaseHelper _db;
  final FirebaseCacheClient _firebaseClient;
  final UsdaApiClient _usdaClient;
  final OffAdapter _offAdapter;
  final FirebaseCacheMetaDao _metaDao;

  /// Whether the underlying Firebase client is available.
  bool get isAvailable => _firebaseClient.isAvailable;

  // =================================================================
  //  Lookup methods
  // =================================================================

  /// Looks up a barcoded product, trying Firebase first, then OFF.
  ///
  /// Returns `null` when the product is unknown to all sources.
  Future<Product?> resolveBarcodedProduct(
    String barcode, {
    required String languageCode,
  }) async {
    if (isAvailable) {
      try {
        final cached = await _firebaseClient.getProduct(barcode);
        if (cached != null) {
          final product = cached.toProduct();
          await _db.insertProduct(product);
          await _upsertMeta(barcode, 'barcoded');
          return product;
        }
      } on Exception catch (e) {
        logWarning('Firebase getProduct failed for $barcode: $e');
      }
    }

    try {
      final product = await _offAdapter.getByBarcode(
        barcode,
        languageCode: languageCode,
      );
      unawaited(cacheBarcodedProduct(product));
      return product;
    } on ProductNotFoundException {
      return null;
    } on Exception catch (e) {
      logWarning('OFF lookup failed for $barcode: $e');
      return null;
    }
  }

  /// Looks up a produce product, trying Firebase first, then USDA.
  ///
  /// Returns `null` when the produce is unknown to all sources or when
  /// [produceName] is empty.
  Future<Product?> resolveProduceProduct(String produceName) async {
    final trimmed = produceName.trim();
    if (trimmed.isEmpty) return null;

    final lowerName = trimmed.toLowerCase();

    if (isAvailable) {
      try {
        final cached = await _firebaseClient.getProduce(lowerName);
        if (cached != null) {
          final product = cached.toProduct(
            barcode: 'produce-${_capitalize(trimmed)}',
          );
          await _db.insertProduct(product);
          await _upsertMeta('produce:$lowerName', 'produce');
          return product;
        }
      } on Exception catch (e) {
        logWarning('Firebase getProduce failed for "$produceName": $e');
      }
    }

    try {
      final results = await _usdaClient.searchFood(produceName);
      if (results.isEmpty) return null;
      final product = results.first;
      final fdcId = int.tryParse(
        product.barcode.replaceFirst('plu-', ''),
      );
      unawaited(cacheProduceProduct(product, produceName, fdcId: fdcId));
      return product;
    } on Exception catch (e) {
      logWarning('USDA lookup failed for "$produceName": $e');
      return null;
    }
  }

  // =================================================================
  //  Cache write methods (fire-and-forget)
  // =================================================================

  /// Writes a barcoded product to the Firebase cache (fire-and-forget).
  ///
  /// This is called from the lookup path after a successful OFF fetch.
  /// Errors are caught and logged — the lookup result is never affected.
  Future<void> cacheBarcodedProduct(Product product) async {
    if (!isAvailable) return;
    try {
      final entry = ProductCacheEntryConversions.fromProduct(product);
      await _firebaseClient.setProduct(entry);
      await _upsertMeta(product.barcode, 'barcoded');
    } on Exception catch (e) {
      logWarning('cacheBarcodedProduct failed: $e');
    }
  }

  /// Writes a produce product to the Firebase cache (fire-and-forget).
  ///
  /// [produceName] is the human-readable name (e.g. "Apple"). The cache
  /// key is normalized to lowercase. [fdcId] is the USDA FDC identifier,
  /// or `null` when unknown.
  Future<void> cacheProduceProduct(
    Product product,
    String produceName, {
    int? fdcId,
  }) async {
    if (!isAvailable) return;
    try {
      final lowerName = produceName.trim().toLowerCase();
      final entry = ProduceCacheEntryConversions.fromProduct(
        product,
        fdcId ?? 0,
        englishName: lowerName,
      );
      await _firebaseClient.setProduce(entry);
      await _upsertMeta('produce:$lowerName', 'produce', fdcId: fdcId);
    } on Exception catch (e) {
      logWarning('cacheProduceProduct failed: $e');
    }
  }

  // =================================================================
  //  Refresh methods
  // =================================================================

  /// Re-fetches stale entries from the source APIs and updates Firebase.
  ///
  /// Returns the number of successfully refreshed entries. At most
  /// [maxBatchSize] entries are processed per call to avoid long-running
  /// background jobs. A 500 ms delay separates consecutive API calls to
  /// reduce the risk of rate limiting.
  Future<int> refreshStaleEntries({int maxBatchSize = 20}) async {
    if (!isAvailable) return 0;

    final db = await _db.database;
    final stale = await _metaDao.getStaleEntries(
      db,
      nowInMs: DateTime.now().millisecondsSinceEpoch,
    );
    if (stale.isEmpty) return 0;

    final toProcess = stale.take(maxBatchSize).toList();
    var successCount = 0;

    for (var i = 0; i < toProcess.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      final row = toProcess[i];
      final cacheKey = row['cache_key'] as String;
      final cacheType = row['cache_type'] as String;

      try {
        final refreshed = cacheType == 'produce'
            ? await _refreshProduceEntry(db, cacheKey)
            : await _refreshBarcodedEntry(db, cacheKey);
        if (refreshed) {
          successCount++;
        }
      } on Exception catch (e) {
        logWarning('Refresh failed for $cacheKey: $e');
      }
    }

    return successCount;
  }

  /// Refreshes a single produce entry by re-fetching from USDA.
  Future<bool> _refreshProduceEntry(Database db, String cacheKey) async {
    final name = cacheKey.startsWith('produce:')
        ? cacheKey.substring(8)
        : cacheKey;

    final results = await _usdaClient.searchFood(name);
    if (results.isEmpty) return false;

    final freshProduct = results.first;

    final fdcId = int.tryParse(
      freshProduct.barcode.replaceFirst('plu-', ''),
    );

    final existingEntry = await _firebaseClient.getProduce(name);
    final now = DateTime.now().millisecondsSinceEpoch;

    final freshEntry = ProduceCacheEntryConversions.fromProduct(
      freshProduct,
      fdcId ?? 0,
      englishName: name,
      createdAt: existingEntry?.createdAt,
    );
    final entry = existingEntry != null
        ? existingEntry.withRefreshedData(freshEntry)
        : freshEntry;

    await _firebaseClient.setProduce(entry);

    final localProduct = entry.toProduct(
      barcode: 'produce-${_capitalize(name)}',
    );
    await _db.insertProduct(localProduct);

    await _metaDao.updateRefreshTimestamps(
      db,
      cacheKey,
      lastRefreshedAt: now,
      nextRefreshAt: now + _refreshIntervalMs,
    );

    return true;
  }

  /// Refreshes a single barcoded entry by re-fetching from OFF.
  Future<bool> _refreshBarcodedEntry(Database db, String cacheKey) async {
    var languageCode = 'en';
    try {
      final existingEntry = await _firebaseClient.getProduct(cacheKey);
      languageCode = existingEntry?.languageCode ?? 'en';
    } on Exception {
      // Continue with default language code.
    }

    Product freshProduct;
    try {
      freshProduct = await _offAdapter.getByBarcode(
        cacheKey,
        languageCode: languageCode,
      );
    } on ProductNotFoundException {
      return false;
    }

    final existingEntry = await _firebaseClient.getProduct(cacheKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    final freshEntry = ProductCacheEntryConversions.fromProduct(
      freshProduct,
      createdAt: existingEntry?.createdAt,
    );
    final entry = existingEntry != null
        ? existingEntry.withRefreshedData(freshEntry)
        : freshEntry;

    await _firebaseClient.setProduct(entry);
    await _db.insertProduct(freshProduct);

    await _metaDao.updateRefreshTimestamps(
      db,
      cacheKey,
      lastRefreshedAt: now,
      nextRefreshAt: now + _refreshIntervalMs,
    );

    return true;
  }

  // =================================================================
  //  Helpers
  // =================================================================

  /// Upserts cache metadata with a 180-day refresh window.
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
        lastRefreshedAt: now,
        nextRefreshAt: now + _refreshIntervalMs,
        fdcId: fdcId,
      );
    } on Exception catch (e) {
      logWarning('_upsertMeta failed for $cacheKey: $e');
    }
  }

  /// Capitalizes the first letter of [s].
  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }
}
