import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/submission_progress.dart';
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
  late ProviderContainer container;
  late MockProductSubmissionService mockService;

  setUpAll(() {
    registerFallbackValue(
      const Product(barcode: '', name: ''),
    );
  });

  setUp(() {
    mockService = MockProductSubmissionService();
    container = ProviderContainer(
      overrides: [
        productSubmissionServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  SubmissionProgress progress(SubmissionStep step) {
    return SubmissionProgress(
      barcode: testProduct.barcode,
      step: step,
    );
  }

  void stubSubmission(Completer<Product> completer) {
    when(
      () => mockService.submitProduct(
        any(),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) => completer.future);
  }

  group('ProductSubmissionNotifier', () {
    test('initial state is null', () {
      expect(container.read(productSubmissionProvider), isNull);
      expect(
        container.read(productSubmissionProvider.notifier).isSubmitting,
        isFalse,
      );
    });

    test('submit updates state as the service reports progress', () async {
      final notifier = container.read(productSubmissionProvider.notifier);
      final completer = Completer<Product>();
      stubSubmission(completer);

      final future = notifier.submit(testProduct);
      final captured = verify(
        () => mockService.submitProduct(
          testProduct,
          onProgress: captureAny(named: 'onProgress'),
        ),
      ).captured;
      final onProgress = captured.first as void Function(SubmissionProgress);

      onProgress(progress(SubmissionStep.submittingMetadata));
      expect(
        container.read(productSubmissionProvider)?.step,
        SubmissionStep.submittingMetadata,
      );

      onProgress(
        progress(SubmissionStep.completed).copyWith(completedImageCount: 1),
      );
      expect(
        container.read(productSubmissionProvider)?.step,
        SubmissionStep.completed,
      );

      completer.complete(testProduct);
      await future;
      expect(notifier.isSubmitting, isFalse);
    });

    test('ignores a second submit while one is in flight', () async {
      final notifier = container.read(productSubmissionProvider.notifier);
      final completer = Completer<Product>();
      stubSubmission(completer);

      final first = notifier.submit(testProduct);
      await notifier.submit(testProduct);

      verify(
        () => mockService.submitProduct(
          testProduct,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);

      completer.complete(testProduct);
      await first;
    });

    test('does not update state after disposal without throwing', () async {
      final notifier = container.read(productSubmissionProvider.notifier);
      final completer = Completer<Product>();
      stubSubmission(completer);

      final future = notifier.submit(testProduct);
      final captured = verify(
        () => mockService.submitProduct(
          testProduct,
          onProgress: captureAny(named: 'onProgress'),
        ),
      ).captured;
      final onProgress = captured.first as void Function(SubmissionProgress);

      container.dispose();
      onProgress(progress(SubmissionStep.completed));
      completer.complete(testProduct);
      await future;
    });

    test('clear resets the current progress', () async {
      final notifier = container.read(productSubmissionProvider.notifier);
      final completer = Completer<Product>();
      stubSubmission(completer);

      final future = notifier.submit(testProduct);
      final captured = verify(
        () => mockService.submitProduct(
          testProduct,
          onProgress: captureAny(named: 'onProgress'),
        ),
      ).captured;
      final onProgress = captured.first as void Function(SubmissionProgress);

      onProgress(progress(SubmissionStep.submittingMetadata));
      notifier.clear();
      expect(container.read(productSubmissionProvider), isNull);

      completer.complete(testProduct);
      await future;
    });

    test('exposes isSubmitting while in flight and false after', () async {
      final notifier = container.read(productSubmissionProvider.notifier);
      final completer = Completer<Product>();
      stubSubmission(completer);

      final future = notifier.submit(testProduct);
      expect(notifier.isSubmitting, isTrue);

      completer.complete(testProduct);
      await future;
      expect(notifier.isSubmitting, isFalse);
    });
  });
}
