import 'package:flutter/foundation.dart';

/// A simple convenience getter that returns `true` when the app is running on
/// a mobile platform (Android or iOS).
///
/// ## Why this exists
///
/// Several parts of the app need to gate functionality that is only available
/// on physical mobile devices:
///
/// - **Barcode scanning** – the camera scanner only works on Android / iOS.
/// - **Local notifications** – the `flutter_local_notifications` plugin is
///   mobile‑only; scheduling on desktop would throw an error.
/// - **SQLite backend** – on desktop `sqflite_common_ffi` must be enabled,
///   whereas on mobile the default `sqflite` factory is used.
///
/// Centralising this check in a single getter makes the code easier to
/// maintain and ensures consistency across the app. If the app ever supports
/// web or other platforms, only this file needs to be updated.
///
/// ## Usage
///
/// ```dart
/// if (isMobile) {
///   // initialise mobile‑only plugin
/// }
/// ```
///
/// The getter compares [defaultTargetPlatform] against the two mobile
/// constants. It does **not** account for Fuchsia or other future platforms;
/// those are implicitly treated as non‑mobile.
bool get isMobile =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
