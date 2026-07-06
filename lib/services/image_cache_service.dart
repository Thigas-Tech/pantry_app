import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:pantry_app/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Caches product images locally in the WebP format.
///
/// Images are downloaded from the network, decoded, re-encoded as WebP for
/// storage efficiency, and saved to `<app-documents>/image_cache/<barcode>.webp`.
/// On subsequent requests the cached file is returned without a network call.
///
/// All I/O is asynchronous — no synchronous file operations are used.
class ImageCacheService {
  /// Creates an [ImageCacheService].
  ///
  /// If [_httpClient] is not provided, a new [http.Client] instance is created.
  /// If [_cacheDirectory] is not provided, the default application documents
  /// directory is used. Both parameters allow unit tests to inject mocks.
  ImageCacheService({http.Client? httpClient, this._cacheDirectory})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final Directory? _cacheDirectory;

  /// Downloads the image at [imageUrl] for the product with [barcode],
  /// converts it to WebP, and saves it to the local file system.
  ///
  /// Returns the path to the cached file, or `null` if caching failed.
  Future<String?> cacheImage(String? imageUrl, String barcode) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final cacheDir = await _imageCacheDirectory();
    final cachedFile = File('${cacheDir.path}/$barcode.webp');

    if (await cachedFile.exists()) {
      return cachedFile.path;
    }

    try {
      final response = await _httpClient.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      final originalImage = img.decodeImage(response.bodyBytes);
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
