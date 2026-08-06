import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/widgets/product_submission_status.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ProductSubmissionStatus', () {
    testWidgets('shows the localized label for the given status', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: ProductSubmissionStatus(
              status: productSubmissionFailed,
              barcode: '123',
            ),
          ),
        ),
      );
      expect(
        find.text('Failed to submit product. Tap to retry.'),
        findsOneWidget,
      );
    });

    testWidgets('submitted status has no retry affordance', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: ProductSubmissionStatus(
              status: productSubmissionSubmitted,
              barcode: '123',
              onRetry: _noop,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(
        find.byKey(const ValueKey('submission-status-123')),
        findsOneWidget,
      );
    });

    testWidgets('pending status has no retry affordance', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: ProductSubmissionStatus(
              status: productSubmissionPending,
              barcode: '123',
              onRetry: _noop,
            ),
          ),
        ),
        settle: false,
      );
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('failed status offers retry and calls onRetry', (
      tester,
    ) async {
      var retried = 0;
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: ProductSubmissionStatus(
              status: productSubmissionFailed,
              barcode: '123',
              onRetry: () => retried++,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('submission-retry-123')),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(retried, 1);
    });

    testWidgets('partially completed status offers retry', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: ProductSubmissionStatus(
              status: productSubmissionPartiallyCompleted,
              barcode: '123',
              onRetry: _noop,
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('submission-retry-123')),
        findsOneWidget,
      );
    });

    testWidgets('unknown status falls back to not-submitted label', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: ProductSubmissionStatus(
              status: 'made-up',
              barcode: '123',
            ),
          ),
        ),
      );
      expect(find.text('Not submitted to Open Food Facts'), findsOneWidget);
    });
  });
}

void _noop() {}
