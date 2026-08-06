import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product_submission_state.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';

/// Shows a modal bottom sheet reporting live product submission progress.
///
/// Pushed on the root navigator so it survives navigating away from the
/// add-product screen. It watches [productSubmissionNotifierProvider]: while
/// the submission runs it renders a [LinearProgressIndicator] and the current
/// step, and when the submission finishes it swaps to a terminal result with
/// a Done button. The sheet can be dismissed at any time; the submission
/// continues in the background and its status is persisted to the database.
Future<void> showSubmissionProgressSheet(
  BuildContext context, {
  required String barcode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => SubmissionProgressSheet(barcode: barcode),
  );
}

/// The sheet body that renders progress for the submission of [barcode].
class SubmissionProgressSheet extends ConsumerWidget {
  /// Creates a [SubmissionProgressSheet] for the given [barcode].
  const SubmissionProgressSheet({required this.barcode, super.key});

  /// The barcode of the product whose submission is being reported.
  final String barcode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(productSubmissionNotifierProvider);
    final matches = state.barcode == barcode;

    final Widget body;
    if (matches && state.isActive) {
      body = _ProgressBody(state: state);
    } else if (matches && state.isTerminal) {
      body = _ResultBody(state: state);
    } else {
      body = const _IndeterminateBody();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.submissionProgressTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey('submission-sheet-minimize'),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            body,
            if (matches && state.isActive) ...[
              const SizedBox(height: 8),
              Text(
                l10n.submissionInBackground,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders an indeterminate progress bar while the submission is running.
class _IndeterminateBody extends StatelessWidget {
  const _IndeterminateBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 12),
        Text(l10n.submittingMetadata),
      ],
    );
  }
}

/// Renders step-specific progress for an active submission.
class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.state});

  /// The active submission state.
  final ProductSubmissionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUpload = state.step == SubmissionStep.uploadingImage;
    final value = isUpload && state.totalImages > 0
        ? state.currentImageIndex / state.totalImages
        : null;
    final label = isUpload
        ? l10n.uploadingPhotos(state.currentImageIndex, state.totalImages)
        : l10n.submittingMetadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: value),
        const SizedBox(height: 12),
        Text(label),
      ],
    );
  }
}

/// Renders the terminal result of a finished submission.
class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.state});

  /// The terminal submission state.
  final ProductSubmissionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color, message) = switch (state.step) {
      SubmissionStep.completed => (
        Icons.check_circle,
        Colors.green,
        l10n.submissionSuccess,
      ),
      SubmissionStep.partiallyCompleted => (
        Icons.warning_amber,
        Colors.orange,
        l10n.submissionPartial,
      ),
      _ => (Icons.error, Colors.red, l10n.submissionError),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('submission-sheet-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.submissionDone),
        ),
      ],
    );
  }
}
