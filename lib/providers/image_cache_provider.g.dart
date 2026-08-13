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

/// Provides the local cached file path for a product image, downloading
/// and caching it on first use.
///
/// Keyed by a (url, barcode) record so rebuilds share one in-flight
/// request instead of re-creating the future (and re-checking the file)
/// on every build.

@ProviderFor(cachedImage)
final cachedImageProvider = CachedImageFamily._();

/// Provides the local cached file path for a product image, downloading
/// and caching it on first use.
///
/// Keyed by a (url, barcode) record so rebuilds share one in-flight
/// request instead of re-creating the future (and re-checking the file)
/// on every build.

final class CachedImageProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the local cached file path for a product image, downloading
  /// and caching it on first use.
  ///
  /// Keyed by a (url, barcode) record so rebuilds share one in-flight
  /// request instead of re-creating the future (and re-checking the file)
  /// on every build.
  CachedImageProvider._({
    required CachedImageFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'cachedImageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cachedImageHash();

  @override
  String toString() {
    return r'cachedImageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return cachedImage(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedImageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cachedImageHash() => r'0a90655d953472e96ea5dcfd685051d14adbfe98';

/// Provides the local cached file path for a product image, downloading
/// and caching it on first use.
///
/// Keyed by a (url, barcode) record so rebuilds share one in-flight
/// request instead of re-creating the future (and re-checking the file)
/// on every build.

final class CachedImageFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, (String, String)> {
  CachedImageFamily._()
    : super(
        retry: null,
        name: r'cachedImageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the local cached file path for a product image, downloading
  /// and caching it on first use.
  ///
  /// Keyed by a (url, barcode) record so rebuilds share one in-flight
  /// request instead of re-creating the future (and re-checking the file)
  /// on every build.

  CachedImageProvider call((String, String) args) =>
      CachedImageProvider._(argument: args, from: this);

  @override
  String toString() => r'cachedImageProvider';
}
