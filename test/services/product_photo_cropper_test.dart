import 'dart:io';

import 'package:crop_image/crop_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pantry_app/services/product_photo_cropper.dart';

/// Unit tests for [ProductPhotoCropper].
///
/// A real PNG is decoded and re-encoded through the Flutter engine, and the
/// output dimensions are verified by decoding the produced file with
/// package:image so the crop math is checked without further UI involvement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ProductPhotoCropper cropper;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cropper_test_');
    cropper = ProductPhotoCropper();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createPng(String name, int width, int height) async {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(10, 20, 30));
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(img.encodePng(image));
    return file;
  }

  Future<(int, int)?> decodedSize(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    return (image.width, image.height);
  }

  group('ProductPhotoCropper.crop', () {
    test('full crop with no rotation keeps the source dimensions', () async {
      final source = await createPng('source.png', 100, 50);

      final result = await cropper.crop(
        sourcePath: source.path,
        cropRect: const Rect.fromLTWH(0, 0, 1, 1),
        rotation: CropRotation.up,
        outputDirectory: tempDir,
      );

      expect(result, isNotNull);
      expect(await result!.exists(), isTrue);
      expect(await decodedSize(result), (100, 50));
    });

    test('half-width crop halves the width', () async {
      final source = await createPng('source.png', 100, 50);

      final result = await cropper.crop(
        sourcePath: source.path,
        cropRect: const Rect.fromLTWH(0, 0, 0.5, 1),
        rotation: CropRotation.up,
        outputDirectory: tempDir,
      );

      expect(result, isNotNull);
      expect(await decodedSize(result!), (50, 50));
    });

    test('right rotation swaps the output dimensions', () async {
      final source = await createPng('source.png', 100, 50);

      final result = await cropper.crop(
        sourcePath: source.path,
        cropRect: const Rect.fromLTWH(0, 0, 1, 1),
        rotation: CropRotation.right,
        outputDirectory: tempDir,
      );

      expect(result, isNotNull);
      expect(await decodedSize(result!), (50, 100));
    });

    test('writes the cropped file into the given output directory', () async {
      final source = await createPng('source.png', 80, 60);
      final outDir = Directory('${tempDir.path}/out')
        ..createSync(recursive: true);

      final result = await cropper.crop(
        sourcePath: source.path,
        cropRect: const Rect.fromLTWH(0, 0, 1, 1),
        rotation: CropRotation.up,
        outputDirectory: outDir,
      );

      expect(result, isNotNull);
      expect(
        result!.path,
        startsWith(outDir.path),
        reason: 'The cropped file must be written to the requested directory',
      );
    });

    test('returns null when the source file is missing', () async {
      final result = await cropper.crop(
        sourcePath: '${tempDir.path}/missing.png',
        cropRect: const Rect.fromLTWH(0, 0, 1, 1),
        rotation: CropRotation.up,
        outputDirectory: tempDir,
      );

      expect(result, isNull);
    });

    test('returns null and does not throw for undecodable bytes', () async {
      final garbage = File('${tempDir.path}/garbage.png')
        ..writeAsBytesSync(<int>[1, 2, 3, 4, 5]);

      final result = await cropper.crop(
        sourcePath: garbage.path,
        cropRect: const Rect.fromLTWH(0, 0, 1, 1),
        rotation: CropRotation.up,
        outputDirectory: tempDir,
      );

      expect(result, isNull);
    });

    test('downscales a crop larger than maxSize', () async {
      final source = await createPng('source.png', 4000, 2000);

      final result = await cropper.crop(
        sourcePath: source.path,
        cropRect: const Rect.fromLTWH(0, 0, 1, 1),
        rotation: CropRotation.up,
        maxSize: 800,
        outputDirectory: tempDir,
      );

      expect(result, isNotNull);
      final (width, height) = (await decodedSize(result!))!;
      expect(width, 800);
      expect(height, 400);
    });

    test('minimumDimension matches the OFF minimum used by the compressor', () {
      expect(ProductPhotoCropper.minimumDimension, 640);
    });
  });
}
