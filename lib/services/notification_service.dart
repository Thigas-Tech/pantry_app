import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/utils/platform_utils.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (!isMobile) return;

    // Load the timezone database
    tz_data.initializeTimeZones();
    // Use the device's local timezone from DateTime
    final localTimeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(localTimeZoneName));
    } catch (_) {
      // Fallback to UTC if the name is unknown
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

  static Future<void> cancelReminders(int itemId) async {
    if (!isMobile) return;
    final id = itemId.hashCode;
    await _plugin.cancel(id: id);
    await _plugin.cancel(id: id + 1);
  }

  static Future<void> requestPermission() async {
    if (!isMobile || !Platform.isAndroid) return;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }
}
