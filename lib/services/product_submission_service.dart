import 'dart:io';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';
import 'package:pantry_app/utils/logger.dart';

/// Coordinates the submission of a manually entered product to Open Food Facts.
///
/// The flow is:
/// 1. Submit product metadata via the legacy API (`/cgi/product_jqm2.pl`).
/// 2. Upload local photos (nutrition table, ingredients, front) via
///    `/cgi/product_image_upload.pl`.
/// 3. Update the product's `submissionStatus` on success/failure and
///    persist to the local database.
class ProductSubmissionService {
  /// Creates a [ProductSubmissionService].
  ProductSubmissionService({
    required this._db,
    required this._api,
  });

  final DatabaseHelper _db;
  final OpenFoodFactsApi _api;

  /// Submits [product] to Open Food Facts along with any local images.
  ///
  /// Returns the updated [Product] with `submissionStatus` set to
  /// [productSubmissionSubmitted] on success or
  /// [productSubmissionFailed] on failure. The updated product is also
  /// persisted to the local database.
  Future<Product> submitProduct(Product product) async {
    var updated = product.copyWith(
      submissionStatus: productSubmissionPending,
    );
    await _db.insertProduct(updated);

    try {
      final metadataOk = await _api.submitProduct(updated);
      if (!metadataOk) {
        logWarning(
          'Product ${product.barcode}: metadata submission returned false',
        );
        updated = updated.copyWith(
          submissionStatus: productSubmissionFailed,
        );
        await _db.insertProduct(updated);
        return updated;
      }

      var imagesOk = true;
      imagesOk &= await _uploadImageIfPresent(
        updated,
        'front',
        updated.productImagePath,
      );
      imagesOk &= await _uploadImageIfPresent(
        updated,
        'ingredients',
        updated.ingredientsImagePath,
      );
      imagesOk &= await _uploadImageIfPresent(
        updated,
        'nutrition',
        updated.nutritionImagePath,
      );

      updated = updated.copyWith(
        submissionStatus: imagesOk
            ? productSubmissionSubmitted
            : productSubmissionFailed,
      );
      await _db.insertProduct(updated);
      return updated;
    } on Exception catch (e) {
      logError('Submission failed for ${product.barcode}: $e');
      updated = updated.copyWith(
        submissionStatus: productSubmissionFailed,
      );
      await _db.insertProduct(updated);
      return updated;
    }
  }

  Future<bool> _uploadImageIfPresent(
    Product product,
    String imageField,
    String? imagePath,
  ) async {
    if (imagePath == null || imagePath.isEmpty) return true;
    final file = File(imagePath);
    if (!await file.exists()) {
      logWarning(
        'Image not found for $imageField: $imagePath',
      );
      return true;
    }
    try {
      final bytes = await file.readAsBytes();
      return await _api.uploadProductImage(
        barcode: product.barcode,
        imageField: imageField,
        imageBytes: bytes,
      );
    } on Exception catch (e) {
      logError('Error uploading $imageField image: $e');
      return false;
    }
  }
}
