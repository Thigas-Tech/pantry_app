import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Manages local notifications for expiry reminders.
///
/// Designed for **Android** (and ready for iOS when that platform is added).
/// Desktop and web are not supported.
///
/// ## Timezone handling
///
/// Scheduled notifications require a timezone‑aware `TZDateTime`. The service
/// loads the IANA timezone database and then attempts to match the device’s
/// local timezone name. If the name is unknown it falls back to UTC.
///
/// ## Notification IDs
///
/// Each inventory item can have up to two scheduled notifications:
/// - ID = `item.id.hashCode`        → “Expiring soon” (1 day before)
/// - ID = `item.id.hashCode + 1`    → “Expiring today” (on the expiry day)
class NotificationService {
  /// Creates a [NotificationService] that uses the given [plugin].
  /// In production code the default [FlutterLocalNotificationsPlugin] is used;
  /// in tests a mock can be injected.
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Initialises the notification plugin.
  ///
  /// Must be called once at app startup, before any notification is
  /// scheduled. The Android icon is `@mipmap/ic_launcher`.
  Future<void> initialize() async {
    logInfo('Initialising notification service');

    tz_data.initializeTimeZones();

    final localTimeZoneName = DateTime.now().timeZoneName;
    logInfo('Detected device timezone name: $localTimeZoneName');
    try {
      tz.setLocalLocation(tz.getLocation(localTimeZoneName));
      logInfo('Timezone set to $localTimeZoneName');
    } on Exception catch (_) {
      tz.setLocalLocation(tz.UTC);
      logWarning('Unknown timezone "$localTimeZoneName", falling back to UTC');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );
      logInfo('Notification plugin initialised successfully');
    } on Exception catch (e) {
      logError('Failed to initialise notification plugin: $e');
    }
  }

  /// Schedules two local notifications for [item].
  Future<void> scheduleExpiryReminders(InventoryItem item) async {
    if (item.expiryDate == null) {
      logInfo('No expiry date for item ${item.id}, skipping reminders');
      return;
    }

    final expiry = DateTime.tryParse(item.expiryDate!);
    if (expiry == null) {
      logWarning('Could not parse expiry date "${item.expiryDate}"');
      return;
    }

    final dayBefore = expiry.subtract(const Duration(days: 1));
    final now = tz.TZDateTime.now(tz.local);
    final id = item.id?.hashCode ?? item.barcode.hashCode;

    // Reminder one day before
    final dayBeforeTZ = tz.TZDateTime.from(dayBefore, tz.local);
    if (dayBeforeTZ.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: 'Expiring soon',
          body: '${item.barcode} expires tomorrow',
          scheduledDate: dayBeforeTZ,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_channel',
              'Expiry reminders',
              channelDescription: 'Warns about expiring food',
              importance: Importance.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        logInfo(
          '''Scheduled "expiring soon" for barcode ${item.barcode} on $dayBeforeTZ''',
        );
      } on Exception catch (e) {
        logError('Failed to schedule "expiring soon" for ${item.barcode}: $e');
      }
    } else {
      logInfo(
        '''Skipping "expiring soon" for ${item.barcode} – date is in the past''',
      );
    }

    // Reminder on expiry day
    final expiryTZ = tz.TZDateTime.from(expiry, tz.local);
    if (expiryTZ.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          id: id + 1,
          title: 'Food expiring today',
          body: '${item.barcode} expires today!',
          scheduledDate: expiryTZ,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_channel',
              'Expiry reminders',
              channelDescription: 'Warns about expiring food',
              importance: Importance.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        logInfo(
          '''Scheduled "expiring today" for barcode ${item.barcode} on $expiryTZ''',
        );
      } on Exception catch (e) {
        logError('Failed to schedule "expiring today" for ${item.barcode}: $e');
      }
    } else {
      logInfo(
        '''Skipping "expiring today" for ${item.barcode} – date is in the past''',
      );
    }
  }

  /// Cancels both notifications associated with the given [itemId].
  Future<void> cancelReminders(int itemId) async {
    logInfo('Cancelling reminders for item $itemId');
    final id = itemId.hashCode;
    try {
      await _plugin.cancel(id: id);
      await _plugin.cancel(id: id + 1);
      logInfo('Reminders cancelled for item $itemId');
    } on Exception catch (e) {
      logError('Failed to cancel reminders for item $itemId: $e');
    }
  }

  /// Requests the `POST_NOTIFICATIONS` permission on Android 13+.
  Future<void> requestPermission() async {
    logInfo('Requesting notification permission');
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    logInfo('Notification permission request completed');
  }
}
