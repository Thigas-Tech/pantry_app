import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/utils/platform_utils.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Manages local notifications for expiry reminders.
///
/// All methods are **static** because the service is a stateless singleton
/// that wraps the `flutter_local_notifications` plugin. There is no instance
/// state – the plugin itself holds the native resources.
///
/// ## Platform support
///
/// - **Android & iOS**: full functionality – notifications are scheduled for
///   one day before and on the expiry date.
/// - **Desktop** (Linux / macOS / Windows): all public methods are no‑ops.
///   The `isMobile` check (from `platform_utils.dart`) gates every operation.
///
/// ## Timezone handling
///
/// Scheduled notifications require a timezone‑aware `TZDateTime`. The service
/// loads the IANA timezone database and then attempts to match the device’s
/// local timezone name (obtained from `DateTime.now().timeZoneName`). If the
/// name is unknown – which can happen on some Android devices – it falls back
/// to UTC. This means notifications may fire at the wrong wall‑clock time on
/// those rare devices. A future improvement could use `flutter_timezone` to
/// obtain a reliable timezone ID.
///
/// ## Notification IDs
///
/// Each inventory item can have up to two scheduled notifications:
/// - ID = `item.id.hashCode`        → “Expiring soon” (1 day before)
/// - ID = `item.id.hashCode + 1`    → “Expiring today” (on the expiry day)
///
/// If the item has no `id` (e.g. a newly created item before insertion),
/// the barcode’s hash code is used as a fallback. When an item is deleted,
/// both IDs are cancelled via [cancelReminders].
class NotificationService {
  /// The plugin instance. All operations go through this object.
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Initialises the notification plugin.
  ///
  /// Must be called once at app startup, before any notification is
  /// scheduled. On desktop platforms this method returns immediately.
  ///
  /// The Android initialisation uses `@mipmap/ic_launcher` as the notification
  /// icon (the default Flutter launcher icon). iOS settings request alert,
  /// badge, and sound permissions.
  static Future<void> initialize() async {
    if (!isMobile) return;

    // Load the IANA timezone database bundled with the `timezone` package.
    tz_data.initializeTimeZones();

    // Attempt to detect the local timezone from the system clock.
    // `DateTime.now().timeZoneName` returns an abbreviated name like "CET"
    // or "America/New_York". The `timezone` package can resolve most of
    // these, but some Android firmwares return non‑standard abbreviations.
    final localTimeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(localTimeZoneName));
    } catch (_) {
      // Fall back to UTC – notifications will still fire, but at the wrong
      // local time on devices with unrecognised timezone names.
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  /// Schedules two local notifications for [item]:
  /// - One day before the expiry date.
  /// - On the expiry date itself.
  ///
  /// If [item.expiryDate] is `null` or cannot be parsed, this method does
  /// nothing. Notifications whose scheduled date is already in the past are
  /// silently skipped.
  ///
  /// The notification body currently shows the barcode. A future improvement
  /// could include the product name by looking it up in the cache.
  static Future<void> scheduleExpiryReminders(InventoryItem item) async {
    if (!isMobile || item.expiryDate == null) return;
    final expiry = DateTime.tryParse(item.expiryDate!);
    if (expiry == null) return;

    final dayBefore = expiry.subtract(const Duration(days: 1));
    final now = tz.TZDateTime.now(tz.local);
    final id = item.id?.hashCode ?? item.barcode.hashCode;

    // Reminder one day before
    final dayBeforeTZ = tz.TZDateTime.from(dayBefore, tz.local);
    if (dayBeforeTZ.isAfter(now)) {
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
    }

    // Reminder on expiry day
    final expiryTZ = tz.TZDateTime.from(expiry, tz.local);
    if (expiryTZ.isAfter(now)) {
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
    }
  }

  /// Cancels both notifications associated with the given [itemId].
  ///
  /// Call this when an inventory item is deleted or its expiry date is
  /// changed. The method cancels the two IDs derived from `itemId.hashCode`.
  static Future<void> cancelReminders(int itemId) async {
    if (!isMobile) return;
    final id = itemId.hashCode;
    await _plugin.cancel(id: id);
    await _plugin.cancel(id: id + 1);
  }

  /// Requests the `POST_NOTIFICATIONS` permission on Android 13+.
  ///
  /// This is a no‑op on iOS and desktop. On older Android versions the
  /// permission is not required. The call is fire‑and‑forget – if the user
  /// denies, notifications will simply not appear, which is acceptable for
  /// a pantry manager.
  static Future<void> requestPermission() async {
    if (!isMobile || !Platform.isAndroid) return;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }
}
