// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton [PriceRepository] instance.

@ProviderFor(priceRepository)
final priceRepositoryProvider = PriceRepositoryProvider._();

/// Provides a singleton [PriceRepository] instance.

final class PriceRepositoryProvider
    extends
        $FunctionalProvider<PriceRepository, PriceRepository, PriceRepository>
    with $Provider<PriceRepository> {
  /// Provides a singleton [PriceRepository] instance.
  PriceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'priceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$priceRepositoryHash();

  @$internal
  @override
  $ProviderElement<PriceRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PriceRepository create(Ref ref) {
    return priceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PriceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PriceRepository>(value),
    );
  }
}

String _$priceRepositoryHash() => r'84e91b9c6fd9ec7f73d21dcefc94988ce256a39c';
