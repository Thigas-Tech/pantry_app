import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';

part 'produce_cache_entry.freezed.dart';
part 'produce_cache_entry.g.dart';

/// 180 days in milliseconds.
const int _produceRefreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

/// Firestore document for the `produce_cache/{name}` collection.
///
/// Stores USDA produce nutrition data in a shared cloud cache so that
/// multiple devices can benefit from a single API fetch. Each document
/// is keyed by the lowercase English produce name (e.g. `apple`).
///
/// ## Refresh cycle
///
/// Every document carries a [createdAt] (set once) and a
/// [nextRefreshAt] that is [lastRefreshedAt] + 180 days. The refresh
/// loop re-fetches from USDA and updates the document, preserving
/// [createdAt] so we always know how long the data has been cached.
@freezed
abstract class ProduceCacheEntry with _$ProduceCacheEntry {
  /// Creates a [ProduceCacheEntry].
  ///
  /// All required parameters must be provided; optional parameters have
  /// sensible defaults matching an empty or unknown produce item.
  const factory ProduceCacheEntry({
    /// USDA FDC (FoodData Central) ID for this produce item.
    ///
    /// Set to `0` when the FDC ID is not known (e.g. from fallback data).
    required int fdcId,

    /// Lowercase English produce name used as the Firestore document ID
    /// (e.g. `"apple"`, `"banana"`).
    required String name,

    /// Nutrition per 100 g, keyed by nutrient name.
    ///
    /// Known keys: `energyKcal`, `proteinG`, `carbsG`, `fatG`, `fiberG`.
    /// An empty map means no nutrition data is available.
    required Map<String, double> nutrition,

    /// Epoch timestamp (ms) of when this entry was first created.
    required int createdAt,

    /// Epoch timestamp (ms) of when this entry was last refreshed.
    required int lastRefreshedAt,

    /// Epoch timestamp (ms) of when this entry should be refreshed next.
    required int nextRefreshAt,

    /// Localized names keyed by locale code (e.g. `{"pt": "Maca"}`).
    @Default({}) Map<String, String> localizedNames,

    /// PLU (Price Look-Up) codes associated with this produce item.
    @Default(<String>[]) List<String> pluCodes,

    /// The USDA food category (e.g. `"Fruits and Fruit Juices"`).
    @JsonKey(includeIfNull: false) String? category,

    /// Suggested serving size in grams. Null when unknown.
    @JsonKey(includeIfNull: false) double? servingSizeG,

    /// Schema version for forward compatibility.
    @Default(1) int schemaVersion,
  }) = _ProduceCacheEntry;

  /// Private constructor for use by the freezed-generated subclass.
  const ProduceCacheEntry._();

  /// Creates a [ProduceCacheEntry] from a Firestore JSON map.
  factory ProduceCacheEntry.fromJson(Map<String, dynamic> json) =>
      _$ProduceCacheEntryFromJson(json);
}

/// Extension providing conversions to/from [Product].
extension ProduceCacheEntryConversions on ProduceCacheEntry {
  /// Creates a cache entry from a [Product] returned by the USDA API.
  ///
  /// [fdcId] is the USDA FDC identifier. Pass `0` when unknown.
  /// [englishName] is the canonical lowercase name used as the Firestore
  /// document key. If [createdAt] is omitted it is set to [lastRefreshedAt].
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
      createdAt: createdAt ?? now,
      lastRefreshedAt: now,
      nextRefreshAt: now + _produceRefreshIntervalMs,
      category: product.category,
    );
  }

  /// Converts this cache entry back to a local [Product].
  ///
  /// The [barcode] parameter must be the synthetic barcode used for produce
  /// items (e.g. `"produce-Apple"`).
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

  /// Returns a copy of [fresh] with [createdAt] preserved from this entry.
  ///
  /// Called during refresh to ensure the original creation timestamp is
  /// never overwritten.
  ProduceCacheEntry withRefreshedData(ProduceCacheEntry fresh) {
    return fresh.copyWith(createdAt: createdAt);
  }
}
