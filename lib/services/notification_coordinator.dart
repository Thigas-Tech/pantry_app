import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/notification_service_interface.dart';
import 'package:pantry_app/services/recipe_suggestion_service.dart';
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
    required this.recipeSuggestionService,
  });

  /// The [NotificationService] that performs the platform scheduling.
  final NotificationService notificationService;

  /// The database used to load inventory items and product names.
  final DatabaseHelper db;

  /// Picks the weekly recipe suggestion from the user's inventory.
  final RecipeSuggestionService recipeSuggestionService;

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
  /// inactivity reminder and the weekly recipe suggestion.
  Future<void> rescheduleAll({
    required AppLocalizations l10n,
    required Settings settings,
  }) async {
    await rescheduleExpiryReminders(l10n: l10n, settings: settings);
    await rescheduleInactivityReminder(l10n: l10n, settings: settings);
    await rescheduleWeeklyRecipeSuggestion(l10n: l10n, settings: settings);
  }

  /// Cancels and re-schedules the weekly recipe suggestion.
  ///
  /// Loads distinct ingredient names from the active inventory, picks a
  /// suggestion (skipping the last one suggested), and schedules the
  /// weekly notification at the configured day and time. Skips when the
  /// service is not initialized, the suggestion is disabled in settings,
  /// notifications are disabled, the inventory is empty, or no recipe is
  /// returned by the API.
  Future<void> rescheduleWeeklyRecipeSuggestion({
    required AppLocalizations l10n,
    required Settings settings,
  }) async {
    final notifService = notificationService;
    if (!notifService.initialized) {
      logWarning(
        'Notification service not initialized, skipping weekly recipe '
        'suggestion',
      );
      return;
    }

    if (!settings.weeklyRecipeSuggestionEnabled ||
        !settings.notificationsEnabled) {
      logInfo('Weekly recipe suggestion disabled in settings, skipping');
      return;
    }

    await notifService.cancelWeeklyRecipeSuggestion();

    final ingredientNames = await _inventoryIngredientNames();
    if (ingredientNames.isEmpty) {
      logInfo('No ingredients in inventory, skipping weekly recipe suggestion');
      return;
    }

    final suggestion = await recipeSuggestionService.pickSuggestion(
      ingredientNames,
    );
    if (suggestion == null) {
      logWarning('No recipe suggestion available, skipping');
      return;
    }

    await notifService.scheduleWeeklyRecipeSuggestion(
      title: l10n.weeklyRecipeSuggestionTitle,
      body: l10n.weeklyRecipeSuggestionBody(
        suggestion.name,
        ingredientNames.length,
      ),
      dayOfWeek: settings.weeklyRecipeSuggestionDay,
      hour: settings.weeklyRecipeSuggestionHour,
      minute: settings.weeklyRecipeSuggestionMinute,
      channelName: l10n.weeklyRecipeSuggestionChannelName,
      channelDescription: l10n.weeklyRecipeSuggestionChannelDescription,
      notificationsEnabled: settings.notificationsEnabled,
    );
    logInfo('Weekly recipe suggestion scheduling completed');
  }

  /// Returns up to 5 distinct, non-empty product names from the active
  /// inventory, preferring items that expire soon.
  Future<List<String>> _inventoryIngredientNames() async {
    final database = await db.database;
    final inventories = await db.getInventories();
    final expiringFirst = <String>[];
    final remaining = <String>[];
    final seen = <String>{};

    void add(List<String> bucket, String name) {
      if (name.isEmpty || name == 'Unknown') return;
      if (seen.add(name)) bucket.add(name);
    }

    for (final inv in inventories) {
      final rows = await db.inventoryDao.listWithProduct(
        database,
        inventoryId: inv['id'] as int,
      );
      for (final row in rows) {
        final name = (row['product_name'] as String?)?.trim() ?? '';
        if (name.isEmpty || name == 'Unknown') continue;
        final expiry = row['expiry_date'] as String?;
        final isExpiring = expiry != null && expiry.isNotEmpty;
        add(isExpiring ? expiringFirst : remaining, name);
      }
    }
    return [...expiringFirst, ...remaining].take(5).toList();
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
