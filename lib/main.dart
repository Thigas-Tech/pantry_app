import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/github_issue_service_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/pantry_shell.dart';
import 'package:pantry_app/services/github_issue_service.dart';
import 'package:pantry_app/services/image_cache_service.dart';
import 'package:pantry_app/services/notification_background_handler.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry point of the Pantry application.
///
/// Startup sequence:
/// 1. Flutter binding.
/// 2. Environment variables loaded via `flutter_dotenv`.
/// 3. App version check — clears stale caches when the app was updated.
/// 4. Notification permission request and initialization.
/// 5. Database cleanup (after first frame).
/// 6. App launched inside `ProviderScope`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  logInfo('Environment loaded');

  off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(
    name: 'PantryApp',
    version: '1.0',
    system: Platform.operatingSystem,
    comment: AppConfig.contactEmail,
  );
  off.OpenFoodAPIConfiguration.globalLanguages = [
    off.OpenFoodFactsLanguage.ENGLISH,
  ];
  logInfo('OFF SDK configured');

  await _handleAppUpdate();

  runApp(const ProviderScope(child: PantryApp()));
  logInfo('App started');

  unawaited(_scheduleCacheRefresh());

  final container = ProviderContainer();
  final notifService = container.read(notificationServiceProvider);

  await notifService.initialize(
    onDidReceiveResponse: (response) {
      _handleNotificationTap(response, container);
    },
    onDidReceiveBackgroundResponse: notificationTapBackground,
  );

  final granted = await notifService.requestPermission();
  if (granted != false) {
    unawaited(_rescheduleNotifications(ProviderContainer()));
  } else {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_denied_warning', true);
    logInfo('Notification permission denied — flagged warning for PantryShell');
  }

  unawaited(_scheduleInactivityReminder(ProviderContainer()));
  unawaited(_runDatabaseCleanup(ProviderContainer()));
  unawaited(_flushFeedbackQueue(ProviderContainer()));
  container.dispose();
}

/// Clears the product database and image cache when the app version changes.
///
/// This ensures products cached before the Nutri-Score badge feature (or any
/// other schema change) get re-fetched from Open Food Facts with fresh data.
///
/// The changelog detection is content-hash‑driven (compares the hash of
/// `CHANGELOG.md`) so that new `[Unreleased]` entries surface even when the
/// app version string has not changed between development builds.
Future<void> _handleAppUpdate() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    final currentVersion = '${info.version}+${info.buildNumber}';
    final lastVersion = prefs.getString('app_version');

    // Changelog tracking — content-hash-driven, not version-driven.
    // This ensures new [Unreleased] entries are surfaced even when the
    // app version string has not changed between development builds.
    final raw = await rootBundle.loadString('CHANGELOG.md');
    final contentHash = raw.hashCode.toString();
    final lastSeenHash = prefs.getString('changelog_content_hash');

    if (lastSeenHash != null && lastSeenHash != contentHash) {
      await prefs.setString('changelog_show_pending', 'true');
      logInfo('Changelog content changed — flagged for display');
    }
    await prefs.setString('changelog_content_hash', contentHash);

    if (lastVersion == currentVersion) {
      logInfo('Version unchanged ($currentVersion) — skipping cache flush');
      return;
    }

    logInfo(
      'App updated from ${lastVersion ?? 'first install'} to $currentVersion',
    );

    // Clear image cache so stale images don't persist across updates.
    await ImageCacheService().clearCache();

    // Clear only API‑fetched product records so they get re‑fetched with
    // fresh OFF data (including fields added in newer versions).
    // Manual products entered by the user are preserved.
    final db = DatabaseHelper();
    await db.clearCachedProducts();

    await prefs.setString('app_version', currentVersion);
    logInfo('Caches flushed for app update');
  } on Exception catch (e) {
    logError('App update handling failed: $e');
  }
}

/// Checks whether the cached product data needs refreshing and, if so, fires
/// a background refresh for every inventory.
///
/// Runs after the app starts. This is a best‑effort operation — failures are
/// silently logged but never propagated.
Future<void> _scheduleCacheRefresh() async {
  try {
    final container = ProviderContainer();
    final repo = container.read(productRepositoryProvider);
    if (!await repo.isCacheOverdue()) {
      logInfo('Cache is fresh — skipping scheduled refresh');
      container.dispose();
      return;
    }
    logInfo('Cache is overdue — scheduling background refresh');
    // Set the timestamp *before* firing refreshes so that
    // [HomeScreen._refreshIfOverdue] sees a non‑overdue cache and
    // does not duplicate the work.
    await repo.setLastRefreshTime();
    final db = container.read(databaseProvider);
    final inventories = await db.getInventories();
    for (final inv in inventories) {
      repo.refreshInventoryProductsBackground(inv['id'] as int);
    }
    logInfo(
      'Background refresh scheduled for ${inventories.length} inventories',
    );
    container.dispose();
  } on Exception catch (e) {
    logError('Scheduled cache refresh failed: $e');
  }
}

/// Removes stale inventory items and orphaned products.
Future<void> _runDatabaseCleanup(ProviderContainer container) async {
  logInfo('Starting database cleanup');
  try {
    final settings = container.read(settingsProvider);
    final dbHelper = DatabaseHelper();
    await dbHelper.cleanupOldEntries(retentionDays: settings.retentionDays);
    logInfo('Database cleanup completed');
  } on Exception catch (e) {
    logError('Database cleanup failed: $e');
  } finally {
    container.dispose();
  }
}

/// Flushes any queued feedback issues at startup.
Future<void> _flushFeedbackQueue(ProviderContainer container) async {
  logInfo('Checking for pending feedback issues');
  await GithubIssueService.initPreferences();
  try {
    final service = container.read(githubIssueServiceProvider);
    final result = await service.flushQueue();
    if (result.submitted > 0) {
      logInfo('Flushed ${result.submitted} queued feedback issues');
    }
    if (result.failed > 0) {
      logWarning('${result.failed} feedback issues failed to flush');
    }
    container.dispose();
  } on Exception catch (e) {
    logWarning('Feedback queue flush skipped: $e');
    container.dispose();
  }
}

/// Handles a notification tap by navigating to the product detail screen.
///
/// Reads the barcode from [NotificationResponse.payload] and looks up
/// the product in the database.
void _handleNotificationTap(
  NotificationResponse response,
  ProviderContainer container,
) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) {
    logWarning('Notification tap with empty payload — ignoring');
    return;
  }

  logInfo('Notification tap: payload=$payload, actionId=${response.actionId}');
  // Deep-link handling is deferred to the notification tap callback in
  // PantryShell, which has access to the Navigator context.
}

/// Reschedules all expiry reminders for items with future expiry dates.
Future<void> _rescheduleNotifications(ProviderContainer container) async {
  logInfo('Rescheduling expiry notifications');
  try {
    final notifService = container.read(notificationServiceProvider);
    if (!notifService.initialized) {
      logWarning('Notification service not initialized, skipping reschedule');
      return;
    }
    final db = DatabaseHelper();
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
    final settings = container.read(settingsProvider);

    if (!settings.notificationsEnabled) {
      logInfo('Notifications disabled in settings, skipping reschedule');
      return;
    }

    // TODO(thiago): localize these strings once l10n is available at startup
    await notifService.rescheduleAllItems(
      items,
      expiringSoonTitle: 'Expiring soon',
      expiringTodayTitle: 'Food expiring today',
      buildExpiringSoonBody: (barcode) => '$barcode expires tomorrow',
      buildExpiringTodayBody: (barcode) => '$barcode expires today!',
      notificationsEnabled: settings.notificationsEnabled,
    );
    logInfo('Notification reschedule completed');
  } on Exception catch (e) {
    logError('Notification reschedule failed: $e');
  } finally {
    container.dispose();
  }
}

/// Checks the inactivity threshold and schedules a daily reminder if the user
/// has not added any product for more than [Settings.inactivityThresholdDays]
/// days.
Future<void> _scheduleInactivityReminder(ProviderContainer container) async {
  logInfo('Scheduling inactivity reminder check');
  try {
    final notifService = container.read(notificationServiceProvider);
    if (!notifService.initialized) {
      logWarning(
        'Notification service not initialized, skipping inactivity reminder',
      );
      return;
    }
    final db = DatabaseHelper();
    final lastAddDateEpoch = await db.getLastAddDate();
    final settings = container.read(settingsProvider);

    if (!settings.inactivityReminderEnabled) {
      logInfo('Inactivity reminder disabled in settings, skipping');
      return;
    }

    await notifService.scheduleInactivityReminder(
      lastAddDateEpoch: lastAddDateEpoch,
      thresholdDays: settings.inactivityThresholdDays,
      title: 'Time to restock your pantry?',
      buildBody: (days) => 'You have not added any products in $days days.',
      channelName: 'Inactivity reminders',
      channelDescription: 'Reminds you to add products regularly',
      notificationsEnabled: settings.notificationsEnabled,
    );
    logInfo('Inactivity reminder scheduling completed');
  } on Exception catch (e) {
    logError('Inactivity reminder scheduling failed: $e');
  } finally {
    container.dispose();
  }
}

/// The root widget of the Pantry application.
class PantryApp extends ConsumerWidget {
  /// Creates a [PantryApp] widget.
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeOption = ref.watch(themeModeProvider);
    final themeMode = switch (themeModeOption) {
      ThemeModeOption.light => ThemeMode.light,
      ThemeModeOption.dark => ThemeMode.dark,
      ThemeModeOption.system => ThemeMode.system,
    };

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme =
            lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal);
        final rawDarkScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            );

        final settings = ref.watch(settingsProvider);
        final darkScheme = settings.amoledDarkMode
            ? rawDarkScheme.copyWith(
                surface: Colors.black,
                surfaceContainerHighest: const Color(0xFF1C1C1E),
                surfaceContainerLow: const Color(0xFF1C1C1E),
                surfaceContainer: const Color(0xFF2C2C2E),
                surfaceContainerHigh: const Color(0xFF3A3A3C),
              )
            : rawDarkScheme;

        return MaterialApp(
          title: 'Pantry',
          theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PantryShell(),
        );
      },
    );
  }
}
