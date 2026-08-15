import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/config.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  group('AppConfig', () {
    /// Verifies OFF_USER_ID returns empty string when not configured.
    test('returns empty string for missing OFF_USER_ID', () {
      expect(AppConfig.offUserId, '');
    });

    test('returns empty string for missing OFF_PASSWORD', () {
      expect(AppConfig.offPassword, '');
    });

    test('returns empty string for missing USDA_API_KEY', () {
      expect(AppConfig.usdaApiKey, '');
    });

    /// Verifies missing CONTACT_EMAIL returns the default email.
    test('returns default email for missing CONTACT_EMAIL', () {
      expect(AppConfig.contactEmail, 'pantry-app@example.com');
    });

    test('returns false for missing USE_OFF_STAGING', () {
      expect(AppConfig.useOffStaging, false);
    });

    test('reads values from environment', () {
      dotenv.loadFromString(
        isOptional: true,
        mergeWith: {
          'OFF_USER_ID': 'testuser',
          'OFF_PASSWORD': 'secret',
          'CONTACT_EMAIL': 'dev@test.com',
          'USE_OFF_STAGING': 'true',
          'USDA_API_KEY': 'usda-key',
        },
      );

      expect(AppConfig.offUserId, 'testuser');
      expect(AppConfig.offPassword, 'secret');
      expect(AppConfig.contactEmail, 'dev@test.com');
      expect(AppConfig.useOffStaging, true);
      expect(AppConfig.usdaApiKey, 'usda-key');
    });
  });
}
