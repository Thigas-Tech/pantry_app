import 'package:pantry_app/services/github_issue_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_issue_service_provider.g.dart';

/// Provides the [GithubIssueService] instance.
@Riverpod(keepAlive: true)
GithubIssueService githubIssueService(Ref ref) {
  return GithubIssueService();
}
