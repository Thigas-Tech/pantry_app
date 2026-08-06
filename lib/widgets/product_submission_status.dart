import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/submission_status_label.dart';

/// Displays the Open Food Facts submission status of a manual product.
///
/// Renders a [Chip] whose icon, color, and retry affordance depend on
/// [status]. Retryable statuses (failed, partial, not-submitted) show a
/// refresh control that invokes [onRetry]. The chip carries stable
/// [ValueKey]s so integration tests can locate the status and its retry
/// action without coupling to incidental layout.
class ProductSubmissionStatus extends StatelessWidget {
  /// Creates a [ProductSubmissionStatus] for the given [status].
  const ProductSubmissionStatus({
    required this.status,
    required this.barcode,
    this.onRetry,
    super.key,
  });

  /// The product's [Product.submissionStatus] vocabulary value.
  final String status;

  /// The product barcode, used in the stable keys.
  final String barcode;

  /// Called when the user taps the retry affordance, or null when the status
  /// cannot be retried (submitted, pending).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = submissionStatusLabel(l10n, status);
    final retryControl = KeyedSubtree(
      key: ValueKey('submission-retry-$barcode'),
      child: const Icon(Icons.refresh, size: 18),
    );

    final Widget chip = switch (status) {
      productSubmissionSubmitted => Chip(
        key: ValueKey('submission-status-$barcode'),
        avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
        label: Text(label),
      ),
      productSubmissionPending => Chip(
        key: ValueKey('submission-status-$barcode'),
        avatar: ProgressIndicatorHelper.build(size: 16, strokeWidth: 2),
        label: Text(label),
      ),
      productSubmissionFailed => Chip(
        key: ValueKey('submission-status-$barcode'),
        avatar: const Icon(Icons.error, size: 18, color: Colors.red),
        label: Text(label),
        deleteIcon: retryControl,
        onDeleted: onRetry,
      ),
      productSubmissionPartiallyCompleted => Chip(
        key: ValueKey('submission-status-$barcode'),
        avatar: const Icon(
          Icons.warning_amber,
          size: 18,
          color: Colors.orange,
        ),
        label: Text(label),
        deleteIcon: retryControl,
        onDeleted: onRetry,
      ),
      _ => Chip(
        key: ValueKey('submission-status-$barcode'),
        avatar: const Icon(
          Icons.cloud_upload,
          size: 18,
          color: Colors.grey,
        ),
        label: Text(label),
        deleteIcon: retryControl,
        onDeleted: onRetry,
      ),
    };

    return Semantics(
      button: onRetry != null,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: chip,
      ),
    );
  }
}
