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
    extends $NotifierProvider<SettingsNotifier, Settings> {
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Settings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Settings>(value),
    );
  }
}

String _$settingsNotifierHash() => r'4683452daa8cedc6d5f0cb48eb82fa1f27b54514';

/// A notifier that holds the current [Settings] and persists every field
/// to [SharedPreferences].

abstract class _$SettingsNotifier extends $Notifier<Settings> {
  Settings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Settings, Settings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Settings, Settings>,
              Settings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
