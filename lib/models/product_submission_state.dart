import 'package:flutter/foundation.dart';

/// The lifecycle step a product submission is currently in.
enum SubmissionStep {
  /// About to begin the submission.
  checking,

  /// Uploading the product metadata to Open Food Facts.
  submittingMetadata,

  /// Uploading a product image. [ProductSubmissionState.currentImageIndex]
  /// and [ProductSubmissionState.totalImages] describe the progress.
  uploadingImage,

  /// The submission finished successfully.
  completed,

  /// Metadata was accepted but at least one image upload failed.
  partiallyCompleted,

  /// The submission failed and can be retried.
  failed,

  /// The user requested a retry of a previously failed submission.
  retrying,
}

/// Classifies why a submission failed so that permanent failures are not
/// queued for automatic retry.
enum SubmissionErrorCategory {
  /// No failure; the submission succeeded or is still running.
  none,

  /// The device lost connectivity or the server was unreachable.
  network,

  /// The Open Food Facts credentials were rejected.
  auth,

  /// The server rate-limited the request (HTTP 429).
  rateLimit,

  /// The server rejected the product metadata as invalid.
  validation,

  /// The product cannot be submitted because it already exists.
  duplicate,

  /// The request exceeded the per-upload timeout.
  timeout,
}

/// An immutable snapshot of a product submission in progress.
///
/// A single global instance is held by the submission notifier and updated at
/// every step so the UI can render progress that survives navigation away from
/// the add-product form. The [barcode] identifies which product the snapshot
/// describes; an empty [barcode] means no submission is active or terminal.
@immutable
class ProductSubmissionState {
  /// Creates a [ProductSubmissionState].
  ///
  /// The default state has an empty [barcode] and [SubmissionStep.checking],
  /// which is neither active nor terminal.
  const ProductSubmissionState({
    this.barcode = '',
    this.step = SubmissionStep.checking,
    this.currentImageIndex = 0,
    this.totalImages = 0,
    this.errorCategory = SubmissionErrorCategory.none,
  });

  /// The barcode of the product being submitted, or an empty string when no
  /// submission is active.
  final String barcode;

  /// The current lifecycle step of the submission.
  final SubmissionStep step;

  /// The one-based index of the image currently being uploaded, or zero when
  /// no image upload is running.
  final int currentImageIndex;

  /// The total number of images to upload for this product.
  final int totalImages;

  /// Why the submission failed, or [SubmissionErrorCategory.none] when it has
  /// not failed.
  final SubmissionErrorCategory errorCategory;

  /// True when a submission for [barcode] is actively running.
  bool get isActive =>
      barcode.isNotEmpty &&
      switch (step) {
        SubmissionStep.checking ||
        SubmissionStep.submittingMetadata ||
        SubmissionStep.uploadingImage ||
        SubmissionStep.retrying => true,
        _ => false,
      };

  /// True when the submission for [barcode] has finished.
  bool get isTerminal =>
      barcode.isNotEmpty &&
      switch (step) {
        SubmissionStep.completed ||
        SubmissionStep.partiallyCompleted ||
        SubmissionStep.failed => true,
        _ => false,
      };

  /// True when a finished submission can be retried (failed or partial).
  bool get isRetryable => isTerminal && step != SubmissionStep.completed;

  /// Returns a copy of this state with any provided fields replaced.
  ProductSubmissionState copyWith({
    String? barcode,
    SubmissionStep? step,
    int? currentImageIndex,
    int? totalImages,
    SubmissionErrorCategory? errorCategory,
  }) {
    return ProductSubmissionState(
      barcode: barcode ?? this.barcode,
      step: step ?? this.step,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      totalImages: totalImages ?? this.totalImages,
      errorCategory: errorCategory ?? this.errorCategory,
    );
  }

  /// Returns a copy describing an image upload at [current] of [total].
  ProductSubmissionState uploadingImage({
    required int current,
    required int total,
  }) {
    return copyWith(
      step: SubmissionStep.uploadingImage,
      currentImageIndex: current,
      totalImages: total,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductSubmissionState &&
        other.barcode == barcode &&
        other.step == step &&
        other.currentImageIndex == currentImageIndex &&
        other.totalImages == totalImages &&
        other.errorCategory == errorCategory;
  }

  @override
  int get hashCode => Object.hash(
    barcode,
    step,
    currentImageIndex,
    totalImages,
    errorCategory,
  );
}
