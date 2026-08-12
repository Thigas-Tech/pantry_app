// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_photo_cropper_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [ProductPhotoCropper] used by the crop screen.
///
/// Tests override this provider with a fake cropper so widget tests can
/// verify the crop screen wiring without encoding real images.

@ProviderFor(productPhotoCropper)
final productPhotoCropperProvider = ProductPhotoCropperProvider._();

/// Provides the [ProductPhotoCropper] used by the crop screen.
///
/// Tests override this provider with a fake cropper so widget tests can
/// verify the crop screen wiring without encoding real images.

final class ProductPhotoCropperProvider
    extends
        $FunctionalProvider<
          ProductPhotoCropper,
          ProductPhotoCropper,
          ProductPhotoCropper
        >
    with $Provider<ProductPhotoCropper> {
  /// Provides the [ProductPhotoCropper] used by the crop screen.
  ///
  /// Tests override this provider with a fake cropper so widget tests can
  /// verify the crop screen wiring without encoding real images.
  ProductPhotoCropperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productPhotoCropperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productPhotoCropperHash();

  @$internal
  @override
  $ProviderElement<ProductPhotoCropper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductPhotoCropper create(Ref ref) {
    return productPhotoCropper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductPhotoCropper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductPhotoCropper>(value),
    );
  }
}

String _$productPhotoCropperHash() =>
    r'44ee017ced2fafd1024a00901bc18b42cb3703bc';
