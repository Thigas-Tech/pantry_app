import 'package:flutter/foundation.dart';

/// Wraps [debugPrint] so that log messages are stripped in release mode.
///
/// Use this everywhere you would have used `print` or `debugPrint` directly.
/// The `debugPrint` function already does nothing in release mode, but this
/// utility gives us a single place to add timestamps, log levels, or switch
/// to a proper logging framework later.

/// Set to `false` to silence all info-level logs even in debug mode.
///
/// Warning and error logs are always printed in debug mode regardless of
/// this flag.
const _verbose = true;

/// Logs an informational message.
///
/// Shown only in debug mode and only when `_verbose` is `true`.
/// Use this for normal operational messages (e.g. "Barcode scanned: 123").
void logInfo(String message) {
  if (_verbose) debugPrint('󱂅 $message');
}

/// Logs a warning message.
///
/// Always shown in debug mode, even when `_verbose` is `false`.
/// Use this for recoverable issues (e.g. "Product not found, redirecting").
void logWarning(String message) {
  debugPrint(' $message');
}

/// Logs an error message.
///
/// Always shown in debug mode, even when `_verbose` is `false`.
/// Use this for exceptions and failures (e.g. "Network error: timeout").
void logError(String message) {
  debugPrint(' $message');
}
