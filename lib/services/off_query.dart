import 'package:openfoodfacts/openfoodfacts.dart';

/// Centralized query configuration for Open Food Facts SDK calls.
///
/// Inspired by smooth-app's ProductQuery class. Provides pre-configured
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
    ProductField.NUTRIMENTS,
    ProductField.NUTRISCORE,
    ProductField.QUANTITY,
  ];

  /// Returns a [ProductQueryConfiguration] for fetching a product by barcode.
  static ProductQueryConfiguration barcodeConfig(String barcode) {
    return ProductQueryConfiguration(
      barcode,
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: productFields,
      version: ProductQueryVersion.v3,
    );
  }

  /// Returns a [ProductSearchQueryConfiguration] for searching products
  /// by name or barcode prefix.
  static ProductSearchQueryConfiguration searchConfig(
    String query, {
    int pageSize = 20,
  }) {
    return ProductSearchQueryConfiguration(
      parametersList: [
        SearchTerms(terms: [query]),
        PageSize(size: pageSize),
      ],
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: productFields,
      version: ProductQueryVersion.v3,
    );
  }
}
