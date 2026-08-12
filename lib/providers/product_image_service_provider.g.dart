// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_image_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the single [ProductImageService] used by the add-product screen.
///
/// Tests override this provider with a service pointed at a temporary
/// directory so photo persistence is exercised without camera hardware or a
/// real application-documents directory.

@ProviderFor(productImageService)
final productImageServiceProvider = ProductImageServiceProvider._();

/// Provides the single [ProductImageService] used by the add-product screen.
///
/// Tests override this provider with a service pointed at a temporary
/// directory so photo persistence is exercised without camera hardware or a
/// real application-documents directory.

final class ProductImageServiceProvider
    extends
        $FunctionalProvider<
          ProductImageService,
          ProductImageService,
          ProductImageService
        >
    with $Provider<ProductImageService> {
  /// Provides the single [ProductImageService] used by the add-product screen.
  ///
  /// Tests override this provider with a service pointed at a temporary
  /// directory so photo persistence is exercised without camera hardware or a
  /// real application-documents directory.
  ProductImageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productImageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productImageServiceHash();

  @$internal
  @override
  $ProviderElement<ProductImageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductImageService create(Ref ref) {
    return productImageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductImageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductImageService>(value),
    );
  }
}

String _$productImageServiceHash() =>
    r'f54ead40b378c6d5d6173d6bfb801c4bbb211258';
