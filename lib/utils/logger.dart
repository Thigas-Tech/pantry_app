import 'package:flutter/foundation.dart';

/// A lightweight logger with coloured output for terminal visibility.
///
/// - Debug messages are uncolored (shown only in debug builds).
/// - Info messages are shown in **blue** (shown only in debug builds).
/// - Warnings in **yellow** (always printed).
/// - Errors in **red** (always printed).
///
/// Colours use ANSI escape codes which work in most terminals. On platforms
/// that do not support ANSI colours the messages still print normally.
///
/// `_verbose` is `kDebugMode` — `true` in debug builds, `false` in release
/// and profile builds. This means [logInfo] and [logDebug] calls are
/// tree-shaken from release binaries entirely.
const bool _verbose = kDebugMode;

// ANSI colour codes.
const _reset = '\x1B[0m';
const _blue = '\x1B[34m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';

String _timestamp() => '[${DateTime.now().toIso8601String()}]';

/// Logs a debug-level message (no colour, verbose-only).
///
/// Only printed when [_verbose] is `true` (debug builds).
void logDebug(String message) {
  if (_verbose) debugPrint('${_timestamp()} [DEBUG] $message');
}

/// Logs an informational message (blue).
///
/// Only printed when [_verbose] is `true` (debug builds).
void logInfo(String message) {
  if (_verbose) debugPrint('${_timestamp()} $_blue[INFO] $_reset$message');
}

/// Logs a warning message (yellow).
void logWarning(String message) {
  debugPrint('${_timestamp()} $_yellow[WARN] $_reset$message');
}

/// Logs an error message (red).
void logError(String message) {
  debugPrint('${_timestamp()} $_red[ERR]  $_reset$message');
}

/// Logs an error with an optional [exception] and [stackTrace].
///
/// The exception type and message are printed inline, followed by the stack
/// trace on subsequent lines. Always printed regardless of build mode.
void logException(
  String message,
  Object? exception,
  StackTrace? stackTrace,
) {
  final trace = stackTrace != null ? '\n$stackTrace' : '';
  debugPrint(
    '${_timestamp()} $_red[ERR]  $_reset$message'
    '\n${exception.runtimeType}: $exception$trace',
  );
}
