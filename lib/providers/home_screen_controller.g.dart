// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_screen_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeScreenController)
final homeScreenControllerProvider = HomeScreenControllerProvider._();

final class HomeScreenControllerProvider
    extends $NotifierProvider<HomeScreenController, HomeScreenState> {
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
    r'01b2c76d24ec91d8ab770a110db3f04485c016db';

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
