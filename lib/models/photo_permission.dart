/// The outcome of requesting a device permission for photo capture.
enum PhotoPermissionStatus {
  /// The user granted the permission.
  granted,

  /// The user denied the permission but can be asked again.
  denied,

  /// The user denied the permission and will not be prompted again.
  permanentlyDenied,
}
