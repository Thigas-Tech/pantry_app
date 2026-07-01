import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/image_cache_service.dart';

/// Provides the [ImageCacheService] to the widget tree.
///
/// The service downloads product images, converts them to WebP, and stores
/// them in the local cache directory.
final imageCacheProvider = Provider<ImageCacheService>((ref) {
  return ImageCacheService();
});
