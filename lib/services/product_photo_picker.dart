import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:permission_handler/permission_handler.dart';

/// Picks product photos from the camera or the device gallery.
///
/// Requests the camera permission for camera sources and compresses the
/// picked image so uploads to Open Food Facts stay small. Gallery picks go
/// through the system picker and never request the camera permission.
class ProductPhotoPicker {
  /// Creates a [ProductPhotoPicker].
  ///
  /// [imagePicker] and [cameraPermissionCheck] are injectable for tests.
  ProductPhotoPicker({
    ImagePicker? imagePicker,
    Future<bool> Function()? cameraPermissionCheck,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _cameraPermissionCheck =
           cameraPermissionCheck ?? _requestCameraPermission;

  final ImagePicker _imagePicker;
  final Future<bool> Function() _cameraPermissionCheck;

  /// Asks the user for camera access and returns true when granted.
  static Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Picks a photo from the given [source].
  ///
  /// Returns a [PhotoPicked] with the chosen file, a
  /// [PhotoPermissionDenied] when the camera permission is refused, or a
  /// [PhotoPickCancelled] when the user dismisses the picker.
  Future<PhotoPickResult> pick(PhotoSource source) async {
    if (source == PhotoSource.camera) {
      final granted = await _cameraPermissionCheck();
      if (!granted) {
        return const PhotoPermissionDenied();
      }
    }
    final picked = await _imagePicker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) {
      return const PhotoPickCancelled();
    }
    return PhotoPicked(File(picked.path));
  }
}
