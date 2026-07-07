import 'dart:io';

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
/// ## Read vs write users
///
/// - [getByBarcode] and [searchProducts] use a test user
///   (`smoothie-app/strawberrybanana`), following the convention
///   established by the official smooth-app. OFF does not require
///   authentication for read operations.
/// - [submitProduct] and [uploadProductImage] use the credentials
///   configured in [AppConfig.offUserId] and [AppConfig.offPassword],
///   or return `false` if no credentials are set.
class OffAdapter {
  /// Creates an [OffAdapter].
  ///
  /// If [useStaging] is `true`, API calls target the OFF staging server
  /// (`world.openfoodfacts.net`); otherwise they target production
  /// (`world.openfoodfacts.org`).
  OffAdapter({required this.useStaging});

  /// Whether to use the Open Food Facts staging server.
  final bool useStaging;

  /// The product URI helper for the selected environment.
  off.UriProductHelper get _uriHelper =>
      useStaging ? off.uriHelperFoodTest : off.uriHelperFoodProd;

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
  /// Returns `null` if no OFF credentials are configured in `.env`.
  @visibleForTesting
  off.User? get writeUser {
    final userId = AppConfig.offUserId;
    final password = AppConfig.offPassword;
    if (userId.isEmpty || password.isEmpty) return null;
    return off.User(userId: userId, password: password);
  }

  /// Fetches a product by barcode from Open Food Facts.
  ///
  /// Throws [ProductNotFoundException] if the barcode is unknown.
  /// Throws [FetchFailedException] on network or server errors that
  /// are not "not found" responses.
  Future<Product> getByBarcode(String barcode) async {
    logInfo('Fetching $barcode via SDK');
    try {
      final result = await off.OpenFoodAPIClient.getProductV3(
        OffQuery.barcodeConfig(barcode),
        user: readUser,
        uriHelper: _uriHelper,
      );
      if (result.product == null) {
        logWarning('Product $barcode not found');
        throw ProductNotFoundException(barcode);
      }
      logInfo('Fetched $barcode — ${result.product!.productName}');
      return Product.fromOffProduct(result.product!);
    } on ProductNotFoundException {
      rethrow;
    } on Exception catch (e) {
      logError('SDK error for $barcode: $e');
      throw FetchFailedException(
        'Failed to fetch product. Please check your connection.',
      );
    }
  }

  /// Searches for products matching [query] by name or barcode prefix.
  ///
  /// Returns an empty list on any error after exhausting retries
  /// (graceful degradation). Results are deduplicated by barcode and
  /// products with empty barcodes are filtered out.
  Future<List<Product>> searchProducts(
    String query, {
    int pageSize = 20,
  }) async {
    const maxRetries = 2;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        logInfo('Searching "$query" via SDK (attempt ${attempt + 1})');
        final result = await off.OpenFoodAPIClient.searchProducts(
          readUser,
          OffQuery.searchConfig(query, pageSize: pageSize),
          uriHelper: _uriHelper,
        );
        if (result.products == null) return <Product>[];
        final products = <Product>[];
        final seen = <String>{};
        for (final offProduct in result.products!) {
          final converted = Product.fromOffProduct(offProduct);
          if (converted.barcode.isNotEmpty && seen.add(converted.barcode)) {
            products.add(converted);
          }
        }
        logInfo('Search "$query" returned ${products.length} results');
        return products;
      } on Exception catch (e) {
        if (attempt < maxRetries) {
          final delay = Duration(seconds: attempt + 1);
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
  /// Returns `true` on success, `false` if credentials are missing or
  /// the server rejected the submission.
  Future<bool> submitProduct(Product product) async {
    final user = writeUser;
    if (user == null) {
      logWarning('Cannot submit — no OFF credentials configured');
      return false;
    }
    try {
      logInfo(
        'Submitting product ${product.barcode} to OFF',
      );
      final offProduct = product.toOffProduct();
      final status = await off.OpenFoodAPIClient.saveProduct(
        user,
        offProduct,
        uriHelper: _uriHelper,
      );
      final success = status.status == 1;
      if (success) {
        logInfo('Product ${product.barcode} submitted successfully');
      } else {
        logWarning(
          'Product ${product.barcode} submission returned status '
          '${status.status}: ${status.statusVerbose}',
        );
      }
      return success;
    } on Exception catch (e) {
      logError('Submission failed for ${product.barcode}: $e');
      return false;
    }
  }

  /// Uploads a product image to Open Food Facts.
  ///
  /// [imagePath] must be a valid local file path. Returns `true` on
  /// success, `false` if credentials are missing or the upload fails.
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
    try {
      logInfo(
        'Uploading $imageField image for $barcode',
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
      final status = await off.OpenFoodAPIClient.addProductImage(
        user,
        image,
        uriHelper: _uriHelper,
      );
      final success = status.status == 1;
      if (success) {
        logInfo('$imageField image uploaded for $barcode');
      } else {
        logWarning(
          '$imageField image upload for $barcode returned status '
          '${status.status}: ${status.statusVerbose}',
        );
      }
      return success;
    } on Exception catch (e) {
      logError('Image upload failed for $barcode: $e');
      return false;
    }
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
