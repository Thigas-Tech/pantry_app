import 'dart:io';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:pantry_app/services/product_image_compressor.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:path/path.dart' as p;

/// Produces cropped and rotated copies of local product photos.
///
/// The pixel work is delegated to [CropController.getCroppedBitmap] so the
/// output is guaranteed to match the crop grid and rotation shown by the
/// [CropImage] widget in the crop screen. The cropped bitmap is encoded as a
/// JPEG in a background isolate (following the same pattern as
/// [ProductImageCompressor]) and written to the caller-provided directory
/// (system temp by default); the source file is left untouched so cropping is
/// non-destructive and can be re-run.
///
/// The decode and the crop canvas are main-isolate operations because
/// [ui.Image] objects cannot cross into a background isolate; the crop screen
/// has already decoded the image for display, so the extra decode here is a
/// single transient cost at apply time.
class ProductPhotoCropper {
  /// The smallest allowed side length in pixels, matching the OFF minimum
  /// used by [ProductImageCompressor].
  static const int minimumDimension = 640;

  /// Crops [sourcePath] to [cropRect] with [rotation] and returns the new
  /// file, or null when the source is missing or cannot be processed.
  ///
  /// [cropRect] is normalized between 0 and 1 in the displayed (post-rotation)
  /// coordinate space, exactly as reported by [CropController.crop]. The
  /// output is downscaled so its longest side never exceeds [maxSize], and is
  /// written into [outputDirectory] (system temp when omitted). The caller
  /// owns the returned file and must delete it once it has been copied into
  /// its managed slot.
  Future<File?> crop({
    required String sourcePath,
    required Rect cropRect,
    required CropRotation rotation,
    double maxSize = 1600,
    Directory? outputDirectory,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final bytes = await source.readAsBytes();
    ui.Image? image;
    ui.Image? cropped;
    try {
      image = await decodeImageFromList(bytes);
      cropped = await CropController.getCroppedBitmap(
        image: image,
        crop: cropRect,
        rotation: rotation,
        maxSize: maxSize,
      );
      final raw = await cropped.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (raw == null) return null;
      final jpeg = await compute(
        _encodeJpeg,
        _EncodeArgs(
          rgba: raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes),
          width: cropped.width,
          height: cropped.height,
          quality: 92,
        ),
      );
      if (jpeg == null) return null;
      final dir = outputDirectory ?? Directory.systemTemp;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final out = File(
        p.join(
          dir.path,
          'crop_${DateTime.now().microsecondsSinceEpoch}.jpg',
        ),
      );
      await out.writeAsBytes(jpeg, flush: true);
      return out;
    } on Object catch (e) {
      logWarning('Crop failed for $sourcePath: $e');
      return null;
    } finally {
      image?.dispose();
      cropped?.dispose();
    }
  }
}

/// The arguments sent to the background isolate.
class _EncodeArgs {
  const _EncodeArgs({
    required this.rgba,
    required this.width,
    required this.height,
    required this.quality,
  });

  final Uint8List rgba;
  final int width;
  final int height;
  final int quality;
}

/// Encodes the raw RGBA pixels as a JPEG. Returns null on any failure.
Uint8List? _encodeJpeg(_EncodeArgs args) {
  try {
    final image = img.Image.fromBytes(
      width: args.width,
      height: args.height,
      bytes: args.rgba.buffer,
      bytesOffset: args.rgba.offsetInBytes,
      order: img.ChannelOrder.rgba,
    );
    return img.encodeJpg(image, quality: args.quality);
  } on Object {
    return null;
  }
}
