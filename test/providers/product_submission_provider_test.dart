import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_submission_state.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/services/product_submission_service.dart';

class MockProductSubmissionService extends Mock
    implements ProductSubmissionService {}

const testProduct = Product(
  barcode: '123456789',
  name: 'Test Product',
  source: 'manual',
);

void main() {
  setUpAll(() {
    registerFallbackValue(testProduct);
  });

  group('ProductSubmissionNotifier', () {
    test('reports step transitions and the terminal result', () async {
      final mock = MockProductSubmissionService();
      when(
        () => mock.submitProduct(
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[#onProgress]
                as void Function(ProductSubmissionState);
        onProgress(
          const ProductSubmissionState(
            barcode: '123456789',
            step: SubmissionStep.submittingMetadata,
          ),
        );
        onProgress(
          const ProductSubmissionState(
            barcode: '123456789',
            step: SubmissionStep.uploadingImage,
            currentImageIndex: 2,
            totalImages: 3,
          ),
        );
        return testProduct.copyWith(
          submissionStatus: productSubmissionPartiallyCompleted,
        );
      });
      final container = ProviderContainer(
        overrides: [
          productSubmissionServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);
      final states = <ProductSubmissionState>[];
      container.listen(
        productSubmissionNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      final result = await container
          .read(productSubmissionNotifierProvider.notifier)
          .submit(testProduct);

      expect(result.submissionStatus, productSubmissionPartiallyCompleted);
      expect(states.first.isActive, isFalse, reason: 'starts idle');
      expect(
        states.map((s) => s.step).toSet(),
        containsAll(<SubmissionStep>[
          SubmissionStep.checking,
          SubmissionStep.submittingMetadata,
          SubmissionStep.uploadingImage,
          SubmissionStep.partiallyCompleted,
        ]),
      );
      expect(states.last.step, SubmissionStep.partiallyCompleted);
    });

    test('rejects a duplicate concurrent submission', () async {
      final gate = Completer<Product>();
      final mock = MockProductSubmissionService();
      when(
        () => mock.submitProduct(
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => gate.future);
      final container = ProviderContainer(
        overrides: [
          productSubmissionServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        productSubmissionNotifierProvider.notifier,
      );

      final first = notifier.submit(testProduct);
      final second = await notifier.submit(testProduct);

      expect(second.submissionStatus, productSubmissionPending);
      verify(
        () => mock.submitProduct(
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
      gate.complete(
        testProduct.copyWith(submissionStatus: productSubmissionSubmitted),
      );
      await first;
    });

    testWidgets('submission state outlives the widget that started it', (
      tester,
    ) async {
      final gate = Completer<Product>();
      final mock = MockProductSubmissionService();
      when(
        () => mock.submitProduct(
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => gate.future);
      final container = ProviderContainer(
        overrides: [
          productSubmissionServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    unawaited(
                      container
                          .read(productSubmissionNotifierProvider.notifier)
                          .submit(testProduct),
                    );
                  },
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      // Replacing the widget tree simulates navigating away from the screen
      // while the submission is still running.
      await tester.pumpWidget(const SizedBox());
      expect(
        container.read(productSubmissionNotifierProvider).isActive,
        isTrue,
        reason: 'Submission must survive screen disposal',
      );

      gate.complete(
        testProduct.copyWith(submissionStatus: productSubmissionSubmitted),
      );
      await tester.pump();
      expect(
        container.read(productSubmissionNotifierProvider).step,
        SubmissionStep.completed,
      );
    });
  });
}
