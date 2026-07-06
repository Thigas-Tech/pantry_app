import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/github_issue_service.dart';

/// Provides the [GithubIssueService] instance.
final githubIssueServiceProvider = Provider<GithubIssueService>((ref) {
  return GithubIssueService();
});
