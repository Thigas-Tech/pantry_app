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
/// loads the IANA timezone database and then attempts to match the device's
/// local timezone name. If the name is unknown it falls back to UTC.
///
/// ## Notification IDs
///
/// Each inventory item can have up to two scheduled notifications:
/// - ID = `item.id.hashCode`        -> "Expiring soon" (1 day before)
/// - ID = `item.id.hashCode + 1`    -> "Expiring today" (on the expiry day)
///
/// ## Localization
///
/// Notification title and body strings are passed in by callers so they can
/// be localized via `AppLocalizations`. If no strings are provided, English
/// fallback values are used.
class NotificationService {
  /// Creates a [NotificationService] that uses the given [plugin].
  ///
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

    tz.Location location;
    try {
      location = tz.getLocation(localTimeZoneName);
    } on Exception {
      location = _resolveFromOffset(localTimeZoneName);
    }

    tz.setLocalLocation(location);
    logInfo('Timezone set to ${location.name}');

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
  ///
  /// [expiringSoonTitle], [expiringSoonBody], [expiringTodayTitle],
  /// [expiringTodayBody], [channelName], and [channelDescription] can be
  /// passed to localize the notifications. If omitted, English defaults
  /// are used.
  Future<void> scheduleExpiryReminders(
    InventoryItem item, {
    String expiringSoonTitle = 'Expiring soon',
    String expiringSoonBody = '',
    String expiringTodayTitle = 'Food expiring today',
    String expiringTodayBody = '',
    String channelName = 'Expiry reminders',
    String channelDescription = 'Warns about expiring food',
  }) async {
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
        final body = expiringSoonBody.isNotEmpty
            ? expiringSoonBody
            : '${item.barcode} expires tomorrow';
        await _plugin.zonedSchedule(
          id: id,
          title: expiringSoonTitle,
          body: body,
          scheduledDate: dayBeforeTZ,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_channel',
              channelName,
              channelDescription: channelDescription,
              importance: Importance.high,
            ),
            iOS: const DarwinNotificationDetails(),
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
        final body = expiringTodayBody.isNotEmpty
            ? expiringTodayBody
            : '${item.barcode} expires today!';
        await _plugin.zonedSchedule(
          id: id + 1,
          title: expiringTodayTitle,
          body: body,
          scheduledDate: expiryTZ,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_channel',
              channelName,
              channelDescription: channelDescription,
              importance: Importance.high,
            ),
            iOS: const DarwinNotificationDetails(),
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

  /// Handles raw UTC offset strings (e.g. `-03` on Linux desktop) by
  /// returning [tz.UTC].  On Android/iOS the system provides a proper
  /// IANA zone name, so this fallback is rarely hit in production.
  static tz.Location _resolveFromOffset(String name) {
    final match = RegExp(r'^[+-]\d{1,2}$').hasMatch(name);
    if (match) {
      logWarning(
        'Raw UTC offset "$name" detected (common on Linux desktop).'
        ' Falling back to UTC for timezone calculations.',
      );
    } else {
      logWarning('Unknown timezone "$name", falling back to UTC');
    }
    return tz.UTC;
  }
}
