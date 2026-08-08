/// @file ProductImageCompressor unit tests.
///
/// Verifies that camera photos (which can be 3-10 MB) are re-encoded before
/// upload to Open Food Facts, targeting under 1 MB per image while never
/// dropping below the OFF minimum image dimension. Covers the success path,
/// dimension and aspect-ratio guarantees, and the fallback-to-original
/// paths.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pantry_app/services/product_image_compressor.dart';

void main() {
  late Directory tempDir;
  late ProductImageCompressor compressor;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pantry_comp_');
    compressor = ProductImageCompressor();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  /// Writes a noisy JPEG of the given size. Noise compresses poorly, so the
  /// file is reliably larger than the 1 MB target.
  File noisyJpeg({int width = 2000, int height = 2000}) {
    final image = img.Image(width: width, height: height);
    final rng = math.Random(42);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        image.setPixelRgb(
          x,
          y,
          rng.nextInt(256),
          rng.nextInt(256),
          rng.nextInt(256),
        );
      }
    }
    return File('${tempDir.path}/noisy.jpg')
      ..writeAsBytesSync(img.encodeJpg(image));
  }

  group('ProductImageCompressor', () {
    test('compresses a large JPEG to under 1 MB', () async {
      final file = noisyJpeg();
      expect(
        await file.length(),
        greaterThan(ProductImageCompressor.defaultMaxBytes),
      );

      final path = await compressor.compress(sourcePath: file.path);
      expect(path, isNotNull);

      final compressed = File(path!);
      addTearDown(compressed.deleteSync);
      expect(
        await compressed.length(),
        lessThan(ProductImageCompressor.defaultMaxBytes),
      );
    });

    test('keeps dimensions at or above the OFF minimum', () async {
      final file = noisyJpeg();
      final path = await compressor.compress(sourcePath: file.path);
      expect(path, isNotNull);

      final compressed = File(path!);
      addTearDown(compressed.deleteSync);
      final decoded = img.decodeImage(await compressed.readAsBytes());
      expect(decoded, isNotNull);
      expect(
        decoded!.width,
        greaterThanOrEqualTo(ProductImageCompressor.minimumDimension),
      );
      expect(
        decoded.height,
        greaterThanOrEqualTo(ProductImageCompressor.minimumDimension),
      );
    });

    test('preserves aspect ratio', () async {
      final file = noisyJpeg(height: 1000);
      final path = await compressor.compress(sourcePath: file.path);
      expect(path, isNotNull);

      final compressed = File(path!);
      addTearDown(compressed.deleteSync);
      final decoded = img.decodeImage(await compressed.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width / decoded.height, closeTo(2.0, 0.05));
    });

    test('returns null when the file is already under the limit', () async {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(10, 10, 10));
      final file = File('${tempDir.path}/small.jpg')
        ..writeAsBytesSync(img.encodeJpg(image));
      expect(
        await file.length(),
        lessThan(ProductImageCompressor.defaultMaxBytes),
      );

      final path = await compressor.compress(sourcePath: file.path);
      expect(path, isNull);
    });

    test('returns null when the file cannot be decoded', () async {
      final file = File('${tempDir.path}/bad.jpg')
        ..writeAsBytesSync(List<int>.filled(100, 0));

      final path = await compressor.compress(sourcePath: file.path);
      expect(path, isNull);
    });

    test('returns null when the file does not exist', () async {
      final path = await compressor.compress(
        sourcePath: '${tempDir.path}/missing.jpg',
      );
      expect(path, isNull);
    });
  });
}
