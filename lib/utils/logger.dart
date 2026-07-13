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
/// `_verbose` is [kDebugMode] — `true` in debug builds, `false` in release
/// and profile builds. This means [logInfo] and [logDebug] calls are
/// tree-shaken from release binaries entirely.
const bool _verbose = kDebugMode;

// ANSI colour codes.
const _reset = '\x1B[0m';
const _blue = '\x1B[34m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';

String _timestamp() => '[${DateTime.now().toIso8601String()}]';

/// Ring buffer of recent log lines (oldest first).
///
/// Each entry is the plain-text log line with ANSI codes stripped.
/// Used to attach recent logs to feedback submissions.
final List<String> _logBuffer = [];
const _maxLogEntries = 200;

String _stripAnsi(String msg) =>
    msg.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');

/// Returns recent log lines joined by newlines, oldest first.
String get recentLogs => _logBuffer.join('\n');

void _append(String line) {
  _logBuffer.add(_stripAnsi(line));
  if (_logBuffer.length > _maxLogEntries) _logBuffer.removeAt(0);
}

/// Logs a debug-level message (no colour, verbose-only).
///
/// Only printed when [_verbose] is `true` (debug builds).
void logDebug(String message) {
  if (_verbose) {
    final line = '${_timestamp()} [DEBUG] $message';
    debugPrint(line);
    _append(line);
  }
}

/// Logs an informational message (blue).
///
/// Only printed when [_verbose] is `true` (debug builds).
void logInfo(String message) {
  if (_verbose) {
    final line = '${_timestamp()} [INFO] $message';
    debugPrint('${_timestamp()} $_blue[INFO] $_reset$message');
    _append(line);
  }
}

/// Logs a warning message (yellow).
void logWarning(String message) {
  final line = '${_timestamp()} [WARN] $message';
  debugPrint('${_timestamp()} $_yellow[WARN] $_reset$message');
  _append(line);
}

/// Logs an error message (red).
void logError(String message) {
  final line = '${_timestamp()} [ERR]  $message';
  debugPrint('${_timestamp()} $_red[ERR]  $_reset$message');
  _append(line);
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
  final line =
      '${_timestamp()} [ERR]  $message'
      '\n${exception.runtimeType}: $exception$trace';
  debugPrint(
    '${_timestamp()} $_red[ERR]  $_reset$message'
    '\n${exception.runtimeType}: $exception$trace',
  );
  _append(line);
}
