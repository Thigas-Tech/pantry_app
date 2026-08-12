// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A notifier that holds the current [ThemeModeOption] and persists it to
/// [SharedPreferences] under the theme_mode key.
///
/// Loads the persisted mode in [build] so no placeholder value flashes.
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// A notifier that holds the current [ThemeModeOption] and persists it to
/// [SharedPreferences] under the theme_mode key.
///
/// Loads the persisted mode in [build] so no placeholder value flashes.
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.
final class ThemeModeNotifierProvider
    extends $AsyncNotifierProvider<ThemeModeNotifier, ThemeModeOption> {
  /// A notifier that holds the current [ThemeModeOption] and persists it to
  /// [SharedPreferences] under the theme_mode key.
  ///
  /// Loads the persisted mode in [build] so no placeholder value flashes.
  /// Used by [themeModeProvider] so that any widget can read or change the
  /// theme mode.
  ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();
}

String _$themeModeNotifierHash() => r'fef597261d1cdde6467f6cd4934d4a60148013ef';

/// A notifier that holds the current [ThemeModeOption] and persists it to
/// [SharedPreferences] under the theme_mode key.
///
/// Loads the persisted mode in [build] so no placeholder value flashes.
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.

abstract class _$ThemeModeNotifier extends $AsyncNotifier<ThemeModeOption> {
  FutureOr<ThemeModeOption> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ThemeModeOption>, ThemeModeOption>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThemeModeOption>, ThemeModeOption>,
              AsyncValue<ThemeModeOption>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
