/// @file Submission status label tests.
///
/// Covers [submissionStatusLabel], the pure mapping from the product
/// submission status vocabulary ([productSubmissionNotSubmitted],
/// [productSubmissionPending], [productSubmissionSubmitted],
/// [productSubmissionFailed], [productSubmissionPartiallyCompleted]) to a
/// localized display label. The mapping powers the status chip on the
/// product detail screen and must treat any unknown status as "not
/// submitted" so future status values degrade gracefully.
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/submission_status_label.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('submissionStatusLabel', () {
    test('submitted maps to submissionSubmitted', () {
      expect(
        submissionStatusLabel(l10n, productSubmissionSubmitted),
        'Submitted to Open Food Facts',
      );
    });

    test('failed maps to submissionFailed', () {
      expect(
        submissionStatusLabel(l10n, productSubmissionFailed),
        'Failed to submit product. Tap to retry.',
      );
    });

    test('pending maps to submissionPending', () {
      expect(
        submissionStatusLabel(l10n, productSubmissionPending),
        'Pending submission to Open Food Facts',
      );
    });

    test('partially completed maps to submissionPartiallyCompleted', () {
      expect(
        submissionStatusLabel(l10n, productSubmissionPartiallyCompleted),
        'Partially submitted to Open Food Facts',
      );
    });

    test('not submitted maps to submissionNotSubmitted', () {
      expect(
        submissionStatusLabel(l10n, productSubmissionNotSubmitted),
        'Not submitted to Open Food Facts',
      );
    });

    test('unknown status falls back to not submitted', () {
      expect(
        submissionStatusLabel(l10n, 'a_future_status'),
        'Not submitted to Open Food Facts',
      );
    });
  });
}
