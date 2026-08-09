import 'package:flutter/foundation.dart';

/// The current step of an Open Food Facts product submission.
///
/// The step names the operation the submission service is performing so
/// the UI can show localized, human-readable progress. Upload steps map
/// to the OFF image fields in the order they are submitted: front,
/// ingredients, then nutrition.
enum SubmissionStep {
  /// The submission is being prepared (e.g. product cached locally).
  checking,

  /// Product metadata is being submitted to Open Food Facts.
  submittingMetadata,

  /// The front (product packaging) photo is being uploaded.
  uploadingFront,

  /// The ingredients-list photo is being uploaded.
  uploadingIngredients,

  /// The nutrition-table photo is being uploaded.
  uploadingNutrition,

  /// The submission finished successfully.
  completed,

  /// Metadata and some photos succeeded but at least one photo failed.
  partiallyCompleted,

  /// The submission failed and no partial progress was persisted.
  failed,
}

/// The category of a submission or image-upload failure.
///
/// Used to decide whether retrying can help and to pick a localized
/// message. Transient categories ([network] and [rateLimited]) allow
/// retry; permanent ones ([missingCredentials], [validation],
/// [duplicate], and [serverRejected]) do not.
enum SubmissionErrorCategory {
  /// No error; the last operation succeeded.
  none,

  /// Open Food Facts credentials are not configured.
  missingCredentials,

  /// A network or timeout error occurred.
  network,

  /// Open Food Facts rate-limited the request.
  rateLimited,

  /// The server rejected the request with a validation error.
  validation,

  /// The server rejected the Open Food Facts credentials.
  wrongCredentials,

  /// The barcode already exists on Open Food Facts.
  duplicate,

  /// The server rejected the request (e.g. validation failure).
  serverRejected,

  /// The failure could not be categorized.
  unknown,
}

/// An immutable snapshot of the progress of a product submission.
///
/// The submission service emits these snapshots as it works so that a
/// Riverpod notifier can expose observable, durable progress that
/// outlives the screen that started the submission. [totalImageCount]
/// counts only the image fields that have a local file;
/// [completedImageCount] is the number of images uploaded before the
/// current step, so the UI shows the in-flight image as
/// completedImageCount + 1.
@immutable
class SubmissionProgress {
  /// Creates a [SubmissionProgress].
  const SubmissionProgress({
    required this.barcode,
    this.step = SubmissionStep.checking,
    this.completedImageCount = 0,
    this.totalImageCount = 0,
    this.errorCategory = SubmissionErrorCategory.none,
    this.retryAvailable = false,
  });

  /// The barcode of the product being submitted.
  final String barcode;

  /// The current submission step.
  final SubmissionStep step;

  /// How many photos have been uploaded before the current step.
  final int completedImageCount;

  /// How many photos are expected to be uploaded in total.
  final int totalImageCount;

  /// The category of the last failure, or [SubmissionErrorCategory.none].
  final SubmissionErrorCategory errorCategory;

  /// Whether retrying the submission can succeed.
  ///
  /// True for transient failures and partial completions, false for
  /// credential or server-rejection failures.
  final bool retryAvailable;

  /// Whether the submission has reached a terminal state.
  bool get isTerminal => switch (step) {
    SubmissionStep.completed ||
    SubmissionStep.partiallyCompleted ||
    SubmissionStep.failed => true,
    _ => false,
  };

  /// Whether a submission is currently in flight.
  bool get isActive => !isTerminal;

  /// Returns a copy of this progress with the given fields replaced.
  SubmissionProgress copyWith({
    SubmissionStep? step,
    int? completedImageCount,
    int? totalImageCount,
    SubmissionErrorCategory? errorCategory,
    bool? retryAvailable,
  }) {
    return SubmissionProgress(
      barcode: barcode,
      step: step ?? this.step,
      completedImageCount: completedImageCount ?? this.completedImageCount,
      totalImageCount: totalImageCount ?? this.totalImageCount,
      errorCategory: errorCategory ?? this.errorCategory,
      retryAvailable: retryAvailable ?? this.retryAvailable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubmissionProgress) return false;
    return barcode == other.barcode &&
        step == other.step &&
        completedImageCount == other.completedImageCount &&
        totalImageCount == other.totalImageCount &&
        errorCategory == other.errorCategory &&
        retryAvailable == other.retryAvailable;
  }

  @override
  int get hashCode => Object.hash(
    barcode,
    step,
    completedImageCount,
    totalImageCount,
    errorCategory,
    retryAvailable,
  );
}
