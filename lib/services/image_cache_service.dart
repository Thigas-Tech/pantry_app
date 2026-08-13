import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:pantry_app/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

/// The longest side, in pixels, that a cached image may have.
///
/// Display sizes are roughly 40-200 dp, so 400 px at a 2x pixel ratio
/// covers the largest card without storing full-resolution source files.
const int kMaxCachedImageDimension = 400;

/// Decodes image bytes and re-encodes them as WebP in a background isolate,
/// downscaling the longest side to [kMaxCachedImageDimension] pixels.
///
/// [args] carries the raw image bytes and the maximum dimension. Returns
/// null when the bytes do not decode to an image.
Uint8List? _decodeAndEncodeWebp((Uint8List, int) args) {
  final (bytes, maxDimension) = args;
  final originalImage = img.decodeImage(bytes);
  if (originalImage == null) return null;

  var image = originalImage;
  final longestSide = image.width > image.height ? image.width : image.height;
  if (longestSide > maxDimension) {
    final scale = maxDimension / longestSide;
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }
  return Uint8List.fromList(img.encodeWebP(image));
}

/// Caches product images locally in the WebP format.
///
/// Images are downloaded from the network, decoded, downscaled to at most
/// [kMaxCachedImageDimension] pixels on the longest side, re-encoded as
/// WebP for storage efficiency, and saved to
/// app-documents/image_cache/barcode.webp. On subsequent requests the
/// cached file is returned without a network call.
///
/// The cache is bounded: when the total size of the cache directory
/// exceeds [maxCacheBytes] (default 50 MB), the oldest files are evicted
/// by last-modified time. Concurrent requests for the same barcode share
/// one in-flight download instead of fetching twice.
///
/// All I/O is asynchronous — no synchronous file operations are used.
class ImageCacheService {
  /// Creates an [ImageCacheService].
  ///
  /// If [http.Client] is not provided, a new instance is created.
  /// If [Directory] is not provided, the default application documents
  /// directory is used. [maxCacheBytes] bounds the total on-disk cache
  /// size (oldest files are evicted when exceeded). All parameters allow
  /// unit tests to inject mocks and small limits.
  ImageCacheService({
    http.Client? httpClient,
    this.cacheDirectory,
    this.maxCacheBytes = 50 * 1024 * 1024,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// The directory used to store cached images, or null to use the
  /// application documents directory.
  final Directory? cacheDirectory;

  /// The maximum total size of the on-disk image cache in bytes.
  final int maxCacheBytes;

  /// In-flight downloads keyed by barcode, so concurrent requests for the
  /// same image share one network call.
  final Map<String, Future<String?>> _inFlight = {};

  /// Downloads the image at [imageUrl] for the product with [barcode],
  /// converts it to WebP, and saves it to the local file system.
  ///
  /// Returns the path to the cached file, or null if caching failed.
  /// Concurrent calls for the same [barcode] share one download.
  Future<String?> cacheImage(String? imageUrl, String barcode) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final inFlight = _inFlight[barcode];
    if (inFlight != null) return inFlight;

    final future = _cacheImageImpl(imageUrl, barcode);
    _inFlight[barcode] = future;
    try {
      return await future;
    } finally {
      final _ = _inFlight.remove(barcode);
    }
  }

  Future<String?> _cacheImageImpl(String imageUrl, String barcode) async {
    final cacheDir = await _imageCacheDirectory();
    final cachedFile = File('${cacheDir.path}/$barcode.webp');

    if (await cachedFile.exists()) {
      return cachedFile.path;
    }

    try {
      final response = await _httpClient.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      final webpBytes = await compute(
        _decodeAndEncodeWebp,
        (Uint8List.fromList(response.bodyBytes), kMaxCachedImageDimension),
      );
      if (webpBytes == null) return null;
      await cachedFile.writeAsBytes(webpBytes);
      await _evictIfNeeded(cacheDir);
      logInfo('Image cached for $barcode');
      return cachedFile.path;
    } on Object catch (e) {
      logError('Failed to cache image for $barcode: $e');
      return null;
    }
  }

  /// Evicts the oldest cached files (by last-modified time) until the
  /// total size of [cacheDir] is within [maxCacheBytes].
  Future<void> _evictIfNeeded(Directory cacheDir) async {
    final entries = <(File, int)>[];
    var total = 0;
    await for (final entity in cacheDir.list()) {
      if (entity is! File) continue;
      final size = await entity.length();
      entries.add((entity, size));
      total += size;
    }
    if (total <= maxCacheBytes) return;

    entries.sort(
      (a, b) => a.$1.statSync().modified.compareTo(b.$1.statSync().modified),
    );
    var current = total;
    for (final (file, size) in entries) {
      if (current <= maxCacheBytes) break;
      await file.delete();
      current -= size;
      logInfo('Evicted cached image ${file.path}');
    }
  }

  /// Returns the directory where cached images are stored.
  Future<Directory> _imageCacheDirectory() async {
    final injected = cacheDirectory;
    if (injected != null) {
      return injected;
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
