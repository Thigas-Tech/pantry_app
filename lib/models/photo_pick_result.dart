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

/// The user denied the camera (or gallery) permission request.
class PhotoPermissionDenied extends PhotoPickResult {
  /// Creates a [PhotoPermissionDenied].
  const PhotoPermissionDenied();
}

/// The user cancelled the picker without choosing a photo.
class PhotoPickCancelled extends PhotoPickResult {
  /// Creates a [PhotoPickCancelled].
  const PhotoPickCancelled();
}
