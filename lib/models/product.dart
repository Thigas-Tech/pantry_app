import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

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
/// user’s pantry, this class holds **static product information** – data that
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
/// Open Food Facts convention: they represent the amount **per 100 g** (or
/// 100 ml) of the product. The unit is always grams, except for energy which
/// is kilocalories (kcal). These fields may be `null` if the data was not
/// available from the API.
///
/// ## Source and freshness
///
/// - Data is fetched from `https://world.openfoodfacts.org/api/v3/product/…`
///   and then stored locally for offline use.
/// - [lastSynced] records an epoch timestamp (milliseconds since Unix epoch)
///   of when the product was last fetched. This can be used in the future to
///   implement cache freshness checks (e.g. re‑fetch if older than 30 days).
///
///
/// ## JSON serialization
///
/// The [@JsonKey] annotations map the Open Food Facts API field names
/// (e.g. `product_name`, `brands`, `energy_kcal`) to the Dart property names.
/// This allows `Product.fromJson` to parse the v3 API response directly.
/// When reading from the local database the mapping is done manually by
/// `ProductDao.fromMap`.
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
    /// The barcode (EAN‑13, UPC, etc.) that uniquely identifies the product.
    ///
    /// This is the primary key in the local database and the lookup key for
    /// the Open Food Facts API.
    @JsonKey(name: '_id') required String barcode,

    /// The product name as returned by Open Food Facts.
    ///
    /// In rare cases the API may return an empty string; the repository
    /// should handle that gracefully.
    @JsonKey(name: 'product_name') required String name,

    /// The brand name(s), often comma‑separated when multiple brands exist
    /// (e.g. `"Ferrero"`, `"Nestlé, Nespresso"`).
    @JsonKey(name: 'brands') String? brand,

    /// A URL to the product’s front image on the Open Food Facts CDN.
    ///
    /// May be `null` if no image has been uploaded for this product.
    @JsonKey(name: 'image_url') String? imageUrl,

    /// OFF CDN URL for the nutrition facts table image, if available.
    ///
    /// Used by the photo-completeness stats screen to compare local user
    /// photos against what OFF already has for this product.
    @JsonKey(name: 'image_nutrition_url') String? offNutritionImageUrl,

    /// OFF CDN URL for the ingredients list image, if available.
    @JsonKey(name: 'image_ingredients_url') String? offIngredientsImageUrl,

    /// OFF CDN URL for the product front/packaging image, if available.
    @JsonKey(name: 'image_front_url') String? offProductImageUrl,

    /// The product category as assigned by the Open Food Facts community.
    ///
    /// Often a comma‑separated hierarchy (e.g. `"Spreads, Sweet spreads"`).
    /// Used in the add‑to‑inventory screen to suggest a default expiry date
    /// based on the category (e.g., dairy → +7 days).
    @JsonKey(name: 'category') String? category,

    /// The full ingredients list as plain text.
    ///
    /// Currently stored as a single string, exactly as returned by the API.
    /// In the future this could be migrated to a separate `ingredients` table
    /// to enable allergen filtering or per‑ingredient search.
    @JsonKey(name: 'ingredients_text') String? ingredients,

    /// The suggested serving size, typically with a unit (e.g. `"15 g"`,
    /// `"1 cookie (28 g)"`).
    @JsonKey(name: 'serving_size') String? servingSize,

    /// Energy content in **kilocalories per 100 g** (or 100 ml).
    ///
    /// Sourced from `nutriments.energy-kcal_100g` in the API response.
    @JsonKey(name: 'energy_kcal') double? energyKcal,

    /// Protein content in **grams per 100 g** (or 100 ml).
    @JsonKey(name: 'protein_g') double? proteinG,

    /// Carbohydrate content in **grams per 100 g** (or 100 ml).
    @JsonKey(name: 'carbs_g') double? carbsG,

    /// Fat content in **grams per 100 g** (or 100 ml).
    @JsonKey(name: 'fat_g') double? fatG,

    /// Fiber content in **grams per 100 g** (or 100 ml).
    @JsonKey(name: 'fiber_g') double? fiberG,

    /// Salt content in **grams per 100 g** (or 100 ml).
    @JsonKey(name: 'salt_g') double? saltG,

    /// Epoch timestamp (milliseconds since Unix epoch) of when the product
    /// data was last fetched from the API or submitted by the user.
    ///
    /// Set automatically in `OpenFoodFactsApi.getByBarcode` and
    /// `OpenFoodFactsApi.submitProduct`.
    @JsonKey(name: 'last_synced') int? lastSynced,

    /// The Nutri-Score grade of the product (`'a'` through `'e'`), or `null`
    /// if the data is unavailable. May also be `'not-applicable'` when the
    /// Nutri-Score system does not apply to this product category (e.g. food
    /// additives).
    ///
    /// Sourced from `nutriscore_grade` in the Open Food Facts v3 API.
    @JsonKey(name: 'nutriscore_grade') String? nutriscoreGrade,

    /// The product category that makes Nutri-Score not applicable, if any.
    ///
    /// This is present only when [nutriscoreGrade] is `'not-applicable'` and
    /// explains why (e.g. `'en:food-additives'`).
    ///
    /// Sourced from `nutriscore_data.nutriscore_not_applicable_for_category`
    /// in the API response. This field is not included in the JSON generated
    /// by `json_serializable` because the value comes from a nested object.
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? nutriscoreNotApplicableCategory,

    /// The origin of this product record.
    ///
    /// - `'api'` — fetched from Open Food Facts (can be safely flushed and
    ///   re‑fetched).
    /// - `'manual'` — entered by the user via the add‑product screen or
    ///   imported from CSV (must never be deleted by a cache flush).
    ///
    /// Defaults to `'api'` because most products come from the OFF
    /// integration. The add‑product screen and CSV import override it to
    /// `'manual'`.
    ///
    /// Not serialised from JSON because the OFF API does not include this
    /// field; it is only stored in the local database.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default('api')
    String source,

    /// Local file path to a photo of the nutrition facts table.
    ///
    /// Populated when the user captures a photo on the manual‑entry screen.
    /// Stored as a stable path inside `<app-documents>/product_images/`.
    /// Not serialised to/from JSON because it is only used locally.
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? nutritionImagePath,

    /// Local file path to a photo of the ingredients list.
    ///
    /// Populated when the user captures a photo on the manual‑entry screen.
    /// Stored as a stable path inside `<app-documents>/product_images/`.
    /// Not serialised to/from JSON because it is only used locally.
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? ingredientsImagePath,

    /// Local file path to a photo of the product packaging / front.
    ///
    /// Populated when the user captures a photo on the manual‑entry screen.
    /// Stored as a stable path inside `<app-documents>/product_images/`.
    /// Not serialised to/from JSON because it is only used locally.
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? productImagePath,

    /// The submission status of this product to Open Food Facts.
    ///
    /// - [productSubmissionNotSubmitted] – not yet submitted (default).
    /// - [productSubmissionPending] – queued for submission.
    /// - [productSubmissionSubmitted] – successfully submitted.
    /// - [productSubmissionFailed] – submission failed; retry possible.
    ///
    /// Not serialised from JSON because the OFF API does not include this
    /// field; it is only stored in the local database.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(productSubmissionNotSubmitted)
    String submissionStatus,
  }) = _Product;

  /// Creates a [Product] from a JSON map in the Open Food Facts v3 format.
  ///
  /// The map is expected to use the API field names (e.g. `_id`,
  /// `product_name`, `energy_kcal`) as configured by the [@JsonKey]
  /// annotations. This factory is generated by `json_serializable` and is
  /// used in `OpenFoodFactsApi._parseProduct`.
  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

/// Extension that provides safe API merge semantics on [Product].
///
/// `mergeFromApi` is defined as an extension rather than a method on the
/// abstract class because freezed generates a concrete implementation
/// (`_Product`) that `implements` (not `extends`) the abstract class.
///
/// ## Merge rules
///
/// - **API non‑null wins** — if the API returned a value, it overwrites
///   the cached value.
/// - **API null preserves cached** — if the API didn't return a field
///   (e.g. the staging server lacks Nutri-Score data), the cached value
///   is kept. This prevents pull-to-refresh from silently wiping data.
/// - **Local-only fields are never touched** — [source],
///   [submissionStatus], [nutritionImagePath], [ingredientsImagePath], and
///   [productImagePath] are preserved exactly as-is because the API doesn't
///   know about them.
/// - **Name sentinel** — if the API returns `'Unknown'` (the default when
///   the real name is missing), the cached name is kept.
///
/// This is the **safe‑update** primitive for pull-to-refresh and post‑flush
/// re‑fetch operations. It guarantees that an incomplete API response can
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
      nutriscoreGrade: nonEmpty(api.nutriscoreGrade) ?? nutriscoreGrade,
      nutriscoreNotApplicableCategory:
          nonEmpty(api.nutriscoreNotApplicableCategory) ??
          nutriscoreNotApplicableCategory,
      lastSynced: api.lastSynced ?? lastSynced,
    );
  }
}
