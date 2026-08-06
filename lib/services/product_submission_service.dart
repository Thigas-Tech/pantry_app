import 'dart:async';
import 'dart:io';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_submission_state.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/utils/logger.dart';

/// Coordinates the submission of a manually entered product to Open Food Facts.
///
/// The flow is:
/// 1. Submit product metadata via the legacy API (/cgi/product_jqm2.pl).
/// 2. Upload local photos (nutrition table, ingredients, front) via
///    /cgi/product_image_upload.pl.
/// 3. Update the product's submission status on success/failure and
///    persist to the local database.
/// 4. On transient network failure, queue the barcode in the
///    product_submission_queue table for later retry.
///
/// ## Progress
///
/// Callers may pass a progress callback that receives a
/// [ProductSubmissionState] at every transition so the UI can render
/// per-step progress (metadata, image N of M, terminal result) even after
/// navigating away from the add-product screen.
///
/// ## Failure semantics
///
/// - Metadata rejection (server returns a non-ok status) is a permanent
///   failure: the product is marked [productSubmissionFailed] and is never
///   queued for automatic retry.
/// - A network, rate-limit, or timeout exception is transient: the product is
///   marked failed and its barcode is queued for background retry.
/// - When metadata succeeds but at least one image upload fails, the product
///   is marked [productSubmissionPartiallyCompleted]. Transient image failures
///   still queue the barcode so the remaining uploads can complete later.
/// - One submission per barcode at a time: a concurrent [submitProduct] call
///   for the same barcode throws [SubmissionAlreadyInProgressException].
///
/// ## Offline queue
///
/// When a submission fails due to a network error (Exception), the barcode
/// is persisted in the product_submission_queue table. The queue is
/// processed at startup and whenever connectivity is restored. Each entry
/// uses exponential backoff (2^retry minutes, max 24h) up to 5 retries
/// before being discarded.
class ProductSubmissionService {
  /// Creates a [ProductSubmissionService].
  ///
  /// [imageUploadTimeout] bounds how long a single image upload may take
  /// before it is treated as failed; it is injectable so tests never wait
  /// for the real 60-second window.
  ProductSubmissionService({
    required this.db,
    required this.api,
    this.imageUploadTimeout = const Duration(seconds: 60),
  });

  /// The database helper used to persist products and queue entries.
  final DatabaseHelper db;

  /// The Open Food Facts adapter used for metadata and image uploads.
  final OffAdapter api;

  /// Maximum time a single image upload may run before it times out.
  final Duration imageUploadTimeout;

  /// Barcodes with a submission currently running, preventing duplicate
  /// concurrent submissions for the same product.
  final Set<String> _inFlight = <String>{};

  /// Submits [product] to Open Food Facts along with any local images.
  ///
  /// Returns the updated [Product] with the final submission status. While
  /// running, [onProgress] is called with each [ProductSubmissionState]
  /// transition. Throws [SubmissionAlreadyInProgressException] when a
  /// submission for the same barcode is already running.
  Future<Product> submitProduct(
    Product product, {
    void Function(ProductSubmissionState progress)? onProgress,
  }) async {
    if (_inFlight.contains(product.barcode)) {
      logWarning('Submission already in progress for ${product.barcode}');
      throw SubmissionAlreadyInProgressException(product.barcode);
    }
    _inFlight.add(product.barcode);
    try {
      return await _runSubmission(product, onProgress);
    } finally {
      _inFlight.remove(product.barcode);
    }
  }

  /// Runs the metadata and image-upload steps for [product], reporting each
  /// transition through [onProgress] and returning the final [Product].
  Future<Product> _runSubmission(
    Product product,
    void Function(ProductSubmissionState progress)? onProgress,
  ) async {
    var updated = product.copyWith(
      submissionStatus: productSubmissionPending,
    );
    onProgress?.call(
      ProductSubmissionState(
        barcode: product.barcode,
        step: SubmissionStep.submittingMetadata,
      ),
    );
    await db.insertProduct(updated);

    try {
      final metadataOk = await api.submitProduct(updated);
      if (!metadataOk) {
        logWarning(
          'Product ${product.barcode}: metadata submission returned false',
        );
        updated = updated.copyWith(
          submissionStatus: productSubmissionFailed,
        );
        await db.insertProduct(updated);
        onProgress?.call(
          ProductSubmissionState(
            barcode: product.barcode,
            step: SubmissionStep.failed,
            errorCategory: SubmissionErrorCategory.validation,
          ),
        );
        return updated;
      }

      final images =
          [
                ('front', updated.productImagePath),
                ('ingredients', updated.ingredientsImagePath),
                ('nutrition', updated.nutritionImagePath),
              ]
              .where((entry) => entry.$2 != null && entry.$2!.isNotEmpty)
              .map((entry) => (entry.$1, entry.$2!))
              .toList();
      final totalImages = images.length;

      var imagesOk = true;
      var transientImageFailure = false;
      for (var i = 0; i < images.length; i++) {
        final (field, path) = images[i];
        onProgress?.call(
          ProductSubmissionState(
            barcode: product.barcode,
            step: SubmissionStep.uploadingImage,
            currentImageIndex: i + 1,
            totalImages: totalImages,
          ),
        );
        try {
          final ok = await _uploadImageIfPresent(updated, field, path);
          if (!ok) imagesOk = false;
        } on Exception catch (e) {
          logError('Error uploading $field image for ${product.barcode}: $e');
          imagesOk = false;
          if (_isTransient(_categorize(e))) transientImageFailure = true;
        }
      }

      updated = updated.copyWith(
        submissionStatus: imagesOk
            ? productSubmissionSubmitted
            : productSubmissionPartiallyCompleted,
      );
      await db.insertProduct(updated);

      final database = await db.database;
      if (imagesOk) {
        await db.productSubmissionQueueDao.deleteByBarcode(
          database,
          product.barcode,
        );
      } else if (transientImageFailure) {
        await _queueForRetry(product.barcode);
      }

      onProgress?.call(
        ProductSubmissionState(
          barcode: product.barcode,
          step: imagesOk
              ? SubmissionStep.completed
              : SubmissionStep.partiallyCompleted,
        ),
      );
      return updated;
    } on Exception catch (e) {
      final category = _categorize(e);
      logError('Submission failed for ${product.barcode}: $e');
      updated = updated.copyWith(
        submissionStatus: productSubmissionFailed,
      );
      await db.insertProduct(updated);

      // Queue for background retry on transient (network-like) failures.
      if (_isTransient(category)) {
        await _queueForRetry(product.barcode);
      }

      onProgress?.call(
        ProductSubmissionState(
          barcode: product.barcode,
          step: SubmissionStep.failed,
          errorCategory: category,
        ),
      );
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
      final database = await db.database;
      final pending = await db.productSubmissionQueueDao.getPending(database);

      if (pending.isEmpty) {
        logInfo('Product submission queue is empty');
        return 0;
      }

      logInfo('Processing ${pending.length} queued submissions');
      for (final row in pending) {
        final id = row['id'] as int;
        final barcode = row['barcode'] as String;

        // Re-fetch the product from cache.
        final cached = await db.getProduct(barcode);
        if (cached == null) {
          logWarning(
            'Product $barcode no longer in cache — removing queue entry',
          );
          await db.productSubmissionQueueDao.delete(database, id);
          continue;
        }

        if (cached.submissionStatus == productSubmissionSubmitted) {
          logInfo('Product $barcode already submitted — removing queue entry');
          await db.productSubmissionQueueDao.delete(database, id);
          continue;
        }

        // Attempt submission.
        try {
          final result = await submitProduct(cached);
          if (result.submissionStatus == productSubmissionSubmitted) {
            submitted++;
            // submitProduct already deletes the queue entry on success.
          } else {
            await db.productSubmissionQueueDao.incrementRetry(database, id);
          }
        } on SubmissionAlreadyInProgressException catch (e) {
          // The running submission resolves the entry itself; do not burn a
          // retry by incrementing the counter here.
          logWarning(
            'Queue flush skipped $barcode — $e',
          );
        } on Exception catch (e) {
          logWarning('Queue flush failed for $barcode: $e');
          await db.productSubmissionQueueDao.incrementRetry(database, id);
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
      final database = await db.database;
      final alreadyQueued = await db.productSubmissionQueueDao.isQueued(
        database,
        barcode,
      );
      if (!alreadyQueued) {
        await db.productSubmissionQueueDao.insert(database, barcode);
        logInfo('Product $barcode queued for background retry');
      }
    } on Exception catch (e) {
      logWarning('Failed to queue $barcode for retry: $e');
    }
  }

  /// Uploads the image at [imagePath] for [imageField] when present.
  ///
  /// Returns true when the slot is empty, the file is missing on disk, or
  /// the upload succeeded. A server rejection returns false. Exceptions
  /// (including [imageUploadTimeout] expiry) propagate to the caller.
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
    return api
        .uploadProductImage(
          barcode: product.barcode,
          imageField: imageField,
          imagePath: imagePath,
        )
        .timeout(imageUploadTimeout);
  }

  /// Maps [error] to a [SubmissionErrorCategory].
  static SubmissionErrorCategory _categorize(Object error) {
    if (error is TimeoutException) return SubmissionErrorCategory.timeout;
    if (OffAdapter.isRateLimitError(error)) {
      return SubmissionErrorCategory.rateLimit;
    }
    return SubmissionErrorCategory.network;
  }

  /// Returns true when [category] is transient and worth queueing for retry.
  static bool _isTransient(SubmissionErrorCategory category) {
    return switch (category) {
      SubmissionErrorCategory.network ||
      SubmissionErrorCategory.rateLimit ||
      SubmissionErrorCategory.timeout => true,
      _ => false,
    };
  }
}
