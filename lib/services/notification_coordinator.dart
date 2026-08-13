import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/notification_service_interface.dart';
import 'package:pantry_app/utils/logger.dart';

/// Single owner of notification (re)scheduling used by every call site.
///
/// The audit found the same scheduling logic re-implemented three times
/// (startup in main.dart, the settings notifications toggle, and the
/// product detail screen), which drifted apart over time — for example the
/// settings path stopped resolving product names. This class centralises:
///
/// - expiry reminders: load every inventory item, resolve display names only
///   for items that actually have an expiry date (one batched query instead
///   of loading the whole products table), then reschedule;
/// - the inactivity reminder: cancel and re-schedule based on the latest
///   product-add date.
///
/// Both operations delegate the platform work to [NotificationService] and
/// read data through [DatabaseHelper].
class NotificationCoordinator {
  /// Creates a [NotificationCoordinator].
  ///
  /// [notificationService] and [db] are injected so the coordinator can be
  /// unit-tested with mocks and shared via the riverpod container.
  NotificationCoordinator({
    required this.notificationService,
    required this.db,
  });

  /// The [NotificationService] that performs the platform scheduling.
  final NotificationService notificationService;

  /// The database used to load inventory items and product names.
  final DatabaseHelper db;

  /// Reschedules expiry reminders for every inventory item with a future
  /// expiry date.
  ///
  /// Loads all inventories and their items, then resolves barcode-to-name
  /// entries only for items that have an expiry date (via a single batched
  /// [DatabaseHelper.getProductsByBarcodes] query). Does nothing when the
  /// notification service is not initialized or [Settings.notificationsEnabled]
  /// is false.
  Future<void> rescheduleExpiryReminders({
    required AppLocalizations l10n,
    required Settings settings,
  }) async {
    final notifService = notificationService;
    if (!notifService.initialized) {
      logWarning('Notification service not initialized, skipping reschedule');
      return;
    }

    final database = await db.database;
    final inventories = await db.getInventories();
    final items = <InventoryItem>[];
    for (final inv in inventories) {
      final invItems = await db.inventoryDao.list(
        database,
        inventoryId: inv['id'] as int,
      );
      items.addAll(invItems);
    }

    if (!settings.notificationsEnabled) {
      logInfo('Notifications disabled in settings, skipping reschedule');
      return;
    }

    final barcodeToName = await _barcodeToNameForExpiring(items);
    await notifService.rescheduleAllItems(
      items,
      barcodeToName: barcodeToName,
      expiringSoonTitle: l10n.expiringSoon,
      expiringTodayTitle: l10n.expiringToday,
      buildExpiringSoonBody: l10n.expiresTomorrow,
      buildExpiringTodayBody: l10n.expiresToday,
      notificationsEnabled: settings.notificationsEnabled,
    );
    logInfo('Notification reschedule completed');
  }

  /// Cancels and re-schedules the inactivity reminder.
  ///
  /// Reads the latest product-add date from [DatabaseHelper.getLastAddDate]
  /// and respects [Settings.inactivityReminderEnabled]; when disabled the
  /// reminder is neither cancelled nor scheduled (the settings toggle owns
  /// cancellation).
  Future<void> rescheduleInactivityReminder({
    required AppLocalizations l10n,
    required Settings settings,
  }) async {
    final notifService = notificationService;
    if (!notifService.initialized) {
      logWarning(
        'Notification service not initialized, skipping inactivity reminder',
      );
      return;
    }

    if (!settings.inactivityReminderEnabled) {
      logInfo('Inactivity reminder disabled in settings, skipping');
      return;
    }

    await notifService.cancelInactivityReminder();
    final lastAddDateEpoch = await db.getLastAddDate();
    await notifService.scheduleInactivityReminder(
      lastAddDateEpoch: lastAddDateEpoch,
      thresholdDays: settings.inactivityThresholdDays,
      title: l10n.inactivityReminderTitle,
      buildBody: l10n.inactivityReminderBody,
      channelName: l10n.inactivityReminderChannelName,
      channelDescription: l10n.inactivityReminderChannelDescription,
      notificationsEnabled: settings.notificationsEnabled,
    );
    logInfo('Inactivity reminder scheduling completed');
  }

  /// Runs the full startup reschedule: expiry reminders followed by the
  /// inactivity reminder.
  Future<void> rescheduleAll({
    required AppLocalizations l10n,
    required Settings settings,
  }) async {
    await rescheduleExpiryReminders(l10n: l10n, settings: settings);
    await rescheduleInactivityReminder(l10n: l10n, settings: settings);
  }

  /// Builds a barcode-to-name map for the items that have an expiry date.
  ///
  /// Queries the products table once with the expiring barcodes and keeps
  /// only non-empty names other than "Unknown".
  Future<Map<String, String>> _barcodeToNameForExpiring(
    List<InventoryItem> items,
  ) async {
    final barcodes = items
        .where(
          (i) => i.expiryDate != null && i.barcode.isNotEmpty,
        )
        .map((i) => i.barcode)
        .toSet()
        .toList();
    if (barcodes.isEmpty) return {};

    final products = await db.getProductsByBarcodes(barcodes);
    final names = <String, String>{};
    for (final p in products) {
      if (p.name.isNotEmpty && p.name != 'Unknown') {
        names[p.barcode] = p.name;
      }
    }
    return names;
  }
}
