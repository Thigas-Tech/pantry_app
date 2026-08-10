import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry_app/models/camera_capture_result.dart';
import 'package:pantry_app/models/photo_permission.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/screens/camera_capture_screen.dart';
import 'package:pantry_app/services/camera_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/navigator_key.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:permission_handler/permission_handler.dart';

/// Picks product photos from the camera or the device gallery.
///
/// Camera picks open an in-app preview ([CameraCaptureScreen]) on platforms
/// with a `camera` plugin implementation (Android, iOS, web) so the rear lens
/// can be selected deterministically. On other platforms they fall back to the
/// system camera app via image_picker. Camera picks first request the camera
/// permission. Gallery picks go through the system picker and only request a
/// permission when the platform requires one.
///
/// Captured and picked images are constrained so Open Food Facts uploads stay
/// small: in-app captures are resized to 1600 x 1600 px at quality 85, and
/// image_picker picks apply the same limits at pick time.
class ProductPhotoPicker {
  /// Creates a [ProductPhotoPicker].
  ///
  /// [imagePicker], [cameraPermissionCheck], [galleryPermissionCheck],
  /// [isGalleryPermissionRequired], and [cameraCapture] are injectable for
  /// tests. [cameraCapture] drives the in-app camera flow and defaults to a
  /// real implementation that selects the rear lens and pushes
  /// [CameraCaptureScreen].
  ProductPhotoPicker({
    ImagePicker? imagePicker,
    Future<PhotoPermissionStatus> Function()? cameraPermissionCheck,
    Future<PhotoPermissionStatus> Function()? galleryPermissionCheck,
    bool Function()? isGalleryPermissionRequired,
    Future<CameraCaptureResult> Function()? cameraCapture,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _cameraPermissionCheck =
           cameraPermissionCheck ?? _requestCameraPermission,
       _galleryPermissionCheck =
           galleryPermissionCheck ?? _requestGalleryPermission,
       _isGalleryPermissionRequired =
           isGalleryPermissionRequired ?? _isGalleryPermissionRequiredDefault,
       _cameraCapture = cameraCapture ?? _captureWithInAppCamera;

  final ImagePicker _imagePicker;
  final Future<PhotoPermissionStatus> Function() _cameraPermissionCheck;
  final Future<PhotoPermissionStatus> Function() _galleryPermissionCheck;
  final bool Function() _isGalleryPermissionRequired;
  final Future<CameraCaptureResult> Function() _cameraCapture;

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

  /// Whether the `camera` plugin supports in-app capture on this platform.
  ///
  /// The plugin has no desktop implementation, so desktop keeps delegating to
  /// the system camera app.
  static bool get _supportsInAppCamera =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

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
  /// when gallery access is denied, a [PhotoCameraUnavailable] when no camera
  /// can be opened, or a [PhotoPickCancelled] when the user dismisses the
  /// picker.
  Future<PhotoPickResult> pick(PhotoSource source) async {
    if (source == PhotoSource.camera) {
      final status = await _cameraPermissionCheck();
      if (status != PhotoPermissionStatus.granted) {
        return PhotoPermissionDenied(
          permanentlyDenied: status == PhotoPermissionStatus.permanentlyDenied,
        );
      }
      if (_supportsInAppCamera) {
        return _captureFromInAppCamera();
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

  /// Maps an in-app camera capture to a [PhotoPickResult].
  Future<PhotoPickResult> _captureFromInAppCamera() async {
    final result = await _cameraCapture();
    return switch (result) {
      CameraCaptured(:final file) => PhotoPicked(file),
      CameraCaptureCancelled() => const PhotoPickCancelled(),
      CameraCaptureUnavailable() => const PhotoCameraUnavailable(),
    };
  }

  /// Opens the in-app camera with the rear lens and returns its result.
  ///
  /// Returns [CameraCaptureUnavailable] when no camera device exists or no
  /// navigator context is available.
  static Future<CameraCaptureResult> _captureWithInAppCamera() async {
    final camera = await CameraService().selectRearCamera();
    if (camera == null) {
      logWarning('No camera available for product photo capture');
      return const CameraCaptureUnavailable();
    }
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      logWarning('No navigator context for product photo capture');
      return const CameraCaptureUnavailable();
    }
    logInfo('Opening in-app camera with rear lens: ${camera.name}');
    return await Navigator.of(context).push<CameraCaptureResult>(
          MaterialPageRoute<CameraCaptureResult>(
            builder: (_) => CameraCaptureScreen(camera: camera),
          ),
        ) ??
        const CameraCaptureCancelled();
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
