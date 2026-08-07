import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/submission_progress.dart';

void main() {
  group('SubmissionProgress', () {
    test('defaults to the checking step for a barcode', () {
      const progress = SubmissionProgress(barcode: '123');
      expect(progress.barcode, '123');
      expect(progress.step, SubmissionStep.checking);
      expect(progress.completedImageCount, 0);
      expect(progress.totalImageCount, 0);
      expect(progress.errorCategory, SubmissionErrorCategory.none);
      expect(progress.retryAvailable, isFalse);
    });

    test('copyWith replaces the given fields only', () {
      const progress = SubmissionProgress(
        barcode: '123',
        step: SubmissionStep.submittingMetadata,
        totalImageCount: 2,
      );
      final updated = progress.copyWith(
        step: SubmissionStep.uploadingFront,
        completedImageCount: 1,
        errorCategory: SubmissionErrorCategory.network,
      );
      expect(updated.barcode, '123');
      expect(updated.step, SubmissionStep.uploadingFront);
      expect(updated.completedImageCount, 1);
      expect(updated.totalImageCount, 2);
      expect(updated.errorCategory, SubmissionErrorCategory.network);
    });

    test('isTerminal is false while a submission is active', () {
      const progress = SubmissionProgress(
        barcode: '123',
        step: SubmissionStep.uploadingNutrition,
      );
      expect(progress.isTerminal, isFalse);
      expect(progress.isActive, isTrue);
    });

    test('isTerminal is true for completed', () {
      const progress = SubmissionProgress(
        barcode: '123',
        step: SubmissionStep.completed,
        totalImageCount: 2,
        completedImageCount: 2,
      );
      expect(progress.isTerminal, isTrue);
      expect(progress.isActive, isFalse);
    });

    test('isTerminal is true for partiallyCompleted', () {
      const progress = SubmissionProgress(
        barcode: '123',
        step: SubmissionStep.partiallyCompleted,
        retryAvailable: true,
      );
      expect(progress.isTerminal, isTrue);
    });

    test('isTerminal is true for failed', () {
      const progress = SubmissionProgress(
        barcode: '123',
        step: SubmissionStep.failed,
      );
      expect(progress.isTerminal, isTrue);
    });

    test('equality compares all fields', () {
      const a = SubmissionProgress(
        barcode: '123',
        step: SubmissionStep.completed,
      );
      const b = SubmissionProgress(
        barcode: '123',
        step: SubmissionStep.completed,
      );
      const c = SubmissionProgress(
        barcode: '123',
        step: SubmissionStep.failed,
      );
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });
  });
}
