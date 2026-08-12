// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_photo_picker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the single [ProductPhotoPicker] used by the add-product screen.
///
/// Tests override this provider with a mock to avoid invoking the real
/// camera or gallery pickers.

@ProviderFor(productPhotoPicker)
final productPhotoPickerProvider = ProductPhotoPickerProvider._();

/// Provides the single [ProductPhotoPicker] used by the add-product screen.
///
/// Tests override this provider with a mock to avoid invoking the real
/// camera or gallery pickers.

final class ProductPhotoPickerProvider
    extends
        $FunctionalProvider<
          ProductPhotoPicker,
          ProductPhotoPicker,
          ProductPhotoPicker
        >
    with $Provider<ProductPhotoPicker> {
  /// Provides the single [ProductPhotoPicker] used by the add-product screen.
  ///
  /// Tests override this provider with a mock to avoid invoking the real
  /// camera or gallery pickers.
  ProductPhotoPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productPhotoPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productPhotoPickerHash();

  @$internal
  @override
  $ProviderElement<ProductPhotoPicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductPhotoPicker create(Ref ref) {
    return productPhotoPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductPhotoPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductPhotoPicker>(value),
    );
  }
}

String _$productPhotoPickerHash() =>
    r'4a8fd4bdd66bab30f1a10a255d53d68e19e8d06b';
