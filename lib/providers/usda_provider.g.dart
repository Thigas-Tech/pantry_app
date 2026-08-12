// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usda_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [UsdaApiClient] instance for USDA FoodData Central searches.

@ProviderFor(usdaApiClient)
final usdaApiClientProvider = UsdaApiClientProvider._();

/// Provides a [UsdaApiClient] instance for USDA FoodData Central searches.

final class UsdaApiClientProvider
    extends $FunctionalProvider<UsdaApiClient, UsdaApiClient, UsdaApiClient>
    with $Provider<UsdaApiClient> {
  /// Provides a [UsdaApiClient] instance for USDA FoodData Central searches.
  UsdaApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usdaApiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usdaApiClientHash();

  @$internal
  @override
  $ProviderElement<UsdaApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UsdaApiClient create(Ref ref) {
    return usdaApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsdaApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsdaApiClient>(value),
    );
  }
}

String _$usdaApiClientHash() => r'1d619f1fe07037ca33fa379435614cd7ed0485bc';
