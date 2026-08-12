// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks whether the user has completed the empty-pantry onboarding.
///
/// Loads the persisted flag from [SharedPreferences] in [build] so the
/// correct value is available on the first frame — no pre-runApp seeding
/// needed and no flash of the onboarding flow for returning users. Returns
/// true once the user has added their first item to any inventory. Once
/// set to true the flag is never cleared, so the onboarding is never shown
/// again — even if the user later empties their pantry.

@ProviderFor(OnboardingNotifier)
final onboardingProvider = OnboardingNotifierProvider._();

/// Tracks whether the user has completed the empty-pantry onboarding.
///
/// Loads the persisted flag from [SharedPreferences] in [build] so the
/// correct value is available on the first frame — no pre-runApp seeding
/// needed and no flash of the onboarding flow for returning users. Returns
/// true once the user has added their first item to any inventory. Once
/// set to true the flag is never cleared, so the onboarding is never shown
/// again — even if the user later empties their pantry.
final class OnboardingNotifierProvider
    extends $AsyncNotifierProvider<OnboardingNotifier, bool> {
  /// Tracks whether the user has completed the empty-pantry onboarding.
  ///
  /// Loads the persisted flag from [SharedPreferences] in [build] so the
  /// correct value is available on the first frame — no pre-runApp seeding
  /// needed and no flash of the onboarding flow for returning users. Returns
  /// true once the user has added their first item to any inventory. Once
  /// set to true the flag is never cleared, so the onboarding is never shown
  /// again — even if the user later empties their pantry.
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
}

String _$onboardingNotifierHash() =>
    r'191a07de500f90b3dbf04dafb54df4ceaff6ac12';

/// Tracks whether the user has completed the empty-pantry onboarding.
///
/// Loads the persisted flag from [SharedPreferences] in [build] so the
/// correct value is available on the first frame — no pre-runApp seeding
/// needed and no flash of the onboarding flow for returning users. Returns
/// true once the user has added their first item to any inventory. Once
/// set to true the flag is never cleared, so the onboarding is never shown
/// again — even if the user later empties their pantry.

abstract class _$OnboardingNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
