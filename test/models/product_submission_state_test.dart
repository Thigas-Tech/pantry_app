import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product_submission_state.dart';

void main() {
  group('ProductSubmissionState', () {
    test('defaults to an empty, inactive state', () {
      const state = ProductSubmissionState();

      expect(state.barcode, '');
      expect(state.step, SubmissionStep.checking);
      expect(state.currentImageIndex, 0);
      expect(state.totalImages, 0);
      expect(state.errorCategory, SubmissionErrorCategory.none);
      expect(state.isActive, isFalse);
      expect(state.isTerminal, isFalse);
      expect(state.isRetryable, isFalse);
    });

    test('copyWith replaces only the provided fields', () {
      const state = ProductSubmissionState(barcode: '123');
      final updated = state.copyWith(
        step: SubmissionStep.uploadingImage,
        currentImageIndex: 2,
        totalImages: 3,
      );

      expect(updated.barcode, '123');
      expect(updated.step, SubmissionStep.uploadingImage);
      expect(updated.currentImageIndex, 2);
      expect(updated.totalImages, 3);
      expect(updated.errorCategory, SubmissionErrorCategory.none);
    });

    test('uploadingImage reports an active upload step', () {
      const state = ProductSubmissionState(barcode: '123');
      final upload = state.uploadingImage(current: 1, total: 3);

      expect(upload.step, SubmissionStep.uploadingImage);
      expect(upload.currentImageIndex, 1);
      expect(upload.totalImages, 3);
      expect(upload.isActive, isTrue);
      expect(upload.isTerminal, isFalse);
    });

    test('checking and submittingMetadata are active but not terminal', () {
      for (final step in [
        SubmissionStep.checking,
        SubmissionStep.submittingMetadata,
        SubmissionStep.retrying,
      ]) {
        const state = ProductSubmissionState(barcode: '123');
        final active = state.copyWith(step: step);
        expect(active.isActive, isTrue, reason: '$step should be active');
        expect(
          active.isTerminal,
          isFalse,
          reason: '$step should not be terminal',
        );
      }
    });

    test('completed, partiallyCompleted and failed are terminal', () {
      for (final step in [
        SubmissionStep.completed,
        SubmissionStep.partiallyCompleted,
        SubmissionStep.failed,
      ]) {
        const state = ProductSubmissionState(barcode: '123');
        final terminal = state.copyWith(step: step);
        expect(
          terminal.isActive,
          isFalse,
          reason: '$step should not be active',
        );
        expect(terminal.isTerminal, isTrue, reason: '$step should be terminal');
      }
    });

    test('failed and partial are retryable, completed is not', () {
      const failed = ProductSubmissionState(
        barcode: '123',
        step: SubmissionStep.failed,
      );
      const partial = ProductSubmissionState(
        barcode: '123',
        step: SubmissionStep.partiallyCompleted,
      );
      const completed = ProductSubmissionState(
        barcode: '123',
        step: SubmissionStep.completed,
      );

      expect(failed.isRetryable, isTrue);
      expect(partial.isRetryable, isTrue);
      expect(completed.isRetryable, isFalse);
    });

    test('equality compares every field', () {
      const a = ProductSubmissionState(
        barcode: '123',
        step: SubmissionStep.failed,
        errorCategory: SubmissionErrorCategory.timeout,
      );
      const same = ProductSubmissionState(
        barcode: '123',
        step: SubmissionStep.failed,
        errorCategory: SubmissionErrorCategory.timeout,
      );
      const different = ProductSubmissionState(
        barcode: '123',
        step: SubmissionStep.failed,
        errorCategory: SubmissionErrorCategory.network,
      );

      expect(a, same);
      expect(a, isNot(different));
      expect(a.hashCode, same.hashCode);
    });
  });
}
