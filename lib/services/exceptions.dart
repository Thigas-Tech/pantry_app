import 'package:dio/dio.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';
import 'package:pantry_app/services/product_repository.dart';

/// Thrown when a product barcode is not found in Open Food Facts.
///
/// This exception is raised by [OpenFoodFactsApi.getByBarcode] when:
/// - The API response status is not `"success"`.
/// - The HTTP status code is 404 (product not found).
/// - The `product` field in the JSON response is `null`.
///
/// ## Handling in the UI
///
/// The [HomeScreen] catches this exception and redirects the user to:
/// - The **Google Play Store** page of the Open Food Facts app (on Android).
/// - The **App Store** page (on iOS).
/// - The **Open Food Facts registration page** (on desktop).
///
/// This encourages the user to install the OFF app and contribute the missing
/// product directly, rather than submitting it through this app.
class ProductNotFoundException implements Exception {
  /// Creates a [ProductNotFoundException] with a human‑readable [message].
  ProductNotFoundException(this.message);

  /// A description of why the product was not found.
  final String message;

  @override
  String toString() => 'ProductNotFoundException: $message';
}

/// Thrown when a product cannot be fetched due to a network error or
/// other transient failure, and no cached copy exists.
///
/// This exception is raised by [ProductRepository.getProduct] when:
/// - The product is not in the local cache.
/// - The API call throws a [DioException] that is **not** a 404.
///
/// ## Handling in the UI
///
/// The [HomeScreen] catches this exception and shows a snackbar with a
/// user‑friendly message. The user can try again when their connection is
/// restored.
class FetchFailedException implements Exception {
  /// Creates a [FetchFailedException] with a human‑readable [message].
  FetchFailedException(this.message);

  /// A description of the failure (e.g. "No connection").
  final String message;

  @override
  String toString() => 'FetchFailedException: $message';
}
