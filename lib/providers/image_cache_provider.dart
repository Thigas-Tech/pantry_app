import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/image_cache_service.dart';

/// Provides the [ImageCacheService] instance.
final imageCacheProvider = Provider<ImageCacheService>((ref) {
  return ImageCacheService();
});
