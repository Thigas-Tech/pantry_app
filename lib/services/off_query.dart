import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:pantry_app/utils/logger.dart';

/// Centralized query configuration for Open Food Facts SDK calls.
///
/// Inspired by the smooth-app codebase. Provides pre-configured
/// [ProductQueryConfiguration], [ProductSearchQueryConfiguration], and
/// field lists that limit fetched data to only what we need — reducing
/// payload size and parse time.
class OffQuery {
  OffQuery._();

  /// Fields requested in every product fetch.
  ///
  /// We request only the fields consumed by our [Product] model. This
  /// keeps API responses small and fast.
  static const List<ProductField> productFields = [
    ProductField.BARCODE,
    ProductField.NAME,
    ProductField.BRANDS,
    ProductField.IMAGE_FRONT_URL,
    ProductField.IMAGE_NUTRITION_URL,
    ProductField.IMAGE_INGREDIENTS_URL,
    ProductField.CATEGORIES_TAGS,
    ProductField.CATEGORIES,
    ProductField.INGREDIENTS_TEXT,
    ProductField.SERVING_SIZE,
    // The numeric values power the package-size/serving-size pre-fill in the
    // price sheets; request them explicitly so the API always returns them
    // rather than relying on the server including extra fields.
    ProductField.SERVING_QUANTITY,
    ProductField.PACKAGING_QUANTITY,
    ProductField.NUTRIMENTS,
    ProductField.NUTRISCORE,
    ProductField.QUANTITY,
  ];

  /// Converts a two-letter language code to an [OpenFoodFactsLanguage].
  ///
  /// Returns [OpenFoodFactsLanguage.ENGLISH] for unknown, empty, or null
  /// codes.
  static OpenFoodFactsLanguage codeToLanguage(String? code) {
    if (code == null || code.isEmpty) return OpenFoodFactsLanguage.ENGLISH;
    try {
      return OpenFoodFactsLanguage.fromOffTag(code) ??
          OpenFoodFactsLanguage.ENGLISH;
    } on Object catch (e) {
      logWarning(
        'Unknown OFF language code $code, falling back to English: $e',
      );
      return OpenFoodFactsLanguage.ENGLISH;
    }
  }

  /// Returns a [ProductQueryConfiguration] for fetching a product by barcode
  /// in the given language (two-letter code like 'en', 'fr', 'pt').
  static ProductQueryConfiguration barcodeConfig(
    String barcode, {
    String language = 'en',
  }) {
    return ProductQueryConfiguration(
      barcode,
      language: codeToLanguage(language),
      fields: productFields,
      version: ProductQueryVersion.v3,
    );
  }

  /// Returns a [ProductSearchQueryConfiguration] for searching products
  /// by name or barcode prefix, in the given language.
  static ProductSearchQueryConfiguration searchConfig(
    String query, {
    int pageSize = 20,
    String language = 'en',
  }) {
    return ProductSearchQueryConfiguration(
      parametersList: [
        SearchTerms(terms: [query]),
        PageSize(size: pageSize),
      ],
      language: codeToLanguage(language),
      fields: productFields,
      version: ProductQueryVersion.v3,
    );
  }
}
