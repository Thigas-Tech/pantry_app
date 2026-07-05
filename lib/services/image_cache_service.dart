import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:pantry_app/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Caches product images locally in the WebP format.
///
/// Images are downloaded from the network, decoded, re‑encoded as WebP for
/// storage efficiency, and saved to `<app-documents>/image_cache/<barcode>.webp`.
/// On subsequent requests the cached file is returned without a network call.
///
/// All I/O is asynchronous — no synchronous file operations are used.
class ImageCacheService {
  /// Creates an [ImageCacheService].
  ///
  /// If [dio] is not provided, a new [Dio] instance is created.
  /// If [_cacheDirectory] is not provided, the default application documents
  /// directory is used. Both parameters allow unit tests to inject mocks.
  ImageCacheService({Dio? dio, this._cacheDirectory}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Directory? _cacheDirectory;

  /// Downloads the image at [imageUrl] for the product with [barcode],
  /// converts it to WebP, and saves it to the local file system.
  ///
  /// Returns the path to the cached file, or `null` if caching failed.
  Future<String?> cacheImage(String? imageUrl, String barcode) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final cacheDir = await _imageCacheDirectory();
    final cachedFile = File('${cacheDir.path}/$barcode.webp');

    // `await exists()` is used intentionally over `existsSync()` to avoid
    // blocking the UI thread, even though the linter flags it as slower.
    if (await cachedFile.exists()) {
      return cachedFile.path;
    }

    try {
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data == null) return null;

      final originalImage = img.decodeImage(Uint8List.fromList(response.data!));
      if (originalImage == null) return null;

      final webpBytes = img.encodeWebP(originalImage);
      await cachedFile.writeAsBytes(webpBytes);
      logInfo('Image cached for $barcode');
      return cachedFile.path;
    } on Exception catch (e) {
      logError('Failed to cache image for $barcode: $e');
      return null;
    }
  }

  /// Returns the directory where cached images are stored.
  Future<Directory> _imageCacheDirectory() async {
    if (_cacheDirectory != null) {
      return _cacheDirectory;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/image_cache');
    // Async file I/O is intentionally used here instead of sync (which would
    // be flagged as `avoid_slow_async_io`) because blocking the UI thread is
    // worse than performing an async existence check on a fast local file.
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Deletes all cached image files.
  ///
  /// Removes the entire image cache directory and recreates it empty.
  /// Called after an app update to force re-download of product images.
  Future<void> clearCache() async {
    try {
      final cacheDir = await _imageCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
        logInfo('Image cache cleared');
      }
    } on Exception catch (e) {
      logError('Failed to clear image cache: $e');
    }
  }
}
