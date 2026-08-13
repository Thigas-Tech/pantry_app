// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_flags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A notifier that holds the current [UiFlags] and persists every field
/// to [SharedPreferences].

@ProviderFor(UiFlagsNotifier)
final uiFlagsProvider = UiFlagsNotifierProvider._();

/// A notifier that holds the current [UiFlags] and persists every field
/// to [SharedPreferences].
final class UiFlagsNotifierProvider
    extends $AsyncNotifierProvider<UiFlagsNotifier, UiFlags> {
  /// A notifier that holds the current [UiFlags] and persists every field
  /// to [SharedPreferences].
  UiFlagsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uiFlagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uiFlagsNotifierHash();

  @$internal
  @override
  UiFlagsNotifier create() => UiFlagsNotifier();
}

String _$uiFlagsNotifierHash() => r'4dc409c2bef59cc749b071841a7394081e74e389';

/// A notifier that holds the current [UiFlags] and persists every field
/// to [SharedPreferences].

abstract class _$UiFlagsNotifier extends $AsyncNotifier<UiFlags> {
  FutureOr<UiFlags> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UiFlags>, UiFlags>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UiFlags>, UiFlags>,
              AsyncValue<UiFlags>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
