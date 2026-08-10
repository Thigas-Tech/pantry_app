import 'dart:io';

/// The outcome of attempting to pick a product photo.
sealed class PhotoPickResult {
  const PhotoPickResult();
}

/// A photo was successfully picked.
class PhotoPicked extends PhotoPickResult {
  /// Creates a [PhotoPicked] for the given [file].
  const PhotoPicked(this.file);

  /// The picked image file.
  final File file;
}

/// The user denied the camera permission request.
class PhotoPermissionDenied extends PhotoPickResult {
  /// Creates a [PhotoPermissionDenied].
  ///
  /// [permanentlyDenied] is true when the user cannot be prompted again and
  /// must grant access from the system settings.
  const PhotoPermissionDenied({this.permanentlyDenied = false});

  /// Whether the denial is permanent and requires the system settings.
  final bool permanentlyDenied;
}

/// The user denied gallery access or the picker reported it as denied.
class PhotoGalleryPermissionDenied extends PhotoPickResult {
  /// Creates a [PhotoGalleryPermissionDenied].
  const PhotoGalleryPermissionDenied();
}

/// The user cancelled the picker without choosing a photo.
class PhotoPickCancelled extends PhotoPickResult {
  /// Creates a [PhotoPickCancelled].
  const PhotoPickCancelled();
}

/// No usable camera could be opened on the device.
///
/// This is distinct from a permission denial: the camera permission was
/// granted but no camera device is available or the camera failed to
/// initialize.
class PhotoCameraUnavailable extends PhotoPickResult {
  /// Creates a [PhotoCameraUnavailable].
  const PhotoCameraUnavailable();
}
