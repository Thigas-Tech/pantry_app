import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/models/product.dart';

part 'product_cache_entry.freezed.dart';
part 'product_cache_entry.g.dart';

/// 180 days in milliseconds.
const int _productRefreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

/// Firestore document for the `product_cache/{barcode}` collection.
///
/// Stores OFF (Open Food Facts) barcoded product data in a shared cloud
/// cache so that multiple devices can benefit from a single API fetch.
/// Each document is keyed by the product's barcode (EAN-13, UPC, etc.).
///
/// ## Refresh cycle
///
/// Every document carries a [createdAt] (set once) and a [nextRefreshAt]
/// that is [lastRefreshedAt] + 180 days. The refresh loop re-fetches
/// from OFF and updates the document, preserving [createdAt] so we
/// always know how long the data has been cached.
///
/// ## Fields excluded from cache
///
/// The following [Product] fields are intentionally not stored in
/// Firestore because they are local-only or transient:
///
/// - `nutritionImagePath`, `ingredientsImagePath`, `productImagePath`
///   (local file paths, not portable across devices)
/// - `source` (always `'api'` for OFF products; irrelevant for cache)
/// - `submissionStatus` (transient submission state, not cacheable)
/// - `productType` (all entries in `product_cache` are implicitly barcoded)
/// - `pluCode` (only applies to produce, never to OFF barcoded items)
/// - `lastSynced` (replaced by [lastRefreshedAt] in the cache entry)
@freezed
abstract class ProductCacheEntry with _$ProductCacheEntry {
  /// Creates a [ProductCacheEntry].
  ///
  /// All required parameters must be provided; optional parameters have
  /// sensible defaults matching a minimal or unknown product.
  const factory ProductCacheEntry({
    /// The barcode (EAN-13, UPC, etc.) used as the Firestore document ID.
    required String barcode,

    /// The product name as returned by Open Food Facts.
    required String name,

    /// Epoch timestamp (ms) of when this entry was first created.
    required int createdAt,

    /// Epoch timestamp (ms) of when this entry was last refreshed.
    required int lastRefreshedAt,

    /// Epoch timestamp (ms) of when this entry should be refreshed next.
    required int nextRefreshAt,

    /// The brand name(s), often comma-separated.
    @JsonKey(includeIfNull: false) String? brand,

    /// The product category (e.g. `"Spreads, Sweet spreads"`).
    @JsonKey(includeIfNull: false) String? category,

    /// The OFF taxonomy hierarchy, broadest to most specific.
    @JsonKey(includeIfNull: false) List<String>? categoriesHierarchy,

    /// The full ingredients list as plain text.
    @JsonKey(includeIfNull: false) String? ingredients,

    /// The suggested serving size (e.g. `"15 g"`).
    @JsonKey(includeIfNull: false) String? servingSize,

    /// Energy in kilocalories per 100 g.
    @JsonKey(includeIfNull: false) double? energyKcal,

    /// Protein in grams per 100 g.
    @JsonKey(includeIfNull: false) double? proteinG,

    /// Carbohydrates in grams per 100 g.
    @JsonKey(includeIfNull: false) double? carbsG,

    /// Fat in grams per 100 g.
    @JsonKey(includeIfNull: false) double? fatG,

    /// Fiber in grams per 100 g.
    @JsonKey(includeIfNull: false) double? fiberG,

    /// Salt in grams per 100 g.
    @JsonKey(includeIfNull: false) double? saltG,

    /// The Nutri-Score grade (`'a'` through `'e'`), or `'not-applicable'`.
    @JsonKey(includeIfNull: false) String? nutriscoreGrade,

    /// URL to the product's front image on the OFF CDN.
    @JsonKey(includeIfNull: false) String? imageUrl,

    /// URL to the nutrition facts table image on the OFF CDN.
    @JsonKey(includeIfNull: false) String? offNutritionImageUrl,

    /// URL to the ingredients list image on the OFF CDN.
    @JsonKey(includeIfNull: false) String? offIngredientsImageUrl,

    /// URL to the product packaging image on the OFF CDN.
    @JsonKey(includeIfNull: false) String? offProductImageUrl,

    /// The locale used when fetching this product (e.g. `'en'`, `'pt'`).
    @Default('en') String languageCode,

    /// Schema version for forward compatibility.
    @Default(1) int schemaVersion,
  }) = _ProductCacheEntry;

  /// Private constructor for use by the freezed-generated subclass.
  const ProductCacheEntry._();

  /// Creates a [ProductCacheEntry] from a Firestore JSON map.
  factory ProductCacheEntry.fromJson(Map<String, dynamic> json) =>
      _$ProductCacheEntryFromJson(json);
}

/// Extension providing conversions to/from [Product].
extension ProductCacheEntryConversions on ProductCacheEntry {
  /// Creates a cache entry from a [Product] fetched from the OFF API.
  ///
  /// Local-only fields ([Product.nutritionImagePath],
  /// [Product.ingredientsImagePath], [Product.productImagePath],
  /// [Product.source], [Product.submissionStatus], [Product.productType],
  /// [Product.pluCode], [Product.lastSynced]) are intentionally excluded.
  /// If [createdAt] is omitted it is set to [lastRefreshedAt].
  static ProductCacheEntry fromProduct(
    Product product, {
    int? createdAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ProductCacheEntry(
      barcode: product.barcode,
      name: product.name,
      createdAt: createdAt ?? now,
      lastRefreshedAt: now,
      nextRefreshAt: now + _productRefreshIntervalMs,
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
    );
  }

  /// Converts this cache entry back to a local [Product].
  ///
  /// [Product.lastSynced] is set to the current timestamp.
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

  /// Returns a copy of [fresh] with [createdAt] preserved from this entry.
  ///
  /// Called during refresh to ensure the original creation timestamp is
  /// never overwritten.
  ProductCacheEntry withRefreshedData(ProductCacheEntry fresh) {
    return fresh.copyWith(createdAt: createdAt);
  }
}
