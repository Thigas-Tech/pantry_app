import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pantry_app/models/inventory_item.dart';

/// Abstract interface for local notification scheduling and management.
///
/// Provides methods for initializing, scheduling, cancelling, and managing
/// local notifications for expiry reminders, inactivity reminders, and
/// test notifications. All methods are safe to call even when the service
/// is not fully initialized — they log warnings and return gracefully.
///
/// Platform-specific behaviour:
/// - Android: full support via FlutterNotificationService.
/// - iOS: basic support (channel creation is a no-op).
/// - Desktop/web: [areNotificationsEnabled] returns `null`.
abstract class NotificationService {
  /// Whether the service has been successfully initialized.
  bool get initialized;

  /// Initializes the notification plugin with tap handlers.
  Future<void> initialize({
    DidReceiveNotificationResponseCallback? onDidReceiveResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundResponse,
    String channelName = 'Expiry reminders',
    String channelDescription = 'Warns about expiring food',
  });

  /// Creates a notification channel with the given [channelId].
  ///
  /// Uses [AndroidNotificationChannelAction.createIfNotExists] so existing
  /// user-configured channel settings are never overwritten.
  Future<void> ensureNotificationChannel({
    String channelId = 'expiry_channel',
    String channelName = 'Expiry reminders',
    String channelDescription = 'Warns about expiring food',
    Importance importance = Importance.high,
  });

  /// Creates the `inactivity_channel` notification channel.
  Future<void> ensureInactivityChannel({
    String channelName = 'Inactivity reminders',
    String channelDescription = 'Reminds you to add products regularly',
  });

  /// Schedules two local notifications for [item].
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
  });

  /// Cancels both notifications associated with the given [itemId].
  Future<void> cancelReminders(int itemId);

  /// Cancels all pending notification requests.
  Future<void> cancelAllReminders();

  /// Sends an immediate test notification.
  Future<void> showTestNotification({
    String title = 'Test Successful',
    String body = 'Immediate notifications are working!',
    String channelName = 'General Notifications',
    String channelDescription = 'Standard app notifications',
  });

  /// Schedules a test notification for 5 seconds from now.
  Future<void> scheduleTestNotification({
    String title = 'Scheduled Test',
    String body = 'This fired 5 seconds later.',
    String channelName = 'General Notifications',
    String channelDescription = 'Standard app notifications',
  });

  /// Schedules a one-shot inactivity reminder.
  Future<void> scheduleInactivityReminder({
    required int? lastAddDateEpoch,
    required int thresholdDays,
    required String title,
    required String Function(int days) buildBody,
    required String channelName,
    required String channelDescription,
    bool notificationsEnabled = true,
  });

  /// Cancels the daily inactivity reminder.
  Future<void> cancelInactivityReminder();

  /// Reschedules expiry reminders for all given [items].
  Future<void> rescheduleAllItems(
    List<InventoryItem> items, {
    required String expiringSoonTitle,
    required String expiringTodayTitle,
    required String Function(String name) buildExpiringSoonBody,
    required String Function(String name) buildExpiringTodayBody,
    Map<String, String>? barcodeToName,
    bool notificationsEnabled = true,
  });

  /// Requests POST_NOTIFICATIONS permission on Android 13+.
  Future<bool?> requestPermission();

  /// Checks whether system notifications are currently enabled.
  Future<bool?> areNotificationsEnabled();

  /// Returns whether the app was launched by tapping a notification.
  Future<NotificationAppLaunchDetails?> getLaunchDetails();

  /// Whether the device can schedule exact-timing notifications.
  ///
  /// Returns `null` on non-Android platforms. On Android 12+ this requires
  /// the `SCHEDULE_EXACT_ALARM` permission; on older Android it defaults to
  /// `true`. When `false`, [scheduleTestNotification] falls back to
  /// [AndroidScheduleMode.inexactAllowWhileIdle].
  Future<bool?> canScheduleExactNotifications();
}
