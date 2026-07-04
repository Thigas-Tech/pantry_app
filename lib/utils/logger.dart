import 'package:flutter/foundation.dart';

/// A lightweight logger with coloured output for terminal visibility.
///
/// - Info messages are shown in **blue**.
/// - Warnings in **yellow**.
/// - Errors in **red**.
///
/// Colours use ANSI escape codes which work in most terminals. On platforms
/// that do not support ANSI colours the messages still print normally.
///
/// Set `_verbose` to `false` to silence info‑level logs in debug mode.
/// Warnings and errors are always printed.
const _verbose = true;

// ANSI colour codes.
const _reset = '\x1B[0m';
const _blue = '\x1B[34m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';

/// Logs an informational message (blue).
void logInfo(String message) {
  if (_verbose) debugPrint('$_blue[INFO] $_reset$message');
}

/// Logs a warning message (yellow).
void logWarning(String message) {
  debugPrint('$_yellow[WARN] $_reset$message');
}

/// Logs an error message (red).
void logError(String message) {
  debugPrint('$_red[ERR]  $_reset$message');
}
