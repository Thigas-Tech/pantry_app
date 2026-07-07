import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/logger.dart';

void main() {
  group('Logger', () {
    test('logInfo prints in debug mode', () {
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        logs.add(message!);
      };

      logInfo('test info message');
      expect(logs, isNotEmpty);
      expect(logs.first, contains('test info message'));
      expect(logs.first, contains('[INFO]'));
    });

    test('logWarning prints a warning message', () {
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        logs.add(message!);
      };

      logWarning('test warning');
      expect(logs, isNotEmpty);
      expect(logs.first, contains('test warning'));
      expect(logs.first, contains('[WARN]'));
    });

    test('logError prints an error message', () {
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        logs.add(message!);
      };

      logError('test error');
      expect(logs, isNotEmpty);
      expect(logs.first, contains('test error'));
      expect(logs.first, contains('[ERR]'));
    });

    test('log functions do not throw', () {
      logInfo('info');
      logWarning('warning');
      logError('error');
    });

    /// Verifies [logDebug] prints in debug mode (when [_verbose] is true).
    test('logDebug prints in debug mode', () {
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        logs.add(message!);
      };

      logDebug('debug message');
      expect(logs, isNotEmpty);
      expect(logs.first, contains('debug message'));
      expect(logs.first, contains('[DEBUG]'));
    });

    /// Verifies [logException] prints the message, exception type, and
    /// stack trace when a [StackTrace] is provided.
    test('logException prints exception with stack trace', () {
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        logs.add(message!);
      };

      final exception = Exception('test failure');
      final stackTrace = StackTrace.current;
      logException('An error occurred', exception, stackTrace);

      expect(logs, isNotEmpty);
      expect(logs.first, contains('An error occurred'));
      expect(logs.first, contains('Exception'));
      expect(logs.first, contains(stackTrace.toString()));
    });

    /// Verifies [logException] handles a null [StackTrace] gracefully.
    test('logException handles null stack trace', () {
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        logs.add(message!);
      };

      logException('Simple error', 'string error', null);

      expect(logs, isNotEmpty);
      expect(logs.first, contains('Simple error'));
    });
  });
}
