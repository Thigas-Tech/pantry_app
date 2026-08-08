/// @file Redaction unit tests.
///
/// Verifies that [redactSensitive] replaces the configured Open Food Facts
/// password so SDK exception messages and error logs never leak credentials.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/redaction.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  group('redactSensitive', () {
    test('replaces the configured OFF password', () {
      dotenv.loadFromString(
        isOptional: true,
        mergeWith: {
          'OFF_USER_ID': 'testuser',
          'OFF_PASSWORD': 'SUPER-SECRET',
        },
      );

      final redacted = redactSensitive(
        'Save failed with body: SUPER-SECRET in the response',
      );
      expect(redacted, isNot(contains('SUPER-SECRET')));
      expect(redacted, contains('[redacted]'));
    });

    test('returns the message unchanged when no password is configured', () {
      const message = 'a harmless error message';
      expect(redactSensitive(message), message);
    });

    test('leaves messages without the password untouched', () {
      dotenv.loadFromString(
        isOptional: true,
        mergeWith: {'OFF_PASSWORD': 'SUPER-SECRET'},
      );

      const message = 'Product 001 rejected';
      expect(redactSensitive(message), message);
    });
  });
}
