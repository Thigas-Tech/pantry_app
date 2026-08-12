// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks whether the user has completed the empty-pantry onboarding.
///
/// Returns true once the user has added their first item to any inventory.
/// Once set to true the flag is never cleared, so the onboarding is never
/// shown again — even if the user later empties their pantry.

@ProviderFor(OnboardingNotifier)
final onboardingProvider = OnboardingNotifierProvider._();

/// Tracks whether the user has completed the empty-pantry onboarding.
///
/// Returns true once the user has added their first item to any inventory.
/// Once set to true the flag is never cleared, so the onboarding is never
/// shown again — even if the user later empties their pantry.
final class OnboardingNotifierProvider
    extends $NotifierProvider<OnboardingNotifier, bool> {
  /// Tracks whether the user has completed the empty-pantry onboarding.
  ///
  /// Returns true once the user has added their first item to any inventory.
  /// Once set to true the flag is never cleared, so the onboarding is never
  /// shown again — even if the user later empties their pantry.
  OnboardingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingNotifierHash();

  @$internal
  @override
  OnboardingNotifier create() => OnboardingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingNotifierHash() =>
    r'0d4a81d3d18a6e9cf7501947c9c7ff60940d6aa1';

/// Tracks whether the user has completed the empty-pantry onboarding.
///
/// Returns true once the user has added their first item to any inventory.
/// Once set to true the flag is never cleared, so the onboarding is never
/// shown again — even if the user later empties their pantry.

abstract class _$OnboardingNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
