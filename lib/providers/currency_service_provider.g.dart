// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton [CurrencyService] instance.

@ProviderFor(currencyService)
final currencyServiceProvider = CurrencyServiceProvider._();

/// Provides a singleton [CurrencyService] instance.

final class CurrencyServiceProvider
    extends
        $FunctionalProvider<CurrencyService, CurrencyService, CurrencyService>
    with $Provider<CurrencyService> {
  /// Provides a singleton [CurrencyService] instance.
  CurrencyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currencyServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currencyServiceHash();

  @$internal
  @override
  $ProviderElement<CurrencyService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CurrencyService create(Ref ref) {
    return currencyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurrencyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurrencyService>(value),
    );
  }
}

String _$currencyServiceHash() => r'5ea63bad2d2793ebf9dde8e92887eb431546da13';

/// Provides the size in bytes of the on-disk currency rate cache.
///
/// autoDispose: only needed while the settings screen is visible.

@ProviderFor(currencyCacheSize)
final currencyCacheSizeProvider = CurrencyCacheSizeProvider._();

/// Provides the size in bytes of the on-disk currency rate cache.
///
/// autoDispose: only needed while the settings screen is visible.

final class CurrencyCacheSizeProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provides the size in bytes of the on-disk currency rate cache.
  ///
  /// autoDispose: only needed while the settings screen is visible.
  CurrencyCacheSizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currencyCacheSizeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currencyCacheSizeHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return currencyCacheSize(ref);
  }
}

String _$currencyCacheSizeHash() => r'83266230271dd79e5b3497b35dd42bcd805ef462';
