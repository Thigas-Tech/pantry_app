// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A notifier that holds the current [Settings] and persists every field
/// to [SharedPreferences].

@ProviderFor(SettingsNotifier)
final settingsProvider = SettingsNotifierProvider._();

/// A notifier that holds the current [Settings] and persists every field
/// to [SharedPreferences].
final class SettingsNotifierProvider
    extends $AsyncNotifierProvider<SettingsNotifier, Settings> {
  /// A notifier that holds the current [Settings] and persists every field
  /// to [SharedPreferences].
  SettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsNotifierHash();

  @$internal
  @override
  SettingsNotifier create() => SettingsNotifier();
}

String _$settingsNotifierHash() => r'a8dcba65857803935301247ca58bd46edfacf59a';

/// A notifier that holds the current [Settings] and persists every field
/// to [SharedPreferences].

abstract class _$SettingsNotifier extends $AsyncNotifier<Settings> {
  FutureOr<Settings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Settings>, Settings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Settings>, Settings>,
              AsyncValue<Settings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
