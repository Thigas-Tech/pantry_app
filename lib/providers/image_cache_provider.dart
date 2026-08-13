import 'package:pantry_app/services/image_cache_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_cache_provider.g.dart';

/// Provides the [ImageCacheService] instance.
@Riverpod(keepAlive: true)
ImageCacheService imageCache(Ref ref) {
  return ImageCacheService();
}

/// Provides the local cached file path for a product image, downloading
/// and caching it on first use.
///
/// Keyed by a (url, barcode) record so rebuilds share one in-flight
/// request instead of re-creating the future (and re-checking the file)
/// on every build.
@riverpod
Future<String?> cachedImage(Ref ref, (String, String) args) {
  final (url, barcode) = args;
  return ref.read(imageCacheProvider).cacheImage(url, barcode);
}
