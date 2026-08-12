import 'package:pantry_app/services/image_cache_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_cache_provider.g.dart';

/// Provides the [ImageCacheService] instance.
@Riverpod(keepAlive: true)
ImageCacheService imageCache(Ref ref) {
  return ImageCacheService();
}
