/// @file Submission error label tests.
///
/// Covers [submissionErrorLabel], the pure mapping from a
/// [SubmissionErrorCategory] to a localized, user-facing failure message.
/// The mapping powers the inline submission panel so every failure category
/// shows a message that matches its cause.
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/utils/submission_error_label.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('submissionErrorLabel', () {
    test('network maps to submissionOfflineError', () {
      expect(
        submissionErrorLabel(l10n, SubmissionErrorCategory.network),
        l10n.submissionOfflineError,
      );
    });

    test('rateLimited maps to submissionRateLimitedError', () {
      expect(
        submissionErrorLabel(l10n, SubmissionErrorCategory.rateLimited),
        l10n.submissionRateLimitedError,
      );
    });

    test('missingCredentials maps to submissionCredentialsError', () {
      expect(
        submissionErrorLabel(l10n, SubmissionErrorCategory.missingCredentials),
        l10n.submissionCredentialsError,
      );
    });

    test('validation maps to submissionValidationError', () {
      expect(
        submissionErrorLabel(l10n, SubmissionErrorCategory.validation),
        l10n.submissionValidationError,
      );
    });

    test('duplicate maps to productAlreadyInOff', () {
      expect(
        submissionErrorLabel(l10n, SubmissionErrorCategory.duplicate),
        l10n.productAlreadyInOff,
      );
    });

    test('serverRejected maps to submissionRejectedError', () {
      expect(
        submissionErrorLabel(l10n, SubmissionErrorCategory.serverRejected),
        l10n.submissionRejectedError,
      );
    });

    test('none and unknown map to the generic submissionError', () {
      expect(
        submissionErrorLabel(l10n, SubmissionErrorCategory.none),
        l10n.submissionError,
      );
      expect(
        submissionErrorLabel(l10n, SubmissionErrorCategory.unknown),
        l10n.submissionError,
      );
    });
  });
}
