// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [ImageCacheService] instance.

@ProviderFor(imageCache)
final imageCacheProvider = ImageCacheProvider._();

/// Provides the [ImageCacheService] instance.

final class ImageCacheProvider
    extends
        $FunctionalProvider<
          ImageCacheService,
          ImageCacheService,
          ImageCacheService
        >
    with $Provider<ImageCacheService> {
  /// Provides the [ImageCacheService] instance.
  ImageCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageCacheHash();

  @$internal
  @override
  $ProviderElement<ImageCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageCacheService create(Ref ref) {
    return imageCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageCacheService>(value),
    );
  }
}

String _$imageCacheHash() => r'57e6f8682b10c439d136807ac725044625616f27';
