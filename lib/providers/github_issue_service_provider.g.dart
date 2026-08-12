// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_issue_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [GithubIssueService] instance.

@ProviderFor(githubIssueService)
final githubIssueServiceProvider = GithubIssueServiceProvider._();

/// Provides the [GithubIssueService] instance.

final class GithubIssueServiceProvider
    extends
        $FunctionalProvider<
          GithubIssueService,
          GithubIssueService,
          GithubIssueService
        >
    with $Provider<GithubIssueService> {
  /// Provides the [GithubIssueService] instance.
  GithubIssueServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubIssueServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubIssueServiceHash();

  @$internal
  @override
  $ProviderElement<GithubIssueService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GithubIssueService create(Ref ref) {
    return githubIssueService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GithubIssueService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GithubIssueService>(value),
    );
  }
}

String _$githubIssueServiceHash() =>
    r'62d901cfc60c0f80416618433438cd772127249a';
