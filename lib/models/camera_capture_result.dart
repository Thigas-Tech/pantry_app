import 'dart:io';

/// The outcome of the in-app camera capture screen.
sealed class CameraCaptureResult {
  const CameraCaptureResult();
}

/// A photo was captured and normalized.
class CameraCaptured extends CameraCaptureResult {
  /// Creates a [CameraCaptured] for the given [file].
  const CameraCaptured(this.file);

  /// The captured image file.
  final File file;
}

/// The user closed the camera screen without taking a photo.
class CameraCaptureCancelled extends CameraCaptureResult {
  /// Creates a [CameraCaptureCancelled].
  const CameraCaptureCancelled();
}

/// The camera could not be opened on this device.
class CameraCaptureUnavailable extends CameraCaptureResult {
  /// Creates a [CameraCaptureUnavailable].
  const CameraCaptureUnavailable();
}
