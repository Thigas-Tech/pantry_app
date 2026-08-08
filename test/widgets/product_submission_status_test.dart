/// @file ProductSubmissionStatus widget tests.
///
/// The widget renders the persistent submission state of a manual product and
/// a live progress panel while a retry is in flight. Tests cover the
/// failed/pending/partial/not-submitted states with their Retry button, the
/// submitted state without one, and the switch to an in-flight progress panel
/// driven by [productSubmissionProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/widgets/product_submission_status.dart';
import '../helpers/pump_app.dart';

/// A notifier seeded with a fixed progress snapshot.
class _SeededNotifier extends ProductSubmissionNotifier {
  _SeededNotifier(this.seed);

  final SubmissionProgress? seed;

  @override
  SubmissionProgress? build() => seed;
}

const _failed = Product(
  barcode: '234567890',
  name: 'Manual Failed',
  source: 'manual',
  submissionStatus: productSubmissionFailed,
);

const _submitted = Product(
  barcode: '123456789',
  name: 'Manual Submitted',
  source: 'manual',
  submissionStatus: productSubmissionSubmitted,
);

const _pending = Product(
  barcode: '345678901',
  name: 'Manual Pending',
  source: 'manual',
  submissionStatus: productSubmissionPending,
);

const _partial = Product(
  barcode: '567890123',
  name: 'Manual Partial',
  source: 'manual',
  submissionStatus: productSubmissionPartiallyCompleted,
);

const _notSubmitted = Product(
  barcode: '456789012',
  name: 'Manual Not Submitted',
  source: 'manual',
);

SubmissionProgress _progress(
  SubmissionStep step, {
  String barcode = '234567890',
}) {
  return SubmissionProgress(barcode: barcode, step: step);
}

Future<void> _pump(
  WidgetTester tester, {
  required Product product,
  required VoidCallback onRetry,
  SubmissionProgress? progress,
}) async {
  await pumpApp(
    tester,
    Scaffold(
      body: ProductSubmissionStatus(product: product, onRetry: onRetry),
    ),
    overrides: [
      productSubmissionProvider.overrideWith(() => _SeededNotifier(progress)),
    ],
    settle: false,
  );
  await tester.pump();
}

void main() {
  testWidgets('failed status shows the failed label and a Retry button', (
    tester,
  ) async {
    await _pump(tester, product: _failed, onRetry: () {});

    expect(
      find.text('Failed to submit product. Tap to retry.'),
      findsOneWidget,
    );
    expect(find.text('Retry now'), findsOneWidget);
  });

  testWidgets('tapping Retry invokes the callback', (tester) async {
    var retried = 0;
    await _pump(tester, product: _failed, onRetry: () => retried++);

    await tester.tap(find.text('Retry now'));
    await tester.pump();

    expect(retried, 1);
  });

  testWidgets('submitted status shows no Retry button', (tester) async {
    await _pump(tester, product: _submitted, onRetry: () {});

    expect(find.text('Submitted to Open Food Facts'), findsOneWidget);
    expect(find.text('Retry now'), findsNothing);
  });

  testWidgets('pending status offers Retry', (tester) async {
    await _pump(tester, product: _pending, onRetry: () {});

    expect(find.text('Pending submission to Open Food Facts'), findsOneWidget);
    expect(find.text('Retry now'), findsOneWidget);
  });

  testWidgets('partially completed status offers Retry', (tester) async {
    await _pump(tester, product: _partial, onRetry: () {});

    expect(
      find.text('Partially submitted to Open Food Facts'),
      findsOneWidget,
    );
    expect(find.text('Retry now'), findsOneWidget);
  });

  testWidgets('not submitted status offers Retry', (tester) async {
    await _pump(tester, product: _notSubmitted, onRetry: () {});

    expect(find.text('Not submitted to Open Food Facts'), findsOneWidget);
    expect(find.text('Retry now'), findsOneWidget);
  });

  testWidgets('active progress renders the upload panel and hides Retry', (
    tester,
  ) async {
    await _pump(
      tester,
      product: _failed,
      onRetry: () {},
      progress: _progress(
        SubmissionStep.uploadingFront,
      ).copyWith(completedImageCount: 0, totalImageCount: 3),
    );

    expect(find.text('Uploading photo 1 of 3…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Retry now'), findsNothing);
  });

  testWidgets('terminal progress falls back to the persisted chip', (
    tester,
  ) async {
    await _pump(
      tester,
      product: _failed,
      onRetry: () {},
      progress: _progress(SubmissionStep.failed),
    );

    expect(
      find.text('Failed to submit product. Tap to retry.'),
      findsOneWidget,
    );
    expect(find.text('Retry now'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('progress for another barcode is ignored', (tester) async {
    await _pump(
      tester,
      product: _failed,
      onRetry: () {},
      progress: _progress(
        SubmissionStep.uploadingFront,
        barcode: 'other-barcode',
      ),
    );

    expect(
      find.text('Failed to submit product. Tap to retry.'),
      findsOneWidget,
    );
    expect(find.text('Retry now'), findsOneWidget);
  });
}
