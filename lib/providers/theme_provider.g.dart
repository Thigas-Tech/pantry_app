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
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// A notifier that holds the current [ThemeModeOption] and persists it to
/// [SharedPreferences] under the theme_mode key.
///
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, ThemeModeOption> {
  /// A notifier that holds the current [ThemeModeOption] and persists it to
  /// [SharedPreferences] under the theme_mode key.
  ///
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeModeOption value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeModeOption>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'38978c05bdd50ebd4a761cf5d21b2cda13548301';

/// A notifier that holds the current [ThemeModeOption] and persists it to
/// [SharedPreferences] under the theme_mode key.
///
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.

abstract class _$ThemeModeNotifier extends $Notifier<ThemeModeOption> {
  ThemeModeOption build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeModeOption, ThemeModeOption>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeModeOption, ThemeModeOption>,
              ThemeModeOption,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
