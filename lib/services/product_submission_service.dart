import 'dart:io';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/product_image_compressor.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/redaction.dart';

/// Coordinates the submission of a manually entered product to Open Food Facts.
///
/// The flow is:
/// 1. Submit product metadata via the legacy API (/cgi/product_jqm2.pl).
/// 2. Upload local photos (nutrition table, ingredients, front) via
///    /cgi/product_image_upload.pl.
/// 3. Update the product's submission status on success/failure and
///    persist to the local database.
/// 4. On transient failure, queue the barcode in the
///    product_submission_queue table for later retry.
///
/// Progress is reported through [submitProduct]'s progress callback as
/// typed [SubmissionProgress] snapshots, so callers can expose observable,
/// durable progress that outlives the originating screen.
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
  ProductSubmissionService({
    required this._db,
    required this._api,
    ProductImageCompressor? imageCompressor,
  }) : _imageCompressor = imageCompressor ?? ProductImageCompressor();

  final DatabaseHelper _db;
  final OffAdapter _api;
  final ProductImageCompressor _imageCompressor;

  /// Submits [product] to Open Food Facts along with any local images.
  ///
  /// Progress snapshots are delivered to [onProgress] when provided.
  /// Returns the updated [Product] with submission status set to
  /// [productSubmissionSubmitted] on success, [productSubmissionFailed]
  /// on failure, or [productSubmissionPartiallyCompleted] when the
  /// metadata and some photos succeeded but at least one photo failed.
  /// On transient failure the barcode is queued for background retry.
  Future<Product> submitProduct(
    Product product, {
    void Function(SubmissionProgress progress)? onProgress,
  }) async {
    final totalImages = _countImages(product);
    var updated = product.copyWith(
      submissionStatus: productSubmissionPending,
    );
    await _db.insertProduct(updated);
    _emit(
      onProgress,
      SubmissionProgress(
        barcode: product.barcode,
        totalImageCount: totalImages,
      ),
    );

    try {
      _emit(
        onProgress,
        SubmissionProgress(
          barcode: product.barcode,
          step: SubmissionStep.submittingMetadata,
          totalImageCount: totalImages,
        ),
      );

      // A fresh manual entry must not silently overwrite a barcode that
      // already exists on Open Food Facts. Retries skip the check so a
      // partially completed submission (whose metadata already reached the
      // server) can still recover.
      if (product.submissionStatus == productSubmissionNotSubmitted) {
        final duplicate = await _isDuplicate(product);
        if (duplicate) {
          logWarning(
            'Product ${product.barcode}: barcode already exists on OFF',
          );
          return await _finishFailed(
            product,
            onProgress,
            SubmissionErrorCategory.duplicate,
            false,
            totalImages,
          );
        }
      }

      // Best-effort credential pre-flight. A definitive rejection is a
      // permanent configuration error: fail fast and do not retry. An
      // inconclusive check (network) must never block a legitimate
      // submission, mirroring the duplicate pre-check.
      final credentialCheck = await _api.validateCredentials();
      if (credentialCheck == OffWriteError.wrongCredentials) {
        logWarning(
          'Product ${product.barcode}: OFF credentials rejected, aborting',
        );
        return await _finishFailed(
          product,
          onProgress,
          SubmissionErrorCategory.wrongCredentials,
          false,
          totalImages,
        );
      }
      if (credentialCheck == OffWriteError.network) {
        logWarning(
          'Product ${product.barcode}: credential validation inconclusive, '
          'proceeding with submission',
        );
      }

      final metadataResult = await _api.submitProduct(updated);
      if (!metadataResult.success) {
        logWarning(
          'Product ${product.barcode}: metadata submission failed',
        );
        return await _finishFailed(
          product,
          onProgress,
          _categorize(metadataResult.error),
          _retryFor(metadataResult.error),
          totalImages,
        );
      }

      var completedImages = 0;
      final failures = <OffWriteResult>[];
      final uploads = <(String, String?, SubmissionStep)>[
        ('front', updated.productImagePath, SubmissionStep.uploadingFront),
        (
          'ingredients',
          updated.ingredientsImagePath,
          SubmissionStep.uploadingIngredients,
        ),
        (
          'nutrition',
          updated.nutritionImagePath,
          SubmissionStep.uploadingNutrition,
        ),
      ];

      // On a retry the metadata may already be on the server and some image
      // fields may have been uploaded successfully before the interruption.
      // Detect those so they are not uploaded again. Fresh submissions skip
      // this read because the duplicate check already proved the barcode is
      // unknown.
      final serverImages =
          product.submissionStatus == productSubmissionNotSubmitted
          ? <String>{}
          : await _existingServerImages(product);

      for (final (imageField, imagePath, step) in uploads) {
        if (serverImages.contains(imageField)) {
          completedImages++;
          continue;
        }
        final result = await _uploadImageIfPresent(
          product: updated,
          imageField: imageField,
          imagePath: imagePath,
          step: step,
          completedImages: completedImages,
          totalImages: totalImages,
          onProgress: onProgress,
        );
        if (result.success) {
          completedImages++;
        } else {
          failures.add(result);
        }
      }

      if (failures.isEmpty) {
        updated = updated.copyWith(
          submissionStatus: productSubmissionSubmitted,
        );
        await _db.insertProduct(updated);
        _emit(
          onProgress,
          SubmissionProgress(
            barcode: product.barcode,
            step: SubmissionStep.completed,
            completedImageCount: completedImages,
            totalImageCount: totalImages,
          ),
        );
        final database = await _db.database;
        await _db.productSubmissionQueueDao.deleteByBarcode(
          database,
          product.barcode,
        );
        return updated;
      }

      if (completedImages > 0) {
        updated = updated.copyWith(
          submissionStatus: productSubmissionPartiallyCompleted,
        );
        await _db.insertProduct(updated);
        _emit(
          onProgress,
          SubmissionProgress(
            barcode: product.barcode,
            step: SubmissionStep.partiallyCompleted,
            completedImageCount: completedImages,
            totalImageCount: totalImages,
            errorCategory: _categorize(failures.first.error),
            retryAvailable: true,
          ),
        );
        await _queueForRetry(product.barcode);
        return updated;
      }

      return await _finishFailed(
        product,
        onProgress,
        _categorize(failures.first.error),
        _retryFor(failures.first.error),
        totalImages,
      );
    } on Exception catch (e) {
      logError(
        'Submission failed for ${product.barcode}: ${redactSensitive('$e')}',
      );
      return _finishFailed(
        product,
        onProgress,
        SubmissionErrorCategory.network,
        true,
        totalImages,
      );
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
          logWarning(
            'Queue flush failed for $barcode: ${redactSensitive('$e')}',
          );
          await _db.productSubmissionQueueDao.incrementRetry(database, id);
        }
      }

      logInfo('Queue flush completed: $submitted submitted');
    } on Exception catch (e) {
      logError('Queue flush failed: ${redactSensitive('$e')}');
    }
    return submitted;
  }

  /// Returns true when [product]'s barcode already exists on Open Food Facts.
  ///
  /// The check is best-effort: any failure to reach Open Food Facts is
  /// treated as "not a duplicate" so a flaky check never blocks a legitimate
  /// submission. Uses no retries so the check fails fast.
  Future<bool> _isDuplicate(Product product) async {
    try {
      await _api.getByBarcode(
        product.barcode,
        languageCode: product.languageCode,
        maxRetries: 0,
      );
      return true;
    } on ProductNotFoundException {
      return false;
    } on Exception catch (e) {
      logWarning(
        'Duplicate check for ${product.barcode} failed: '
        '${redactSensitive('$e')}',
      );
      return false;
    }
  }

  /// Returns the set of image fields that already have an image on Open Food
  /// Facts for [product]'s barcode.
  ///
  /// Best-effort: any failure to reach Open Food Facts returns an empty set
  /// so a retry conservatively uploads every local image. Uses no retries so
  /// the check fails fast.
  Future<Set<String>> _existingServerImages(Product product) async {
    final present = <String>{};
    try {
      final serverProduct = await _api.getByBarcode(
        product.barcode,
        languageCode: product.languageCode,
        maxRetries: 0,
      );
      if ((serverProduct.offProductImageUrl ?? '').isNotEmpty) {
        present.add('front');
      }
      if ((serverProduct.offIngredientsImageUrl ?? '').isNotEmpty) {
        present.add('ingredients');
      }
      if ((serverProduct.offNutritionImageUrl ?? '').isNotEmpty) {
        present.add('nutrition');
      }
    } on Exception catch (e) {
      logWarning(
        'Could not fetch server images for ${product.barcode}: '
        '${redactSensitive('$e')}',
      );
    }
    return present;
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
      logWarning(
        'Failed to queue $barcode for retry: ${redactSensitive('$e')}',
      );
    }
  }

  /// Persists the failed status, emits the failed snapshot, and queues the
  /// barcode for background retry when [retryAvailable] is true.
  Future<Product> _finishFailed(
    Product product,
    void Function(SubmissionProgress progress)? onProgress,
    SubmissionErrorCategory errorCategory,
    bool retryAvailable,
    int totalImages,
  ) async {
    final updated = product.copyWith(
      submissionStatus: productSubmissionFailed,
    );
    await _db.insertProduct(updated);
    _emit(
      onProgress,
      SubmissionProgress(
        barcode: product.barcode,
        step: SubmissionStep.failed,
        totalImageCount: totalImages,
        errorCategory: errorCategory,
        retryAvailable: retryAvailable,
      ),
    );
    if (retryAvailable) {
      await _queueForRetry(product.barcode);
    }
    return updated;
  }

  /// Uploads [imagePath] for [imageField] when a local file exists.
  ///
  /// Missing or empty paths count as success and skip the upload. A
  /// [SubmissionProgress] snapshot for [step] is emitted before the
  /// network call so the UI can show the in-flight image.
  Future<OffWriteResult> _uploadImageIfPresent({
    required Product product,
    required String imageField,
    required String? imagePath,
    required SubmissionStep step,
    required int completedImages,
    required int totalImages,
    required void Function(SubmissionProgress progress)? onProgress,
  }) async {
    if (imagePath == null || imagePath.isEmpty) {
      return const OffWriteResult.success();
    }
    final file = File(imagePath);
    if (!await file.exists()) {
      logWarning('Image not found for $imageField');
      return const OffWriteResult.success();
    }
    _emit(
      onProgress,
      SubmissionProgress(
        barcode: product.barcode,
        step: step,
        completedImageCount: completedImages,
        totalImageCount: totalImages,
      ),
    );
    File? compressed;
    try {
      var uploadPath = imagePath;
      final compressedPath = await _imageCompressor.compress(
        sourcePath: imagePath,
      );
      if (compressedPath != null) {
        compressed = File(compressedPath);
        uploadPath = compressedPath;
      }
      return await _api.uploadProductImage(
        barcode: product.barcode,
        imageField: imageField,
        imagePath: uploadPath,
        languageCode: product.languageCode,
      );
    } on Exception catch (e) {
      logError('Error uploading $imageField image: ${redactSensitive('$e')}');
      return const OffWriteResult.failure(OffWriteError.network);
    } finally {
      if (compressed != null) {
        try {
          await compressed.delete();
        } on Exception catch (e) {
          logWarning(
            'Failed to delete compressed temp image: ${redactSensitive('$e')}',
          );
        }
      }
    }
  }

  /// Delivers [progress] to [onProgress] when one was provided.
  void _emit(
    void Function(SubmissionProgress progress)? onProgress,
    SubmissionProgress progress,
  ) {
    onProgress?.call(progress);
  }

  /// Counts how many image fields have a local file path.
  int _countImages(Product product) {
    var count = 0;
    if (_hasImage(product.productImagePath)) count++;
    if (_hasImage(product.ingredientsImagePath)) count++;
    if (_hasImage(product.nutritionImagePath)) count++;
    return count;
  }

  /// Whether [path] names a local image file.
  bool _hasImage(String? path) => path != null && path.isNotEmpty;

  /// Maps an [OffWriteError] to its [SubmissionErrorCategory].
  SubmissionErrorCategory _categorize(OffWriteError error) {
    return switch (error) {
      OffWriteError.none => SubmissionErrorCategory.none,
      OffWriteError.missingCredentials =>
        SubmissionErrorCategory.missingCredentials,
      OffWriteError.network => SubmissionErrorCategory.network,
      OffWriteError.rateLimited => SubmissionErrorCategory.rateLimited,
      OffWriteError.validation => SubmissionErrorCategory.validation,
      OffWriteError.wrongCredentials =>
        SubmissionErrorCategory.wrongCredentials,
      OffWriteError.serverRejected => SubmissionErrorCategory.serverRejected,
      OffWriteError.unknown => SubmissionErrorCategory.unknown,
    };
  }

  /// Whether retrying a write that failed with [error] can succeed.
  bool _retryFor(OffWriteError error) {
    return switch (error) {
      OffWriteError.missingCredentials ||
      OffWriteError.serverRejected ||
      OffWriteError.validation ||
      OffWriteError.wrongCredentials ||
      OffWriteError.none => false,
      OffWriteError.network ||
      OffWriteError.rateLimited ||
      OffWriteError.unknown => true,
    };
  }
}
