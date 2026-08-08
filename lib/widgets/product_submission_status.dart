import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/submission_status_label.dart';

/// Renders the persistent Open Food Facts submission state of a manual product
/// and a live progress panel while a retry is in flight.
///
/// When [ProductSubmissionNotifier] reports an active submission for this
/// product's barcode, a card with a localized step label and a
/// [LinearProgressIndicator] replaces the chip. Once the submission reaches a
/// terminal state (or no submission is running), the persisted status chip is
/// shown and a localized "Retry now" button appears for every retryable state
/// ([productSubmissionFailed], [productSubmissionPartiallyCompleted],
/// [productSubmissionPending], and [productSubmissionNotSubmitted]).
class ProductSubmissionStatus extends ConsumerWidget {
  /// Creates a [ProductSubmissionStatus] for the given [product].
  const ProductSubmissionStatus({
    required this.product,
    required this.onRetry,
    super.key,
  });

  /// The manual product whose submission status is displayed.
  final Product product;

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(productSubmissionProvider);
    if (progress != null &&
        progress.barcode == product.barcode &&
        progress.isActive) {
      return _ProgressPanel(progress: progress);
    }
    return _StatusChip(product: product, onRetry: onRetry);
  }
}

/// A card showing the localized label and progress bar of an in-flight
/// submission.
class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.progress});

  /// The in-flight progress snapshot to display.
  final SubmissionProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (text, value) = switch (progress.step) {
      SubmissionStep.checking => (l10n.preparingSubmission, null),
      SubmissionStep.submittingMetadata => (l10n.submittingMetadata, null),
      SubmissionStep.uploadingFront ||
      SubmissionStep.uploadingIngredients ||
      SubmissionStep.uploadingNutrition => (
        l10n.uploadingPhotos(
          progress.completedImageCount + 1,
          progress.totalImageCount,
        ),
        progress.totalImageCount > 0
            ? (progress.completedImageCount + 1) / progress.totalImageCount
            : null,
      ),
      SubmissionStep.completed => (l10n.submissionSuccess, 1.0),
      SubmissionStep.partiallyCompleted => (
        l10n.submissionPartiallyCompleted,
        null,
      ),
      SubmissionStep.failed => (l10n.submissionError, null),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text),
            const SizedBox(height: 8),
            ProgressIndicatorHelper.build(
              type: ProgressIndicatorType.linear,
              value: value,
            ),
          ],
        ),
      ),
    );
  }
}

/// A chip with the persisted submission status and, for retryable states, a
/// localized "Retry now" button.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.product, required this.onRetry});

  /// The manual product whose persisted status is displayed.
  final Product product;

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = product.submissionStatus;
    final label = submissionStatusLabel(l10n, status);
    final retryable =
        status == productSubmissionFailed ||
        status == productSubmissionPartiallyCompleted ||
        status == productSubmissionPending ||
        status == productSubmissionNotSubmitted;

    final chip = switch (status) {
      productSubmissionSubmitted => Chip(
        avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
        label: Text(label),
      ),
      productSubmissionFailed => Chip(
        avatar: const Icon(Icons.error, size: 18, color: Colors.red),
        label: Text(label),
      ),
      productSubmissionPending => Chip(
        avatar: ProgressIndicatorHelper.build(size: 16, strokeWidth: 2),
        label: Text(label),
      ),
      productSubmissionPartiallyCompleted => Chip(
        avatar: const Icon(
          Icons.warning_amber,
          size: 18,
          color: Colors.orange,
        ),
        label: Text(label),
      ),
      _ => Chip(
        avatar: const Icon(Icons.cloud_upload, size: 18, color: Colors.grey),
        label: Text(label),
      ),
    };

    return Row(
      children: [
        Expanded(child: chip),
        if (retryable)
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.retryNow),
          ),
      ],
    );
  }
}
