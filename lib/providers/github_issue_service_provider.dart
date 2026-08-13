import 'package:pantry_app/services/github_issue_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_issue_service_provider.g.dart';

/// Provides the [GithubIssueService] instance.
@Riverpod(keepAlive: true)
GithubIssueService githubIssueService(Ref ref) {
  return GithubIssueService();
}

/// Provides the number of feedback issues queued for submission.
///
/// autoDispose: only needed while the settings screen is visible.
@riverpod
Future<int> pendingFeedbackCount(Ref ref) {
  return ref.read(githubIssueServiceProvider).pendingCount();
}
