import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/config.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/off_query.dart';
import 'package:pantry_app/utils/logger.dart';

/// Injectable wrapper around the official Open Food Facts SDK.
///
/// Wraps [off.OpenFoodAPIClient] static methods so they can be injected
/// via Riverpod and mocked in tests. Handles staging/production
/// URI selection per call (inspired by smooth-app's explicit
/// [off.UriProductHelper] pattern).
///
/// Each SDK static call can be overridden via optional function parameters
/// in the constructor for testing.  When omitted they default to the real
/// [off.OpenFoodAPIClient] methods.
///
/// ## Read vs write users
///
/// - [getByBarcode] and [searchProducts] use a test user
///   (smoothie-app/strawberrybanana), following the convention
///   established by the official smooth-app. OFF does not require
///   authentication for read operations.
/// - [submitProduct] and [uploadProductImage] use the credentials
///   configured in [AppConfig.offUserId] and [AppConfig.offPassword],
///   or return false if no credentials are set.
class OffAdapter {
  /// Creates an [OffAdapter].
  ///
  /// If [useStaging] is true, API calls target the OFF staging server
  /// (world.openfoodfacts.net); otherwise they target production
  /// (world.openfoodfacts.org).
  ///
  /// Each on* parameter overrides the corresponding SDK static call
  /// for testing.  When omitted the real SDK method is used.
  OffAdapter({
    required this.useStaging,
    Future<off.ProductResultV3> Function(
      off.ProductQueryConfiguration, {
      off.User? user,
      off.UriProductHelper uriHelper,
    })?
    onGetProductV3,
    Future<off.SearchResult> Function(
      off.User,
      off.ProductSearchQueryConfiguration, {
      off.UriProductHelper uriHelper,
    })?
    onSearchProducts,
    Future<off.Status> Function(
      off.User,
      off.Product, {
      off.UriProductHelper uriHelper,
    })?
    onSaveProduct,
    Future<off.Status> Function(
      off.User,
      off.SendImage, {
      off.UriProductHelper uriHelper,
    })?
    onAddProductImage,
  }) : _onGetProductV3 = onGetProductV3 ?? off.OpenFoodAPIClient.getProductV3,
       _onSearchProducts =
           onSearchProducts ?? off.OpenFoodAPIClient.searchProducts,
       _onSaveProduct = onSaveProduct ?? off.OpenFoodAPIClient.saveProduct,
       _onAddProductImage =
           onAddProductImage ?? off.OpenFoodAPIClient.addProductImage;

  /// Whether to use the Open Food Facts staging server.
  final bool useStaging;

  // SDK call overrides — defaults to real SDK static methods.
  final Future<off.ProductResultV3> Function(
    off.ProductQueryConfiguration, {
    off.User? user,
    off.UriProductHelper uriHelper,
  })
  _onGetProductV3;

  final Future<off.SearchResult> Function(
    off.User,
    off.ProductSearchQueryConfiguration, {
    off.UriProductHelper uriHelper,
  })
  _onSearchProducts;

  final Future<off.Status> Function(
    off.User,
    off.Product, {
    off.UriProductHelper uriHelper,
  })
  _onSaveProduct;

  final Future<off.Status> Function(
    off.User,
    off.SendImage, {
    off.UriProductHelper uriHelper,
  })
  _onAddProductImage;

  /// The product URI helper for the selected environment.
  off.UriProductHelper get _uriHelper =>
      useStaging ? off.uriHelperFoodTest : off.uriHelperFoodProd;

  /// Returns `true` when [error] indicates HTTP 429 rate limiting.
  ///
  /// The OFF SDK wraps 429 responses as generic exceptions with the
  /// HTTP error page in the message body.
  @visibleForTesting
  static bool isRateLimitError(Object error) {
    final msg = error.toString();
    return msg.contains('429 Too Many Requests');
  }

  /// Returns a retry delay with linear backoff and ±25% jitter.
  ///
  /// [attempt] is zero-based (0 = first retry).  The base delay is
  /// `(attempt + 1)` seconds.  When [isRateLimit] is `true`, the base
  /// delay is multiplied by 5 to be more respectful of the server's
  /// capacity.  The result is clamped to >= 500 ms.
  @visibleForTesting
  static Duration retryDelay(
    int attempt, {
    Random? random,
    bool isRateLimit = false,
  }) {
    const baseMs = 1000;
    final multiplier = isRateLimit ? 5 : 1;
    final base = (attempt + 1) * baseMs * multiplier;
    final rng = random ?? Random();
    // ±25% jitter
    final jitter = ((rng.nextDouble() - 0.5) * 0.5 * base).round();
    return Duration(milliseconds: (base + jitter).clamp(500, base * 2));
  }

  /// The test user used for unauthenticated read operations.
  ///
  /// This follows smooth-app's convention — OFF does not require auth
  /// for product lookups or searches.
  @visibleForTesting
  static const off.User readUser = off.User(
    userId: 'smoothie-app',
    password: 'strawberrybanana',
  );

  /// The authenticated user for write operations (submission, upload).
  ///
  /// Returns null if no OFF credentials are configured in .env.
  @visibleForTesting
  off.User? get writeUser {
    final userId = AppConfig.offUserId;
    final password = AppConfig.offPassword;
    if (userId.isEmpty || password.isEmpty) return null;
    return off.User(userId: userId, password: password);
  }

  /// Fetches a product by barcode from Open Food Facts.
  ///
  /// [languageCode] is a two-letter code (e.g. 'en', 'fr', 'pt')
  /// that requests product data in the user's preferred language.
  ///
  /// Retries up to [maxRetries] times on transient failures (network
  /// errors, server errors, rate limiting) with linear backoff.  Does
  /// NOT retry on [ProductNotFoundException] — unknown barcodes fail
  /// fast.
  ///
  /// Throws [ProductNotFoundException] if the barcode is unknown.
  /// Throws [FetchFailedException] on network or server errors that
  /// are not "not found" responses.
  Future<Product> getByBarcode(
    String barcode, {
    String languageCode = 'en',
    int maxRetries = 2,
  }) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        logInfo('Fetching $barcode via SDK (attempt ${attempt + 1})');
        final result = await _onGetProductV3(
          OffQuery.barcodeConfig(barcode, language: languageCode),
          user: readUser,
          uriHelper: _uriHelper,
        );
        if (result.product == null) {
          logWarning('Product $barcode not found');
          throw ProductNotFoundException(barcode);
        }
        logInfo('Fetched $barcode — ${result.product!.productName}');
        return Product.fromOffProduct(
          result.product!,
          languageCode: languageCode,
        );
      } on ProductNotFoundException {
        rethrow;
      } on Exception catch (e) {
        if (attempt < maxRetries) {
          final isRateLimit = isRateLimitError(e);
          final delay = retryDelay(attempt, isRateLimit: isRateLimit);
          logWarning(
            'Fetch $barcode failed (attempt ${attempt + 1}), '
            'retrying in ${delay.inSeconds}s: $e',
          );
          await Future<void>.delayed(delay);
        } else {
          logError('Fetch $barcode failed after all retries: $e');
          throw FetchFailedException(
            'Failed to fetch product. Please check your connection.',
          );
        }
      }
    }
    // Unreachable — either returns or throws above.
    throw FetchFailedException(
      'Failed to fetch product. Please check your connection.',
    );
  }

  /// Searches for products matching [query] by name or barcode prefix.
  ///
  /// [languageCode] requests product data in the user's preferred language.
  ///
  /// Returns an empty list on any error after exhausting retries
  /// (graceful degradation). Results are deduplicated by barcode and
  /// products with empty barcodes are filtered out.
  Future<List<Product>> searchProducts(
    String query, {
    int pageSize = 20,
    String languageCode = 'en',
  }) async {
    const maxRetries = 2;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        logInfo('Searching "$query" via SDK (attempt ${attempt + 1})');
        final result = await _onSearchProducts(
          readUser,
          OffQuery.searchConfig(
            query,
            pageSize: pageSize,
            language: languageCode,
          ),
          uriHelper: _uriHelper,
        );
        if (result.products == null) return <Product>[];
        final products = <Product>[];
        final seen = <String>{};
        for (final offProduct in result.products!) {
          final converted = Product.fromOffProduct(
            offProduct,
            languageCode: languageCode,
          );
          if (converted.barcode.isNotEmpty && seen.add(converted.barcode)) {
            products.add(converted);
          }
        }
        logInfo('Search "$query" returned ${products.length} results');
        return products;
      } on Exception catch (e) {
        if (attempt < maxRetries) {
          final isRateLimit = isRateLimitError(e);
          final delay = retryDelay(attempt, isRateLimit: isRateLimit);
          logWarning(
            'Search "$query" failed (attempt ${attempt + 1}), '
            'retrying in ${delay.inSeconds}s: $e',
          );
          await Future<void>.delayed(delay);
        } else {
          logWarning('Search "$query" failed after all retries: $e');
          return <Product>[];
        }
      }
    }
    return <Product>[];
  }

  /// Submits a product to Open Food Facts.
  ///
  /// Returns true on success, false if credentials are missing or
  /// the server rejected the submission.
  Future<bool> submitProduct(Product product) async {
    final user = writeUser;
    if (user == null) {
      logWarning('Cannot submit — no OFF credentials configured');
      return false;
    }
    const maxRetries = 2;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        logInfo(
          'Submitting product ${product.barcode} to OFF '
          '(attempt ${attempt + 1})',
        );
        final offProduct = product.toOffProduct();
        final status = await _onSaveProduct(
          user,
          offProduct,
          uriHelper: _uriHelper,
        );
        final success = status.status == 1;
        if (success) {
          logInfo('Product ${product.barcode} submitted successfully');
          return true;
        }
        logWarning(
          'Product ${product.barcode} submission returned status '
          '${status.status}: ${status.statusVerbose}',
        );
        return false;
      } on Exception catch (e) {
        if (attempt < maxRetries) {
          final isRateLimit = isRateLimitError(e);
          final delay = retryDelay(attempt, isRateLimit: isRateLimit);
          logWarning(
            'Submission failed for ${product.barcode} '
            '(attempt ${attempt + 1}), retrying in ${delay.inSeconds}s: $e',
          );
          await Future<void>.delayed(delay);
        } else {
          logError(
            'Submission failed for ${product.barcode} after '
            'all retries: $e',
          );
          return false;
        }
      }
    }
    return false;
  }

  /// Uploads a product image to Open Food Facts.
  ///
  /// [imagePath] must be a valid local file path. Returns true on
  /// success, false if credentials are missing or the upload fails.
  Future<bool> uploadProductImage({
    required String barcode,
    required String imageField,
    required String imagePath,
    String? languageCode,
  }) async {
    final user = writeUser;
    if (user == null) {
      logWarning('Cannot upload image — no OFF credentials configured');
      return false;
    }
    final file = File(imagePath);
    if (!await file.exists()) {
      logWarning('Image file not found: $imagePath');
      return false;
    }
    const maxRetries = 2;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        logInfo(
          'Uploading $imageField image for $barcode '
          '(attempt ${attempt + 1})',
        );
        final lang = languageCode != null
            ? off.OpenFoodFactsLanguage.fromOffTag(languageCode)
            : off.OpenFoodFactsLanguage.ENGLISH;
        final image = off.SendImage(
          lang: lang == off.OpenFoodFactsLanguage.UNDEFINED
              ? off.OpenFoodFactsLanguage.ENGLISH
              : lang,
          barcode: barcode,
          imageField: parseImageField(imageField),
          imageUri: Uri.parse(imagePath),
        );
        final status = await _onAddProductImage(
          user,
          image,
          uriHelper: _uriHelper,
        );
        final success = status.status == 1;
        if (success) {
          logInfo('$imageField image uploaded for $barcode');
          return true;
        }
        logWarning(
          '$imageField image upload for $barcode returned status '
          '${status.status}: ${status.statusVerbose}',
        );
        return false;
      } on Exception catch (e) {
        if (attempt < maxRetries) {
          final isRateLimit = isRateLimitError(e);
          final delay = retryDelay(attempt, isRateLimit: isRateLimit);
          logWarning(
            '$imageField image upload failed for $barcode '
            '(attempt ${attempt + 1}), retrying in ${delay.inSeconds}s: $e',
          );
          await Future<void>.delayed(delay);
        } else {
          logError(
            'Image upload failed for $barcode after '
            'all retries: $e',
          );
          return false;
        }
      }
    }
    return false;
  }

  /// Parses an image field string into the SDK's [off.ImageField] enum.
  @visibleForTesting
  static off.ImageField parseImageField(String field) {
    switch (field) {
      case 'front':
        return off.ImageField.FRONT;
      case 'ingredients':
        return off.ImageField.INGREDIENTS;
      case 'nutrition':
        return off.ImageField.NUTRITION;
      default:
        logWarning('Unknown image field "$field", falling back to FRONT');
        return off.ImageField.FRONT;
    }
  }
}
