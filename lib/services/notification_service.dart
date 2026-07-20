import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/services/notification_service_interface.dart';
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
/// Uses flutter_timezone to query the device's IANA timezone identifier
/// and the timezone package for [tz.TZDateTime] math. The combination
/// provides reliable timezone resolution on all platforms without the
/// fragile [DateTime.timeZoneName] workaround.
///
/// ## Notification IDs
///
/// Each inventory item can have up to two scheduled notifications:
/// - ID = `itemId * 2`      -> "Expiring soon" (1 day before)
/// - ID = `itemId * 2 + 1`  -> "Expiring today" (on the expiry day)
///
/// The ID scheme uses `itemId * 2` instead of [hashCode] to guarantee
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
class FlutterNotificationService implements NotificationService {
  /// Creates a [FlutterNotificationService] that uses the given [plugin].
  FlutterNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this._defaultLocation,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final tz.Location? _defaultLocation;
  bool _initialized = false;
  bool _rescheduling = false;

  @override
  bool get initialized => _initialized;

  @override
  Future<void> initialize({
    DidReceiveNotificationResponseCallback? onDidReceiveResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundResponse,
    String channelName = 'Expiry reminders',
    String channelDescription = 'Warns about expiring food',
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

    await ensureNotificationChannel(
      channelName: channelName,
      channelDescription: channelDescription,
    );
    await ensureNotificationChannel(
      channelId: 'pantry_general_channel',
      channelName: 'General Notifications',
      channelDescription: 'Standard app notifications',
      importance: Importance.max,
    );

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

  @override
  Future<void> ensureInactivityChannel({
    String channelName = 'Inactivity reminders',
    String channelDescription = 'Reminds you to add products regularly',
  }) async {
    final channel = AndroidNotificationChannel(
      'inactivity_channel',
      channelName,
      description: channelDescription,
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

  @override
  Future<void> ensureNotificationChannel({
    String channelId = 'expiry_channel',
    String channelName = 'Expiry reminders',
    String channelDescription = 'Warns about expiring food',
    Importance importance = Importance.high,
  }) async {
    final channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: importance,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    try {
      await androidPlugin.createNotificationChannel(channel);
      logInfo('Notification channel ($channelId) created/verified');
    } on Exception catch (e) {
      logWarning('Failed to create notification channel ($channelId): $e');
    }
  }

  @override
  Future<void> scheduleExpiryReminders(
    InventoryItem item, {
    required String expiringSoonTitle,
    required String expiringTodayTitle,
    required String Function(String name) buildExpiringSoonBody,
    required String Function(String name) buildExpiringTodayBody,
    String? productName,
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

    final displayName = (productName != null && productName.isNotEmpty)
        ? productName
        : item.barcode;

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

    final expiringSoonDate = _toMorningTZDateTime(oneDayBefore);
    if (expiringSoonDate.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          id: itemId * 2,
          title: expiringSoonTitle,
          body: buildExpiringSoonBody(displayName),
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

    final expiringTodayDate = _toMorningTZDateTime(expiry);
    if (expiringTodayDate.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          id: itemId * 2 + 1,
          title: expiringTodayTitle,
          body: buildExpiringTodayBody(displayName),
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

  @override
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

  @override
  Future<void> cancelAllReminders() async {
    logInfo('Cancelling all reminder notifications');
    try {
      await _plugin.cancelAll();
      logInfo('All reminder notifications cancelled');
    } on Exception catch (e) {
      logError('Failed to cancel all reminders: $e');
    }
  }

  NotificationDetails _getChannelDetails({
    String channelName = 'General Notifications',
    String channelDescription = 'Standard app notifications',
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'pantry_general_channel',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
    );
  }

  @override
  Future<void> showTestNotification({
    String title = 'Test Successful',
    String body = 'Immediate notifications are working!',
    String channelName = 'General Notifications',
    String channelDescription = 'Standard app notifications',
  }) async {
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: _getChannelDetails(
        channelName: channelName,
        channelDescription: channelDescription,
      ),
    );
  }

  @override
  Future<void> scheduleTestNotification({
    String title = 'Scheduled Test',
    String body = 'This fired 5 seconds later.',
    String channelName = 'General Notifications',
    String channelDescription = 'Standard app notifications',
  }) async {
    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 5));

    final exactAvailable = await canScheduleExactNotifications();
    final scheduleMode = (exactAvailable == true)
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    if (exactAvailable == false) {
      logWarning(
        'Exact alarms not available — test notification will use inexact '
        'scheduling',
      );
    }

    await _plugin.zonedSchedule(
      id: 1,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: _getChannelDetails(
        channelName: channelName,
        channelDescription: channelDescription,
      ),
      androidScheduleMode: scheduleMode,
    );
  }

  @override
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

    await ensureInactivityChannel(
      channelName: channelName,
      channelDescription: channelDescription,
    );

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

  @override
  Future<void> cancelInactivityReminder() async {
    logInfo('Cancelling inactivity reminder');
    try {
      await _plugin.cancel(id: _inactivityReminderId);
      logInfo('Inactivity reminder cancelled');
    } on Exception catch (e) {
      logError('Failed to cancel inactivity reminder: $e');
    }
  }

  @override
  Future<void> rescheduleAllItems(
    List<InventoryItem> items, {
    required String expiringSoonTitle,
    required String expiringTodayTitle,
    required String Function(String name) buildExpiringSoonBody,
    required String Function(String name) buildExpiringTodayBody,
    Map<String, String>? barcodeToName,
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
          productName: barcodeToName?[item.barcode],
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

  @override
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
    await androidPlugin.requestExactAlarmsPermission();
    logInfo('Notification permission request result: $granted');
    return granted;
  }

  @override
  Future<bool?> canScheduleExactNotifications() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return null;

    try {
      return await androidPlugin.canScheduleExactNotifications();
    } on Exception catch (e) {
      logWarning('Failed to check exact alarm status: $e');
      return null;
    }
  }

  @override
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

  @override
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    try {
      return await _plugin.getNotificationAppLaunchDetails();
    } on Exception catch (e) {
      logWarning('Failed to get notification launch details: $e');
      return null;
    }
  }

  /// Common timezone abbreviations mapped to IANA identifiers.
  static const _tzAbbreviations = <String, String>{
    'BRT': 'America/Sao_Paulo',
    'BRST': 'America/Sao_Paulo',
    'EST': 'America/New_York',
    'EDT': 'America/New_York',
    'CST': 'America/Chicago',
    'CDT': 'America/Chicago',
    'MST': 'America/Denver',
    'MDT': 'America/Denver',
    'PST': 'America/Los_Angeles',
    'PDT': 'America/Los_Angeles',
    'CET': 'Europe/Berlin',
    'CEST': 'Europe/Berlin',
    'GMT': 'UTC',
    'UTC': 'UTC',
    'JST': 'Asia/Tokyo',
    'IST': 'Asia/Kolkata',
    'AEST': 'Australia/Sydney',
    'AEDT': 'Australia/Sydney',
    'NZST': 'Pacific/Auckland',
    'NZDT': 'Pacific/Auckland',
  };

  /// Resolves the device's local timezone using flutter_timezone.
  Future<tz.Location> _resolveDeviceTimezone() async {
    if (_defaultLocation != null) return _defaultLocation;

    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final identifier = tzInfo.identifier;

      final resolved = _resolveTimezoneIdentifier(identifier);
      if (resolved != null) return resolved;

      logWarning(
        'Could not resolve timezone "$identifier", falling back to UTC',
      );
      return tz.UTC;
    } on Exception catch (e) {
      logWarning('Failed to resolve device timezone: $e, falling back to UTC');
      return tz.UTC;
    }
  }

  /// Attempts to resolve [identifier] to a [tz.Location].
  ///
  /// Handles IANA names, common abbreviations, and raw UTC offset strings.
  /// Returns `null` if the identifier cannot be resolved.
  tz.Location? _resolveTimezoneIdentifier(String identifier) {
    // 1. Try as a direct IANA identifier.
    try {
      return tz.getLocation(identifier);
    } on tz.LocationNotFoundException {
      // Continue to fallbacks.
    }

    // 2. Check abbreviation map.
    final ianaName = _tzAbbreviations[identifier];
    if (ianaName != null) {
      try {
        return tz.getLocation(ianaName);
      } on tz.LocationNotFoundException {
        // Continue to fallbacks.
      }
    }

    // 3. Strip "GMT" prefix (common on some Android devices).
    if (identifier.startsWith('GMT') || identifier.startsWith('gmt')) {
      final offset = identifier.substring(3);
      if (offset.isEmpty) return tz.UTC;
      return _parseOffsetLocation(offset);
    }

    // 4. Try as a raw UTC offset (e.g. "-03", "+05:30", "UTC+8").
    if (identifier.startsWith('UTC') || identifier.startsWith('utc')) {
      final offset = identifier.substring(3);
      if (offset.isEmpty) return tz.UTC;
      return _parseOffsetLocation(offset);
    }

    return null;
  }

  /// Parses a UTC offset string like "-03", "+05:30", or "8" and returns
  /// a [tz.Location] with the fixed offset.
  tz.Location? _parseOffsetLocation(String offset) {
    try {
      final cleaned = offset.trim();
      final negative = cleaned.startsWith('-');
      final parts = cleaned
          .replaceFirst(RegExp('^[+-]'), '')
          .split(':')
          .map((s) => int.tryParse(s) ?? 0)
          .toList();
      final hours = parts.isNotEmpty ? parts[0] : 0;
      final minutes = parts.length > 1 ? parts[1] : 0;
      final totalMinutes = (hours * 60 + minutes) * (negative ? -1 : 1);
      final offsetDuration = Duration(minutes: totalMinutes);
      final sign = negative ? '-' : '+';
      final locationName =
          'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
      return tz.Location(
        locationName,
        [],
        [],
        [tz.TimeZone(offsetDuration, isDst: false, abbreviation: locationName)],
      );
    } on Exception catch (e) {
      logWarning('Failed to parse UTC offset "$offset": $e');
      return null;
    }
  }

  /// Converts a [DateTime] to a same-date [tz.TZDateTime] at 9:00 AM
  /// in the local timezone.
  tz.TZDateTime _toMorningTZDateTime(DateTime date) {
    final morning = DateTime(date.year, date.month, date.day, 9);
    return tz.TZDateTime.from(morning, tz.local);
  }
}
