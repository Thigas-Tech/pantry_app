/// Placeholder tests for [NotificationService].
///
/// The current static design makes it difficult to mock the platform
/// plugin without dependency injection. These tests are skipped until
/// the service is refactored to accept a configurable plugin instance.
library;
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  /// The static plugin cannot be replaced in the current design, so
  /// the real initialisation path would try to communicate with the
  /// native side and fail. These tests are skipped until DI is added.
  test('initialize does not throw', () async {
    expect(NotificationService.initialize(), completes);
  }, skip: true);

  test('requestPermission does not throw', () async {
    expect(NotificationService.requestPermission(), completes);
  }, skip: true);
}
