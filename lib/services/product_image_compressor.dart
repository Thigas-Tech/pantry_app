import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pantry_app/services/image_cache_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Recompresses local product photos before they are uploaded to Open Food
/// Facts.
///
/// Camera photos can be 3-10 MB; OFF imposes upload limits and large files
/// upload slowly over mobile data. The compressor re-encodes a photo as a
/// JPEG under [defaultMaxBytes] (1 MB) while never shrinking a side below
/// [minimumDimension] (640 px), which matches OFF's minimum image size.
///
/// The expensive decode/encode runs in a background isolate via [compute],
/// following the same pattern as [ImageCacheService].
class ProductImageCompressor {
  /// The default maximum compressed size in bytes (1 MB).
  static const int defaultMaxBytes = 1 << 20;

  /// The default maximum side length in pixels before downscaling.
  static const int defaultMaxDimension = 1600;

  /// The smallest allowed side length, matching the OFF minimum.
  static const int minimumDimension = 640;

  /// Compresses the image at [sourcePath] and returns the path to the
  /// compressed JPEG temp file, or null when no compression is needed or
  /// possible.
  ///
  /// Returns null when the source file is missing, already smaller than
  /// [maxBytes], or cannot be decoded — the caller should then upload the
  /// original file. The caller owns the returned temp file and must delete
  /// it after the upload.
  Future<String?> compress({
    required String sourcePath,
    int maxBytes = defaultMaxBytes,
    int maxDimension = defaultMaxDimension,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    if (await source.length() <= maxBytes) return null;

    final bytes = await source.readAsBytes();
    try {
      final compressed = await compute(
        _compressBytes,
        _CompressArgs(
          bytes: bytes,
          maxBytes: maxBytes,
          maxDimension: maxDimension,
        ),
      );
      if (compressed == null) return null;
      final tempFile = File(
        '${Directory.systemTemp.path}/'
        'pantry_comp_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressed);
      return tempFile.path;
    } on Object catch (e) {
      logWarning('Image compression failed for $sourcePath: $e');
      return null;
    }
  }
}

/// The arguments sent to the background isolate.
class _CompressArgs {
  const _CompressArgs({
    required this.bytes,
    required this.maxBytes,
    required this.maxDimension,
  });

  final Uint8List bytes;
  final int maxBytes;
  final int maxDimension;
}

/// Decodes, downscales, and re-encodes the source bytes as a JPEG within
/// the target byte budget. Returns null when the image cannot be decoded.
Uint8List? _compressBytes(_CompressArgs args) {
  var image = img.decodeImage(args.bytes);
  if (image == null) return null;

  final longestSide = math.max(image.width, image.height);
  if (longestSide > args.maxDimension) {
    image = img.copyResize(image, width: args.maxDimension);
  }

  var quality = 85;
  var output = img.encodeJpg(image, quality: quality);
  while (output.length > args.maxBytes && quality > 40) {
    quality -= 10;
    output = img.encodeJpg(image, quality: quality);
  }

  // Progressive downscale if quality alone cannot reach the target.
  var current = image;
  while (output.length > args.maxBytes &&
      current.width > ProductImageCompressor.minimumDimension) {
    final newWidth = math.max(
      ProductImageCompressor.minimumDimension,
      (current.width * 0.8).round(),
    );
    current = img.copyResize(current, width: newWidth);
    output = img.encodeJpg(current, quality: quality);
  }

  return Uint8List.fromList(output);
}
