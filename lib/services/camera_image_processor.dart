import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pantry_app/utils/logger.dart';

/// Normalizes an in-app camera capture to the same constraints the old
/// image_picker path applied at pick time: at most 1600 px on the longest
/// side, re-encoded as JPEG at quality 85.
///
/// This keeps stored product photos and Open Food Facts uploads small. The
/// decode/encode runs in a background isolate via [compute] so the UI thread
/// is not blocked.
class CameraImageProcessor {
  /// The maximum side length in pixels after resizing.
  static const int maxDimension = 1600;

  /// The JPEG encoding quality, matching the previous picker compression.
  static const int quality = 85;

  /// Re-encodes [source] as a JPEG of at most [maxDimension] px and returns
  /// the resulting file.
  ///
  /// Returns [source] unchanged when it is missing or cannot be decoded, so a
  /// failed capture never breaks the form.
  Future<File> resizeToStandard(File source) async {
    if (!await source.exists()) return source;
    try {
      final bytes = await source.readAsBytes();
      final resized = await compute(_resizeBytes, bytes);
      if (resized == null) return source;
      await source.writeAsBytes(resized, flush: true);
      return source;
    } on Object catch (e) {
      logWarning('Camera photo resize failed for ${source.path}: $e');
      return source;
    }
  }
}

/// Decodes, downscales, and re-encodes [bytes] as a JPEG. Returns null when
/// the bytes cannot be decoded.
Uint8List? _resizeBytes(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return null;
  final longestSide = math.max(image.width, image.height);
  final resized = longestSide > CameraImageProcessor.maxDimension
      ? img.copyResize(image, width: CameraImageProcessor.maxDimension)
      : image;
  return Uint8List.fromList(
    img.encodeJpg(resized, quality: CameraImageProcessor.quality),
  );
}
