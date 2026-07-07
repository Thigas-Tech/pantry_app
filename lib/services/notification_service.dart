import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notification ID for the single daily inactivity reminder.
///
/// Chosen far above any realistic [InventoryItem.id] so it never collides
/// with expiry IDs (which use `itemId * 2` / `itemId * 2 + 1`).
const _inactivityReminderId = 999_999_001;

/// Manages local notifications for expiry and inactivity reminders.
///
/// Designed for **Android** (and ready for iOS when that platform is added).
/// Desktop and web are not supported for scheduled notifications.
///
/// ## Timezone handling
///
/// Uses `flutter_timezone` to query the device's IANA timezone identifier
/// and the `timezone` package for `TZDateTime` math. The combination
/// provides reliable timezone resolution on all platforms without the
/// fragile `DateTime.now().timeZoneName` workaround.
///
/// ## Notification IDs
///
/// Each inventory item can have up to two scheduled notifications:
/// - ID = `itemId * 2`      -> "Expiring soon" (1 day before)
/// - ID = `itemId * 2 + 1`  -> "Expiring today" (on the expiry day)
///
/// The ID scheme uses `itemId * 2` instead of `hashCode` to guarantee
/// positivity (required by Android) and avoid collisions between items
/// that share a barcode.
///
/// ## Channel
///
/// All expiry reminders use `'expiry_channel'`, created explicitly during
/// [initialize] with [Importance.high] and
/// [AndroidNotificationCategory.reminder].
///
/// ## Time-of-day
///
/// Notifications fire at 9:00 AM on the reminder day rather than at
/// midnight. Most users check their pantry in the morning, and a 9 AM
/// notification is more useful than one at midnight.
///
/// See also:
/// - [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
///   — the underlying plugin.
/// - [flutter_timezone](https://pub.dev/packages/flutter_timezone)
///   — device IANA timezone identifier.
class NotificationService {
  /// Creates a [NotificationService] that uses the given [plugin].
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this._defaultLocation,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final tz.Location? _defaultLocation;
  bool _initialized = false;
  bool _rescheduling = false;

  /// Whether the service has been successfully initialized.
  bool get initialized => _initialized;

  /// Initializes the notification plugin with tap handlers.
  ///
  /// Must be called once at app startup, before any notification is
  /// scheduled. Creates the [AndroidNotificationChannel] and registers
  /// the response callbacks for tap handling.
  ///
  /// See also:
  /// - [FlutterLocalNotificationsPlugin.initialize] — the underlying plugin
  ///   method.
  ///
  /// [onDidReceiveResponse] is fired on the main isolate when the user
  /// taps a notification. [onDidReceiveBackgroundResponse] is fired in a
  /// background isolate for actions that do not show the UI.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize({
    DidReceiveNotificationResponseCallback? onDidReceiveResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundResponse,
  }) async {
    if (_initialized) {
      logInfo('Notification service already initialised');
      return;
    }

    logInfo('Initialising notification service');

    tz_data.initializeTimeZones();

    final location = await _resolveDeviceTimezone();
    tz.setLocalLocation(location);
    logInfo('Timezone set to ${location.name}');

    try {
      await ensureNotificationChannel();
    } on Exception catch (e) {
      logWarning('Failed to create notification channel: $e');
      return;
    }

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings();

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: onDidReceiveResponse,
        onDidReceiveBackgroundNotificationResponse:
            onDidReceiveBackgroundResponse,
      );
      _initialized = true;
      logInfo('Notification plugin initialised successfully');
    } on Exception catch (e) {
      logError('Failed to initialise notification plugin: $e');
    }
  }

  /// Creates the `inactivity_channel` notification channel with
  /// [Importance.low] and [AndroidNotificationCategory.recommendation].
  ///
  /// Uses [AndroidNotificationChannelAction.createIfNotExists] so existing
  /// user-configured channel settings are never overwritten.
  Future<void> ensureInactivityChannel() async {
    const channel = AndroidNotificationChannel(
      'inactivity_channel',
      'Inactivity reminders',
      description: 'Reminds you to add products regularly',
      importance: Importance.low,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    try {
      await androidPlugin.createNotificationChannel(channel);
      logInfo('Inactivity notification channel created/verified');
    } on Exception catch (e) {
      logWarning('Failed to create inactivity notification channel: $e');
    }
  }

  /// Creates the `expiry_channel` notification channel.
  ///
  /// Uses [AndroidNotificationChannelAction.createIfNotExists] so that
  /// existing user-configured channel settings are never overwritten.
  /// Should be called during [initialize] before any notification is
  /// scheduled.
  Future<void> ensureNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'expiry_channel',
      'Expiry reminders',
      description: 'Warns about expiring food',
      importance: Importance.high,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    try {
      await androidPlugin.createNotificationChannel(channel);
      logInfo('Notification channel created/verified');
    } on Exception catch (e) {
      logWarning('Failed to create notification channel: $e');
    }
  }

  /// Schedules two local notifications for [item].
  ///
  /// Skips scheduling if notifications are disabled or if the item
  /// has no expiry date or the expiry date is in the past.
  Future<void> scheduleExpiryReminders(
    InventoryItem item, {
    required String expiringSoonTitle,
    required String expiringTodayTitle,
    required String Function(String barcode) buildExpiringSoonBody,
    required String Function(String barcode) buildExpiringTodayBody,
    String channelName = 'Expiry reminders',
    String channelDescription = 'Warns about expiring food',
    bool notificationsEnabled = true,
  }) async {
    if (!notificationsEnabled) {
      logInfo('Notifications disabled in settings, skipping');
      return;
    }

    if (item.expiryDate == null) {
      logInfo('No expiry date for item ${item.barcode}, skipping reminders');
      return;
    }

    if (item.id == null) {
      logWarning('Item has no id, skipping expiry reminders');
      return;
    }

    final expiry = DateTime.tryParse(item.expiryDate!);
    if (expiry == null) {
      logWarning('Could not parse expiry date "${item.expiryDate}"');
      return;
    }

    final systemEnabled = await areNotificationsEnabled();
    if (systemEnabled == false) {
      logWarning('System notifications disabled, skipping reminders');
      return;
    }

    final itemId = item.id!;
    final now = tz.TZDateTime.now(tz.local);

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'expiry_channel',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final oneDayBefore = expiry.subtract(const Duration(days: 1));

    // "Expiring soon" — 9 AM one day before expiry
    final expiringSoonDate = _toMorningTZDateTime(oneDayBefore);
    if (expiringSoonDate.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          id: itemId * 2,
          title: expiringSoonTitle,
          body: buildExpiringSoonBody(item.barcode),
          scheduledDate: expiringSoonDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: item.barcode.isNotEmpty ? item.barcode : 'manual-${item.id}',
        );
        logInfo(
          'Scheduled "expiring soon" for ${item.barcode} on $expiringSoonDate',
        );
      } on Exception catch (e) {
        logError(
          'Failed to schedule "expiring soon" for ${item.barcode}: $e',
        );
      }
    } else {
      logInfo(
        'Skipping "expiring soon" for ${item.barcode} '
        '-- date is in the past',
      );
    }

    // "Expiring today" — 9 AM on the expiry day
    final expiringTodayDate = _toMorningTZDateTime(expiry);
    if (expiringTodayDate.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          id: itemId * 2 + 1,
          title: expiringTodayTitle,
          body: buildExpiringTodayBody(item.barcode),
          scheduledDate: expiringTodayDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: item.barcode.isNotEmpty ? item.barcode : 'manual-${item.id}',
        );
        logInfo(
          'Scheduled "expiring today" for ${item.barcode}'
          ' on $expiringTodayDate',
        );
      } on Exception catch (e) {
        logError(
          'Failed to schedule "expiring today" for ${item.barcode}: $e',
        );
      }
    } else {
      logInfo(
        'Skipping "expiring today" for ${item.barcode} '
        '-- date is in the past',
      );
    }
  }

  /// Cancels both notifications associated with the given [itemId].
  Future<void> cancelReminders(int itemId) async {
    logInfo('Cancelling reminders for item $itemId');
    try {
      await _plugin.cancel(id: itemId * 2);
      await _plugin.cancel(id: itemId * 2 + 1);
      logInfo('Reminders cancelled for item $itemId');
    } on Exception catch (e) {
      logError('Failed to cancel reminders for item $itemId: $e');
    }
  }

  /// Cancels all pending notification requests.
  Future<void> cancelAllReminders() async {
    logInfo('Cancelling all reminder notifications');
    try {
      await _plugin.cancelAll();
      logInfo('All reminder notifications cancelled');
    } on Exception catch (e) {
      logError('Failed to cancel all reminders: $e');
    }
  }

  /// Schedules a one-shot inactivity reminder for tomorrow at 9 AM if the
  /// user has not added any product for [thresholdDays] or more.
  ///
  /// Pass `null` for [lastAddDateEpoch] when the inventory table is empty
  /// (first launch) — no notification is scheduled. The reminder is rescheduled
  /// on every app startup and whenever a new product is added.
  ///
  /// Uses a fixed ID ([_inactivityReminderId]) — calling this again replaces
  /// any previously scheduled inactivity reminder.
  ///
  /// See also:
  /// - [cancelInactivityReminder] to cancel the pending reminder.
  Future<void> scheduleInactivityReminder({
    required int? lastAddDateEpoch,
    required int thresholdDays,
    required String title,
    required String Function(int days) buildBody,
    required String channelName,
    required String channelDescription,
    bool notificationsEnabled = true,
  }) async {
    if (!notificationsEnabled) {
      logInfo('Notifications disabled, skipping inactivity reminder');
      return;
    }

    if (lastAddDateEpoch == null) {
      logInfo(
        'No last add date (empty inventory), skipping inactivity '
        'reminder',
      );
      return;
    }

    final systemEnabled = await areNotificationsEnabled();
    if (systemEnabled == false) {
      logWarning('System notifications disabled, skipping inactivity reminder');
      return;
    }

    await ensureInactivityChannel();

    final lastAddDate = DateTime.fromMillisecondsSinceEpoch(lastAddDateEpoch);
    final now = DateTime.now();
    final daysSinceLastAdd = now.difference(lastAddDate).inDays;

    if (daysSinceLastAdd < thresholdDays) {
      logInfo(
        'Only $daysSinceLastAdd day(s) since last add '
        '(< $thresholdDays), skipping inactivity reminder',
      );
      return;
    }

    // Schedule tomorrow at 9 AM
    final tomorrow = now.add(const Duration(days: 1));
    final scheduledDate = _toMorningTZDateTime(tomorrow);

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'inactivity_channel',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.low,
        category: AndroidNotificationCategory.recommendation,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: _inactivityReminderId,
        title: title,
        body: buildBody(daysSinceLastAdd),
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'inactivity_reminder',
      );
      logInfo(
        'Scheduled inactivity reminder for $scheduledDate '
        '(last add: $daysSinceLastAdd days ago)',
      );
    } on Exception catch (e) {
      logError('Failed to schedule inactivity reminder: $e');
    }
  }

  /// Cancels the daily inactivity reminder associated with
  /// [_inactivityReminderId].
  ///
  /// Safe to call even if no reminder is pending — the plugin ignores
  /// cancellation of non-existent notifications.
  Future<void> cancelInactivityReminder() async {
    logInfo('Cancelling inactivity reminder');
    try {
      await _plugin.cancel(id: _inactivityReminderId);
      logInfo('Inactivity reminder cancelled');
    } on Exception catch (e) {
      logError('Failed to cancel inactivity reminder: $e');
    }
  }

  /// Reschedules expiry reminders for all given [items].
  ///
  /// Cancels all existing scheduled notifications first, then schedules
  /// new ones for items with future expiry dates. This recovers from
  /// device reboots, app updates, and timezone changes.
  ///
  /// Guards against concurrent calls with an internal lock.
  /// Best-effort — individual scheduling failures are caught and logged.
  Future<void> rescheduleAllItems(
    List<InventoryItem> items, {
    required String expiringSoonTitle,
    required String expiringTodayTitle,
    required String Function(String barcode) buildExpiringSoonBody,
    required String Function(String barcode) buildExpiringTodayBody,
    bool notificationsEnabled = true,
  }) async {
    if (!notificationsEnabled) {
      logInfo('Notifications disabled, skipping reschedule');
      return;
    }

    if (_rescheduling) {
      logInfo('Reschedule already in progress, skipping');
      return;
    }

    _rescheduling = true;
    logInfo('Starting reschedule for ${items.length} items');

    try {
      await _plugin.cancelAll();

      for (final item in items) {
        await scheduleExpiryReminders(
          item,
          expiringSoonTitle: expiringSoonTitle,
          expiringTodayTitle: expiringTodayTitle,
          buildExpiringSoonBody: buildExpiringSoonBody,
          buildExpiringTodayBody: buildExpiringTodayBody,
          notificationsEnabled: notificationsEnabled,
        );
      }

      logInfo('Reschedule completed');
    } on Exception catch (e) {
      logError('Reschedule failed: $e');
    } finally {
      _rescheduling = false;
    }
  }

  /// Requests the `POST_NOTIFICATIONS` permission on Android 13+.
  ///
  /// Returns `true` if permission was granted, `false` if denied,
  /// and `null` if the platform does not require permission handling
  /// (desktop/web or Android < 13).
  Future<bool?> requestPermission() async {
    logInfo('Requesting notification permission');
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      logInfo('Not on Android, skipping permission request');
      return null;
    }

    final granted = await androidPlugin.requestNotificationsPermission();
    logInfo('Notification permission request result: $granted');
    return granted;
  }

  /// Checks whether system notifications are currently enabled.
  ///
  /// Returns `true` if notifications are enabled, `false` if disabled,
  /// and `null` if the platform does not support this check.
  Future<bool?> areNotificationsEnabled() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return null;

    try {
      return await androidPlugin.areNotificationsEnabled();
    } on Exception catch (e) {
      logWarning('Failed to check notification status: $e');
      return null;
    }
  }

  /// Returns whether the app was launched by tapping a notification.
  ///
  /// Call this on startup to handle cold-start notification taps.
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    try {
      return await _plugin.getNotificationAppLaunchDetails();
    } on Exception catch (e) {
      logWarning('Failed to get notification launch details: $e');
      return null;
    }
  }

  /// Resolves the device's local timezone using `flutter_timezone`.
  ///
  /// Falls back to [tz.UTC] if the plugin fails or the returned IANA
  /// identifier is not present in the bundled timezone database.
  Future<tz.Location> _resolveDeviceTimezone() async {
    if (_defaultLocation != null) return _defaultLocation;

    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      try {
        return tz.getLocation(tzInfo.identifier);
      } on tz.LocationNotFoundException {
        logWarning(
          'IANA identifier "${tzInfo.identifier}" not in timezone '
          'database, falling back to UTC',
        );
        return tz.UTC;
      }
    } on Exception catch (e) {
      logWarning('Failed to resolve device timezone: $e, falling back to UTC');
      return tz.UTC;
    }
  }

  /// Converts a [DateTime] to a same-date [tz.TZDateTime] at 9:00 AM
  /// in the local timezone.
  tz.TZDateTime _toMorningTZDateTime(DateTime date) {
    final morning = DateTime(date.year, date.month, date.day, 9);
    return tz.TZDateTime.from(morning, tz.local);
  }
}
