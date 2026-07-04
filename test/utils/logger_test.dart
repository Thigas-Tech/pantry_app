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
  });
}
