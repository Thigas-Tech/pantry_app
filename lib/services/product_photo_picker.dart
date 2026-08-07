import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry_app/models/photo_permission.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:permission_handler/permission_handler.dart';

/// Picks product photos from the camera or the device gallery.
///
/// Requests the camera permission for camera sources and compresses the
/// picked image so uploads to Open Food Facts stay small. Gallery picks go
/// through the system picker and only request a permission when the platform
/// requires one.
class ProductPhotoPicker {
  /// Creates a [ProductPhotoPicker].
  ///
  /// [imagePicker], [cameraPermissionCheck], [galleryPermissionCheck], and
  /// [isGalleryPermissionRequired] are injectable for tests.
  ProductPhotoPicker({
    ImagePicker? imagePicker,
    Future<PhotoPermissionStatus> Function()? cameraPermissionCheck,
    Future<PhotoPermissionStatus> Function()? galleryPermissionCheck,
    bool Function()? isGalleryPermissionRequired,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _cameraPermissionCheck =
           cameraPermissionCheck ?? _requestCameraPermission,
       _galleryPermissionCheck =
           galleryPermissionCheck ?? _requestGalleryPermission,
       _isGalleryPermissionRequired =
           isGalleryPermissionRequired ?? _isGalleryPermissionRequiredDefault;

  final ImagePicker _imagePicker;
  final Future<PhotoPermissionStatus> Function() _cameraPermissionCheck;
  final Future<PhotoPermissionStatus> Function() _galleryPermissionCheck;
  final bool Function() _isGalleryPermissionRequired;

  /// Asks the user for camera access and maps the outcome.
  static Future<PhotoPermissionStatus> _requestCameraPermission() async {
    return _mapStatus(await Permission.camera.request());
  }

  /// Asks the user for photo-library access and maps the outcome.
  static Future<PhotoPermissionStatus> _requestGalleryPermission() async {
    return _mapStatus(await Permission.photos.request());
  }

  /// Whether an explicit gallery permission request is required.
  ///
  /// The system photo picker (Android 13+), ACTION_GET_CONTENT (older
  /// Android), and PHPicker (iOS) grant access without a permission, so the
  /// default is false on the supported platforms.
  static bool _isGalleryPermissionRequiredDefault() => false;

  static PhotoPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted) {
      return PhotoPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return PhotoPermissionStatus.permanentlyDenied;
    }
    return PhotoPermissionStatus.denied;
  }

  /// Picks a photo from the given [source].
  ///
  /// Returns a [PhotoPicked] with the chosen file, a [PhotoPermissionDenied]
  /// when the camera permission is refused (permanentlyDenied is true when
  /// the user cannot be prompted again), a [PhotoGalleryPermissionDenied]
  /// when gallery access is denied, or a [PhotoPickCancelled] when the user
  /// dismisses the picker.
  Future<PhotoPickResult> pick(PhotoSource source) async {
    if (source == PhotoSource.camera) {
      final status = await _cameraPermissionCheck();
      if (status != PhotoPermissionStatus.granted) {
        return PhotoPermissionDenied(
          permanentlyDenied: status == PhotoPermissionStatus.permanentlyDenied,
        );
      }
      return _pickImage(ImageSource.camera);
    }
    if (_isGalleryPermissionRequired()) {
      final status = await _galleryPermissionCheck();
      if (status != PhotoPermissionStatus.granted) {
        return const PhotoGalleryPermissionDenied();
      }
    }
    try {
      return await _pickImage(ImageSource.gallery);
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        return const PhotoGalleryPermissionDenied();
      }
      rethrow;
    }
  }

  Future<PhotoPickResult> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
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
