import 'package:flutter/foundation.dart';

/// Wraps [debugPrint] so that log messages are stripped in release mode.
///
/// Use this everywhere you would have used `print` or `debugPrint` directly.
/// The `debugPrint` function already does nothing in release mode, but this
/// utility gives us a single place to add timestamps, log levels, or switch
/// to a proper logging framework later.
const _verbose = true;
void logInfo(String message) {
  if (_verbose) debugPrint('󱂅 $message');
}

void logWarning(String message) {
  debugPrint(' $message');
}

void logError(String message) {
  debugPrint(' $message');
}
