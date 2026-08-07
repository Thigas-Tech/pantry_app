import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/product_submission_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Exposes observable, durable progress for an Open Food Facts submission.
///
/// The notifier owns the submission lifecycle: [submit] starts a
/// background submission, [state] holds the latest [SubmissionProgress]
/// snapshot (null when idle), and [isSubmitting] reports whether a
/// submission is running. Because [productSubmissionProvider] is a plain
/// [NotifierProvider] (not autoDispose), progress outlives the screen that
/// started the submission, so a user can navigate away while uploads
/// continue.
class ProductSubmissionNotifier extends Notifier<SubmissionProgress?> {
  bool _inFlight = false;

  @override
  SubmissionProgress? build() {
    _inFlight = false;
    return null;
  }

  /// Whether a submission is currently running.
  bool get isSubmitting => _inFlight;

  /// Starts submitting [product] to Open Food Facts unless a submission
  /// is already in flight.
  ///
  /// Progress snapshots are written to [state] as the submission runs. The
  /// returned future completes when the submission reaches a terminal
  /// state. Duplicate calls while in flight are ignored.
  Future<void> submit(Product product) async {
    if (_inFlight) return;
    _inFlight = true;
    if (ref.mounted) state = null;
    final service = ref.read(productSubmissionServiceProvider);
    try {
      await service.submitProduct(
        product,
        onProgress: (progress) {
          if (ref.mounted) state = progress;
        },
      );
    } on Object catch (e) {
      logError('Unexpected submission error for ${product.barcode}: $e');
      if (ref.mounted) {
        state = SubmissionProgress(
          barcode: product.barcode,
          step: SubmissionStep.failed,
          errorCategory: SubmissionErrorCategory.unknown,
          retryAvailable: true,
        );
      }
    } finally {
      _inFlight = false;
    }
  }

  /// Clears the current progress so the UI returns to its idle state.
  void clear() {
    if (ref.mounted) state = null;
  }
}

/// The provider for [ProductSubmissionNotifier].
final productSubmissionProvider =
    NotifierProvider<ProductSubmissionNotifier, SubmissionProgress?>(
      ProductSubmissionNotifier.new,
    );

/// Provider for [ProductSubmissionService].
final productSubmissionServiceProvider = Provider<ProductSubmissionService>(
  (ref) {
    final db = ref.watch(databaseProvider);
    final api = ref.watch(apiServiceProvider);
    return ProductSubmissionService(db: db, api: api);
  },
);
