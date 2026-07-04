import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';

/// Abstract interface for fetching product data by barcode.
///
/// This allows the app to swap between different API implementations
/// (e.g., Open Food Facts, UPCitemdb, or a mock for testing) without
/// changing the repository or UI code.
///
/// ## Implementations
///
/// - `OpenFoodFactsApi` — the primary implementation used in production.
///   Implementations must throw `ProductNotFoundException` when a barcode
///   is unknown and allow other exceptions to propagate for the caller
///   to handle (e.g., network errors).
abstract class ProductApiService {
  /// Retrieves product information for the given [barcode].
  ///
  /// Must throw [ProductNotFoundException] if the product is not found.
  /// May throw other exceptions for network errors.
  Future<Product> getByBarcode(String barcode);

  /// Optional method that can be used to close any resources held by the
  /// API client (e.g., HTTP connection pools).
  ///
  /// The default implementation does nothing. Implementations may override
  /// this if they need to release resources.
  Future<void> close() async {}
}
