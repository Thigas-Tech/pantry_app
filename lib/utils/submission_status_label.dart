import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';

/// Returns the localized label for a product submission [status].
///
/// Maps the submission status vocabulary defined for [Product] to the
/// matching localized string used by the status chip on the product detail
/// screen. Unknown or empty statuses fall back to the "not submitted"
/// label so future status values degrade gracefully instead of throwing.
String submissionStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case productSubmissionSubmitted:
      return l10n.submissionSubmitted;
    case productSubmissionFailed:
      return l10n.submissionFailed;
    case productSubmissionPending:
      return l10n.submissionPending;
    case productSubmissionPartiallyCompleted:
      return l10n.submissionPartiallyCompleted;
    case productSubmissionNotSubmitted:
    default:
      return l10n.submissionNotSubmitted;
  }
}
