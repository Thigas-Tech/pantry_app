import 'package:pantry_app/models/product.dart';

/// Abstract interface for fetching product data by barcode.
///
/// This allows the app to swap between different API implementations
/// (e.g., Open Food Facts, UPCitemdb, or a mock for testing) without
/// changing the repository or UI code.
///
/// ## Implementations
///
/// - [OpenFoodFactsApi] — the primary implementation used in production.
/// - (Removed) `UpcItemDbApi` — previously used as a fallback; removed to
///   simplify the app and focus on contributing to Open Food Facts.
abstract class ProductApiService {
  /// Retrieves product information for the given [barcode].
  ///
  /// Must throw [ProductNotFoundException] if the product is not found.
  /// May throw other exceptions for network errors.
  Future<Product> getByBarcode(String barcode);
}
