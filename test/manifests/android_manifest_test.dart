import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android security posture in the manifest, which is not
/// exercised by the Dart unit suite. Each assertion is a regression lock
/// for a security audit finding.
void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
  });

  group('Android backups disabled (S5)', () {
    test('declares android:allowBackup="false"', () {
      expect(manifest, contains('android:allowBackup="false"'));
    });
  });

  group('vestigial permissions (S7)', () {
    test('does not declare READ_EXTERNAL_STORAGE', () {
      expect(
        manifest,
        isNot(contains('android.permission.READ_EXTERNAL_STORAGE')),
      );
    });

    test('does not request legacy external storage', () {
      expect(manifest, isNot(contains('requestLegacyExternalStorage')));
    });

    test('does not declare exact-alarm permissions', () {
      expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
      expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    });
  });
}
