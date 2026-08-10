import 'package:camera/camera.dart';

/// Selects a camera device for in-app product photo capture.
///
/// Wraps [availableCameras] so back-lens selection is testable without real
/// camera hardware. The rear lens is preferred because product photos
/// (nutrition table, ingredients, front image) are taken of a physical item.
class CameraService {
  /// Creates a [CameraService].
  ///
  /// [cameras] is injectable for tests; when omitted it delegates to the
  /// plugin's [availableCameras].
  CameraService({Future<List<CameraDescription>> Function()? cameras})
    : _cameras = cameras ?? availableCameras;

  final Future<List<CameraDescription>> Function() _cameras;

  /// Returns the first back-facing camera, or the first available camera when
  /// no rear lens exists, or null when the device has no camera at all.
  ///
  /// Throws a [CameraException] when the platform cannot enumerate cameras.
  Future<CameraDescription?> selectRearCamera() async {
    final cameras = await _cameras();
    if (cameras.isEmpty) return null;
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) return camera;
    }
    return cameras.first;
  }
}
