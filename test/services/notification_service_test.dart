import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Tests for [NotificationService].
///
/// This suite verifies that the notification service correctly initialises the
/// plugin, schedules expiry reminders, cancels them, and requests permissions.
/// All native plugin calls are mocked using [Mock], so no real
/// notifications are ever sent during testing.
///
/// The tests follow these key strategies:
/// - A [MockFlutterLocalNotificationsPlugin] is injected into the service
///   to replace the real plugin.
/// - Every plugin method that returns a `Future` is stubbed with
///   `thenAnswer((_) => Future.value())` to avoid `null` being returned
///   (which would cause a type error when `await` is used).
/// - Each test is `async` and uses `await` on the service method before
///   verifying interactions. This ensures all asynchronous operations have
///   completed and the verification sees the full set of calls.
///
/// Fallback values are registered for all matcher arguments that are passed
/// to `any(named: ...)`, so Mocktail can match calls without caring about
/// the concrete values.

// ---------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------

/// Mock implementation of [FlutterLocalNotificationsPlugin].
///
/// Used to verify that the service invokes the correct plugin methods
/// with the expected arguments, without executing any native code.
class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

/// Mock implementation of the Android‑specific plugin interface.
///
/// Used to test permission requests on Android without invoking
/// platform channels.
class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

// ---------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------

void main() {
  // Set up timezone database and a default local timezone (UTC) for the
  // entire test run. This avoids timezone‑related errors when constructing
  // TZDateTime objects inside the service.
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    // Register fallback values so that `any(named: '...')` can be used
    // with the correct type for each parameter.
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    registerFallbackValue(tz.TZDateTime.now(tz.UTC));
    registerFallbackValue(
      const InventoryItem(barcode: '123', expiryDate: '2099-01-01'),
    );
    registerFallbackValue(
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Expiry reminders',
          channelDescription: 'Warns about expiring food',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  // Each test gets a fresh mock plugin and a new service instance to
  // prevent state leaking between tests.
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationService service;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: mockPlugin);
  });

  // -----------------------------------------------------------------
  // Group: initialize
  // -----------------------------------------------------------------

  group('initialize', () {
    test('calls plugin.initialize with correct settings', () async {
      // Arrange: stub the initialize method to return a completed future.
      when(
        () => mockPlugin.initialize(settings: any(named: 'settings')),
      ).thenAnswer((_) => Future.value());

      // Act: call the service method.
      await service.initialize();

      // Assert: verify that initialize was called exactly once,
      // with any settings (the exact content is not important for this test).
      verify(
        () => mockPlugin.initialize(settings: any(named: 'settings')),
      ).called(1);
    });
  });

  // -----------------------------------------------------------------
  // Group: scheduleExpiryReminders
  // -----------------------------------------------------------------

  group('scheduleExpiryReminders', () {
    test('skips when expiryDate is null', () async {
      // Arrange: an item without an expiry date.
      const item = InventoryItem(barcode: '123');

      // Act: schedule reminders for that item.
      await service.scheduleExpiryReminders(item);

      // Assert: no zonedSchedule calls should have been made.
      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
        ),
      );
    });

    test(
      'schedules two notifications when both dates are in the future',
      () async {
        // Arrange: stub zonedSchedule to return a completed future.
        // This is crucial: without this stub, the method would return `null`
        // and `await` would fail with a type error. The stub ensures the
        // method can be awaited and the second call can be reached.
        when(
          () => mockPlugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
          ),
        ).thenAnswer((_) => Future.value());

        // Create an item whose expiry date is 10 days from now
        // (both the 1‑day‑before reminder and
        // the expiry‑day reminder should be scheduled).
        final expiry = DateTime.now().add(const Duration(days: 10));
        const item = InventoryItem(barcode: '123', id: 1);
        final itemWithExpiry = item.copyWith(
          expiryDate: expiry.toIso8601String().substring(0, 10),
        );

        // Act: schedule reminders.
        await service.scheduleExpiryReminders(itemWithExpiry);

        // Assert: verify that zonedSchedule was called exactly two times
        // (once for each reminder). The exact IDs, titles, etc. are matched
        // using `any()` because we only care about the count.
        verify(
          () => mockPlugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
          ),
        ).called(2);
      },
    );
  });

  // -----------------------------------------------------------------
  // Group: cancelReminders
  // -----------------------------------------------------------------

  group('cancelReminders', () {
    test('cancels two notification IDs', () async {
      // Arrange: stub cancel to return a completed future.
      when(
        () => mockPlugin.cancel(id: any(named: 'id')),
      ).thenAnswer((_) => Future.value());

      // Act: cancel reminders for an item id.
      await service.cancelReminders(42);

      // Assert: verify that cancel was called exactly twice.
      verify(() => mockPlugin.cancel(id: any(named: 'id'))).called(2);
    });
  });

  // -----------------------------------------------------------------
  // Group: requestPermission
  // -----------------------------------------------------------------

  group('requestPermission', () {
    test('calls requestNotificationsPermission on Android', () async {
      // Arrange: create a mock Android plugin and stub the resolution
      // and the permission request.
      final mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroidPlugin);
      when(
        mockAndroidPlugin.requestNotificationsPermission,
      ).thenAnswer((_) => Future.value());

      // Act: request permission.
      await service.requestPermission();

      // Assert: verify that the permission request was made exactly once.
      verify(mockAndroidPlugin.requestNotificationsPermission).called(1);
    });
  });
}
