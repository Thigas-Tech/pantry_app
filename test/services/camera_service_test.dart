import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/camera_service.dart';

void main() {
  CameraDescription camera(
    String name,
    CameraLensDirection direction, {
    int sensorOrientation = 90,
  }) {
    return CameraDescription(
      name: name,
      lensDirection: direction,
      sensorOrientation: sensorOrientation,
    );
  }

  final back = camera('back', CameraLensDirection.back);
  final front = camera('front', CameraLensDirection.front);
  final external = camera('external', CameraLensDirection.external);

  group('CameraService.selectRearCamera', () {
    test('returns the back camera when one is available', () async {
      final service = CameraService(
        cameras: () async => <CameraDescription>[front, back],
      );

      final selected = await service.selectRearCamera();

      expect(selected, same(back));
    });

    test('prefers the first back camera when several exist', () async {
      final firstBack = camera('back1', CameraLensDirection.back);
      final secondBack = camera('back2', CameraLensDirection.back);
      final service = CameraService(
        cameras: () async => <CameraDescription>[secondBack, front, firstBack],
      );

      final selected = await service.selectRearCamera();

      expect(selected, same(secondBack));
    });

    test('falls back to the first camera when no back lens exists', () async {
      final service = CameraService(
        cameras: () async => <CameraDescription>[front, external],
      );

      final selected = await service.selectRearCamera();

      expect(selected, same(front));
    });

    test('returns null when no camera is available', () async {
      final service = CameraService(cameras: () async => const []);

      final selected = await service.selectRearCamera();

      expect(selected, isNull);
    });
    test('propagates a CameraException from availableCameras', () {
      final service = CameraService(
        cameras: () => throw CameraException('camera_unavailable', 'No camera'),
      );

      expect(service.selectRearCamera(), throwsA(isA<CameraException>()));
    });
  });
}
