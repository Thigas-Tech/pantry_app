// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current platform locale (from the dart:ui dispatcher).
///
/// keepAlive because the locale rarely changes during a session and is
/// needed by non-widget code (such as the stats provider) that cannot
/// read the resolved app locale from the widget tree. Tests can override
/// this provider to simulate a device language.

@ProviderFor(currentLocale)
final currentLocaleProvider = CurrentLocaleProvider._();

/// Provides the current platform locale (from the dart:ui dispatcher).
///
/// keepAlive because the locale rarely changes during a session and is
/// needed by non-widget code (such as the stats provider) that cannot
/// read the resolved app locale from the widget tree. Tests can override
/// this provider to simulate a device language.

final class CurrentLocaleProvider
    extends $FunctionalProvider<Locale, Locale, Locale>
    with $Provider<Locale> {
  /// Provides the current platform locale (from the dart:ui dispatcher).
  ///
  /// keepAlive because the locale rarely changes during a session and is
  /// needed by non-widget code (such as the stats provider) that cannot
  /// read the resolved app locale from the widget tree. Tests can override
  /// this provider to simulate a device language.
  CurrentLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLocaleHash();

  @$internal
  @override
  $ProviderElement<Locale> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Locale create(Ref ref) {
    return currentLocale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$currentLocaleHash() => r'73c8034755aac15f72a8115f0173372e0ecf3f4e';
