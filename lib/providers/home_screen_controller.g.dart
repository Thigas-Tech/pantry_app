// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_screen_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier that manages ephemeral home screen UI state.
///
/// Owns selection mode, search query, produce loading state, and the
/// overdue cache refresh gate. Persistent pantry data lives in
/// [pantryProvider].

@ProviderFor(HomeScreenController)
final homeScreenControllerProvider = HomeScreenControllerProvider._();

/// Notifier that manages ephemeral home screen UI state.
///
/// Owns selection mode, search query, produce loading state, and the
/// overdue cache refresh gate. Persistent pantry data lives in
/// [pantryProvider].
final class HomeScreenControllerProvider
    extends $NotifierProvider<HomeScreenController, HomeScreenState> {
  /// Notifier that manages ephemeral home screen UI state.
  ///
  /// Owns selection mode, search query, produce loading state, and the
  /// overdue cache refresh gate. Persistent pantry data lives in
  /// [pantryProvider].
  HomeScreenControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeScreenControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeScreenControllerHash();

  @$internal
  @override
  HomeScreenController create() => HomeScreenController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeScreenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeScreenState>(value),
    );
  }
}

String _$homeScreenControllerHash() =>
    r'cd64346f5f6ee1bb54a09f6a24f061bbe5b37270';

/// Notifier that manages ephemeral home screen UI state.
///
/// Owns selection mode, search query, produce loading state, and the
/// overdue cache refresh gate. Persistent pantry data lives in
/// [pantryProvider].

abstract class _$HomeScreenController extends $Notifier<HomeScreenState> {
  HomeScreenState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HomeScreenState, HomeScreenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HomeScreenState, HomeScreenState>,
              HomeScreenState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
