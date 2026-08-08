import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/submission_progress.dart';

/// Returns the localized, user-facing message for a
/// [SubmissionErrorCategory].
///
/// Used by the inline submission panel so failures show a message that
/// matches the failure category instead of a generic one.
String submissionErrorLabel(
  AppLocalizations l10n,
  SubmissionErrorCategory category,
) {
  return switch (category) {
    SubmissionErrorCategory.network => l10n.submissionOfflineError,
    SubmissionErrorCategory.rateLimited => l10n.submissionRateLimitedError,
    SubmissionErrorCategory.missingCredentials =>
      l10n.submissionCredentialsError,
    SubmissionErrorCategory.validation => l10n.submissionValidationError,
    SubmissionErrorCategory.duplicate => l10n.productAlreadyInOff,
    SubmissionErrorCategory.serverRejected => l10n.submissionRejectedError,
    SubmissionErrorCategory.none ||
    SubmissionErrorCategory.unknown => l10n.submissionError,
  };
}
