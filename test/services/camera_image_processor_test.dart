import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pantry_app/services/camera_image_processor.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('camera_proc_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writeJpg({required int width, required int height}) async {
    final image = img.Image(width: width, height: height)
      ..clear(img.ColorRgb8(120, 140, 160));
    final bytes = img.encodeJpg(image);
    final file = File('${tempDir.path}/large_$width.jpg');
    await file.writeAsBytes(bytes);
    return file;
  }

  group('CameraImageProcessor.resizeToStandard', () {
    test(
      'downscales a large photo to at most 1600px on the longest side',
      () async {
        final source = await writeJpg(width: 4000, height: 3000);

        final output = await CameraImageProcessor().resizeToStandard(source);

        final decoded = img.decodeImage(await output.readAsBytes());
        expect(decoded, isNotNull);
        expect(
          math.max(decoded!.width, decoded.height),
          lessThanOrEqualTo(1600),
        );
      },
    );

    test('keeps a small photo at its original dimensions', () async {
      final source = await writeJpg(width: 800, height: 600);

      final output = await CameraImageProcessor().resizeToStandard(source);

      final decoded = img.decodeImage(await output.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, 800);
      expect(decoded.height, 600);
    });

    test('returns the original file when the source is missing', () async {
      final missing = File('${tempDir.path}/missing.jpg');

      final output = await CameraImageProcessor().resizeToStandard(missing);

      expect(output, same(missing));
    });

    test(
      'returns the original file when the bytes cannot be decoded',
      () async {
        final undecodable = File('${tempDir.path}/bad.jpg')
          ..writeAsBytesSync(List<int>.filled(64, 7));

        final output = await CameraImageProcessor().resizeToStandard(
          undecodable,
        );

        expect(output, same(undecodable));
      },
    );
  });
}
