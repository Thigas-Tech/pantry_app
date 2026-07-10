import 'dart:io';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/utils/logger.dart';

/// Coordinates the submission of a manually entered product to Open Food Facts.
///
/// The flow is:
/// 1. Submit product metadata via the legacy API (`/cgi/product_jqm2.pl`).
/// 2. Upload local photos (nutrition table, ingredients, front) via
///    `/cgi/product_image_upload.pl`.
/// 3. Update the product's `submissionStatus` on success/failure and
///    persist to the local database.
/// 4. On network failure, queue the barcode in the
///    `product_submission_queue` table for later retry.
///
/// ## Offline queue
///
/// When a submission fails due to a network error (Exception), the barcode
/// is persisted in the `product_submission_queue` table. The queue is
/// processed at startup and whenever connectivity is restored. Each entry
/// uses exponential backoff (2^retry minutes, max 24h) up to 5 retries
/// before being discarded.
class ProductSubmissionService {
  /// Creates a [ProductSubmissionService].
  ProductSubmissionService({
    required this._db,
    required this._api,
  });

  final DatabaseHelper _db;
  final OffAdapter _api;

  /// Submits [product] to Open Food Facts along with any local images.
  ///
  /// Returns the updated [Product] with `submissionStatus` set to
  /// [productSubmissionSubmitted] on success or
  /// [productSubmissionFailed] on failure. On network failure the barcode
  /// is queued for background retry.
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

      // On success, remove any pending queue entries for this barcode.
      if (imagesOk) {
        final database = await _db.database;
        await _db.productSubmissionQueueDao.deleteByBarcode(
          database,
          product.barcode,
        );
      }

      return updated;
    } on Exception catch (e) {
      logError('Submission failed for ${product.barcode}: $e');
      updated = updated.copyWith(
        submissionStatus: productSubmissionFailed,
      );
      await _db.insertProduct(updated);

      // Queue for background retry on network failure.
      await _queueForRetry(product.barcode);

      return updated;
    }
  }

  /// Processes the product submission queue: retries pending submissions
  /// and removes entries that succeed or exhaust retries.
  ///
  /// Returns the number of successfully submitted products.
  Future<int> flushQueue() async {
    logInfo('Flushing product submission queue');
    var submitted = 0;
    try {
      final database = await _db.database;
      final pending = await _db.productSubmissionQueueDao.getPending(database);

      if (pending.isEmpty) {
        logInfo('Product submission queue is empty');
        return 0;
      }

      logInfo('Processing ${pending.length} queued submissions');
      for (final row in pending) {
        final id = row['id'] as int;
        final barcode = row['barcode'] as String;

        // Re-fetch the product from cache.
        final cached = await _db.getProduct(barcode);
        if (cached == null) {
          logWarning(
            'Product $barcode no longer in cache — removing queue entry',
          );
          await _db.productSubmissionQueueDao.delete(database, id);
          continue;
        }

        if (cached.submissionStatus == productSubmissionSubmitted) {
          logInfo('Product $barcode already submitted — removing queue entry');
          await _db.productSubmissionQueueDao.delete(database, id);
          continue;
        }

        // Attempt submission.
        try {
          final result = await submitProduct(cached);
          if (result.submissionStatus == productSubmissionSubmitted) {
            submitted++;
            // submitProduct already deletes the queue entry on success.
          } else {
            await _db.productSubmissionQueueDao.incrementRetry(database, id);
          }
        } on Exception catch (e) {
          logWarning('Queue flush failed for $barcode: $e');
          await _db.productSubmissionQueueDao.incrementRetry(database, id);
        }
      }

      logInfo('Queue flush completed: $submitted submitted');
    } on Exception catch (e) {
      logError('Queue flush failed: $e');
    }
    return submitted;
  }

  /// Queues a barcode for background retry if not already queued.
  Future<void> _queueForRetry(String barcode) async {
    try {
      final database = await _db.database;
      final alreadyQueued = await _db.productSubmissionQueueDao.isQueued(
        database,
        barcode,
      );
      if (!alreadyQueued) {
        await _db.productSubmissionQueueDao.insert(database, barcode);
        logInfo('Product $barcode queued for background retry');
      }
    } on Exception catch (e) {
      logWarning('Failed to queue $barcode for retry: $e');
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
      return await _api.uploadProductImage(
        barcode: product.barcode,
        imageField: imageField,
        imagePath: imagePath,
      );
    } on Exception catch (e) {
      logError('Error uploading $imageField image: $e');
      return false;
    }
  }
}
