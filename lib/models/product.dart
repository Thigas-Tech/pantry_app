import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;

part 'product.freezed.dart';

/// Submission status: product has never been submitted.
const String productSubmissionNotSubmitted = 'not_submitted';

/// Submission status: queued for submission.
const String productSubmissionPending = 'pending';

/// Submission status: successfully submitted to Open Food Facts.
const String productSubmissionSubmitted = 'submitted';

/// Submission status: submission failed, retry possible.
const String productSubmissionFailed = 'failed';

/// Represents a cached product from Open Food Facts.
///
/// Each `Product` corresponds to a row in the `products` table. Unlike
/// `InventoryItem`, which tracks a specific instance of a product in the
/// user's pantry, this class holds **static product information** — data that
/// rarely changes and is shared by all instances of the same barcode.
///
/// ## Identity
///
/// The [barcode] field is the **primary key**. It is the unique identifier
/// used to fetch the product from the Open Food Facts API and to join with
/// the `inventory` table.
///
/// ## Nutrition
///
/// All nutrition values (energy, protein, carbs, fat, fiber, salt) follow the
/// Open Food Facts convention: they represent the amount **per 100 g** (or
/// 100 ml) of the product. The unit is always grams, except for energy which
/// is kilocalories (kcal). These fields may be `null` if the data was not
/// available from the API.
///
/// ## Source and freshness
///
/// - Data is fetched from the Open Food Facts API via the official
///   `openfoodfacts` Dart SDK and stored locally for offline use.
/// - [lastSynced] records an epoch timestamp (milliseconds since Unix epoch)
///   of when the product was last fetched. This can be used in the future to
///   implement cache freshness checks (e.g. re-fetch if older than 30 days).
///
/// ## Immutability
///
/// This class uses the `freezed` package, making it **immutable**. Any
/// modification must be done via the generated `copyWith` method, which
/// returns a new instance.
@freezed
abstract class Product with _$Product {
  /// Constructs a [Product].
  ///
  /// Only [barcode] and [name] are required; all other fields are optional
  /// and may not be present for every product.
  const factory Product({
    /// The barcode (EAN-13, UPC, etc.) that uniquely identifies the product.
    ///
    /// This is the primary key in the local database and the lookup key for
    /// the Open Food Facts API.
    required String barcode,

    /// The product name as returned by Open Food Facts.
    ///
    /// In rare cases the API may return an empty string; the repository
    /// should handle that gracefully.
    required String name,

    /// The brand name(s), often comma-separated when multiple brands exist
    /// (e.g. `"Ferrero"`, `"Nestle, Nespresso"`).
    String? brand,

    /// A URL to the product's front image on the Open Food Facts CDN.
    ///
    /// May be `null` if no image has been uploaded for this product.
    String? imageUrl,

    /// OFF CDN URL for the nutrition facts table image, if available.
    ///
    /// Used by the photo-completeness stats screen to compare local user
    /// photos against what OFF already has for this product.
    String? offNutritionImageUrl,

    /// OFF CDN URL for the ingredients list image, if available.
    String? offIngredientsImageUrl,

    /// OFF CDN URL for the product front/packaging image, if available.
    String? offProductImageUrl,

    /// The OFF taxonomy hierarchy for this product, from broadest to
    /// most specific. Each entry is a language-prefixed tag
    /// (e.g. `en:eggs`, `en:chicken-eggs`).
    ///
    /// May be `null` for manually entered products or when OFF has no
    /// taxonomy data.
    List<String>? categoriesHierarchy,

    /// The product category as assigned by the Open Food Facts community.
    ///
    /// Often a comma-separated hierarchy (e.g. `"Spreads, Sweet spreads"`).
    /// Used in the add-to-inventory screen to suggest a default expiry date
    /// based on the category (e.g., dairy -> +7 days).
    String? category,

    /// The full ingredients list as plain text.
    ///
    /// Currently stored as a single string, exactly as returned by the API.
    /// In the future this could be migrated to a separate `ingredients` table
    /// to enable allergen filtering or per-ingredient search.
    String? ingredients,

    /// The suggested serving size, typically with a unit (e.g. `"15 g"`,
    /// `"1 cookie (28 g)"`).
    String? servingSize,

    /// Energy content in **kilocalories per 100 g** (or 100 ml).
    ///
    /// Sourced from `nutriments.energy-kcal_100g` in the API response.
    double? energyKcal,

    /// Protein content in **grams per 100 g** (or 100 ml).
    double? proteinG,

    /// Carbohydrate content in **grams per 100 g** (or 100 ml).
    double? carbsG,

    /// Fat content in **grams per 100 g** (or 100 ml).
    double? fatG,

    /// Fiber content in **grams per 100 g** (or 100 ml).
    double? fiberG,

    /// Salt content in **grams per 100 g** (or 100 ml).
    double? saltG,

    /// Epoch timestamp (milliseconds since Unix epoch) of when the product
    /// data was last fetched from the API or submitted by the user.
    ///
    /// Set automatically when the product is fetched from the API or
    /// submitted by the user.
    int? lastSynced,

    /// The Nutri-Score grade of the product (`'a'` through `'e'`), or `null`
    /// if the data is unavailable. May also be `'not-applicable'` when the
    /// Nutri-Score system does not apply to this product category (e.g. food
    /// additives).
    ///
    /// Sourced from `nutrition_grade_fr` in the Open Food Facts v3 API via
    /// the SDK's `nutriscore` field.
    String? nutriscoreGrade,

    /// The product category that makes Nutri-Score not applicable, if any.
    ///
    /// This is present only when [nutriscoreGrade] is `'not-applicable'` and
    /// explains why (e.g. `'en:food-additives'`).
    ///
    /// Note: the official Dart SDK does not expose the
    /// `nutriscore_data.nutriscore_not_applicable_for_category` field, so
    /// this value is only populated when reading from the local database
    /// for previously cached products.
    String? nutriscoreNotApplicableCategory,

    /// The origin of this product record.
    ///
    /// - `'api'` — fetched from Open Food Facts (can be safely flushed and
    ///   re-fetched).
    /// - `'manual'` — entered by the user via the add-product screen or
    ///   imported from CSV (must never be deleted by a cache flush).
    ///
    /// Defaults to `'api'` because most products come from the OFF
    /// integration. The add-product screen and CSV import override it to
    /// `'manual'`.
    @Default('api') String source,

    /// Local file path to a photo of the nutrition facts table.
    ///
    /// Populated when the user captures a photo on the manual-entry screen.
    /// Stored as a stable path inside `<app-documents>/product_images/`.
    String? nutritionImagePath,

    /// Local file path to a photo of the ingredients list.
    ///
    /// Populated when the user captures a photo on the manual-entry screen.
    /// Stored as a stable path inside `<app-documents>/product_images/`.
    String? ingredientsImagePath,

    /// Local file path to a photo of the product packaging / front.
    ///
    /// Populated when the user captures a photo on the manual-entry screen.
    /// Stored as a stable path inside `<app-documents>/product_images/`.
    String? productImagePath,

    /// The submission status of this product to Open Food Facts.
    ///
    /// - [productSubmissionNotSubmitted] — not yet submitted (default).
    /// - [productSubmissionPending] — queued for submission.
    /// - [productSubmissionSubmitted] — successfully submitted.
    /// - [productSubmissionFailed] — submission failed; retry possible.
    @Default(productSubmissionNotSubmitted) String submissionStatus,
  }) = _Product;

  /// Creates a [Product] from an SDK [off.Product].
  ///
  /// Maps every field we need from the official SDK model to our local
  /// model. Local-only fields ([source], [submissionStatus],
  /// [nutritionImagePath], etc.) are set to their defaults because the
  /// SDK does not carry them. The [lastSynced] timestamp is set to now.
  factory Product.fromOffProduct(off.Product offProduct) {
    final n = offProduct.nutriments;
    return Product(
      barcode: offProduct.barcode ?? '',
      name: offProduct.productName ?? 'Unknown',
      brand: offProduct.brands,
      imageUrl: offProduct.imageFrontUrl,
      offNutritionImageUrl: offProduct.imageNutritionUrl,
      offIngredientsImageUrl: offProduct.imageIngredientsUrl,
      offProductImageUrl: offProduct.imageFrontUrl,
      categoriesHierarchy: offProduct.categoriesTags,
      category: offProduct.categories,
      ingredients: offProduct.ingredientsText,
      servingSize: offProduct.servingSize,
      energyKcal: n?.getValue(
        off.Nutrient.energyKCal,
        off.PerSize.oneHundredGrams,
      ),
      proteinG: n?.getValue(off.Nutrient.proteins, off.PerSize.oneHundredGrams),
      carbsG: n?.getValue(
        off.Nutrient.carbohydrates,
        off.PerSize.oneHundredGrams,
      ),
      fatG: n?.getValue(off.Nutrient.fat, off.PerSize.oneHundredGrams),
      fiberG: n?.getValue(off.Nutrient.fiber, off.PerSize.oneHundredGrams),
      saltG: n?.getValue(off.Nutrient.salt, off.PerSize.oneHundredGrams),
      lastSynced: DateTime.now().millisecondsSinceEpoch,
      nutriscoreGrade: offProduct.nutriscore,
    );
  }
}

/// Extension to convert our [Product] to an SDK [off.Product] for
/// submission to Open Food Facts via [off.OpenFoodAPIClient.saveProduct].
extension ProductToOff on Product {
  /// Converts this product to an SDK [off.Product].
  off.Product toOffProduct() {
    return off.Product(
      barcode: barcode,
      productName: name,
      brands: brand,
      categories: category,
      ingredientsText: ingredients,
      servingSize: servingSize,
    );
  }
}

/// Extension that provides safe API merge semantics on [Product].
///
/// `mergeFromApi` is defined as an extension rather than a method on the
/// abstract class because freezed generates a concrete implementation
/// (`_Product`) that `implements` (not `extends`) the abstract class.
///
/// ## Merge rules
///
/// - **API non-null wins** — if the API returned a value, it overwrites
///   the cached value.
/// - **API null preserves cached** — if the API didn't return a field
///   (e.g. the staging server lacks Nutri-Score data), the cached value
///   is kept. This prevents pull-to-refresh from silently wiping data.
/// - **Local-only fields are never touched** — [source],
///   [submissionStatus], [nutritionImagePath], [ingredientsImagePath], and
///   [productImagePath] are preserved exactly as-is.
/// - **Name sentinel** — if the API returns `'Unknown'` (the default when
///   the real name is missing), the cached name is kept.
///
/// This is the **safe-update** primitive for pull-to-refresh and post-flush
/// re-fetch operations. It guarantees that an incomplete API response can
/// never degrade the cached data.
extension ProductMerge on Product {
  /// Merges data from an API-fetched [api] product into this product,
  /// preserving local-only fields that the API does not return.
  ///
  /// Empty strings (`""`) from the API are treated the same as `null` to
  /// prevent incomplete API responses from overwriting cached data.
  Product mergeFromApi(Product api) {
    T? nonEmpty<T extends String>(T? value) =>
        (value != null && value.isNotEmpty) ? value : null;

    return copyWith(
      name: api.name != 'Unknown' ? api.name : name,
      brand: nonEmpty(api.brand) ?? brand,
      category: nonEmpty(api.category) ?? category,
      ingredients: nonEmpty(api.ingredients) ?? ingredients,
      servingSize: nonEmpty(api.servingSize) ?? servingSize,
      energyKcal: api.energyKcal ?? energyKcal,
      proteinG: api.proteinG ?? proteinG,
      carbsG: api.carbsG ?? carbsG,
      fatG: api.fatG ?? fatG,
      fiberG: api.fiberG ?? fiberG,
      saltG: api.saltG ?? saltG,
      imageUrl: nonEmpty(api.imageUrl) ?? imageUrl,
      offNutritionImageUrl:
          nonEmpty(api.offNutritionImageUrl) ?? offNutritionImageUrl,
      offIngredientsImageUrl:
          nonEmpty(api.offIngredientsImageUrl) ?? offIngredientsImageUrl,
      offProductImageUrl:
          nonEmpty(api.offProductImageUrl) ?? offProductImageUrl,
      nutriscoreGrade: nonEmpty(api.nutriscoreGrade) ?? nutriscoreGrade,
      nutriscoreNotApplicableCategory:
          nonEmpty(api.nutriscoreNotApplicableCategory) ??
          nutriscoreNotApplicableCategory,
      lastSynced: api.lastSynced ?? lastSynced,
    );
  }
}
