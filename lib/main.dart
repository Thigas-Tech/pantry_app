import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/firebase_cache_provider.dart';
import 'package:pantry_app/providers/github_issue_service_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/onboarding_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/pantry_shell.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/services/github_issue_service.dart';
import 'package:pantry_app/services/notification_background_handler.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/navigator_key.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global key for the root scaffold messenger.
///
/// Used by [SnackbarHelper] to show snackbars that survive route
/// transitions, and passed to [MaterialApp.scaffoldMessengerKey].
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// The single [ProviderContainer] shared by the entire app.
///
/// Created once before [runApp] and passed to [UncontrolledProviderScope] so
/// that all providers share the same container and any pre-initialized
/// services (e.g. notification service) are immediately available to the
/// widget tree. Disposed when the platform sends [AppLifecycleState.detached].
late final ProviderContainer appContainer;

/// Entry point of the Pantry application.
///
/// Startup sequence:
/// 1. Flutter binding.
/// 2. Environment variables loaded via flutter_dotenv.
/// 3. App version check — clears stale caches when the app was updated.
/// 4. Notification service initialized (timezone, channel, plugin).
/// 5. Notification permission requested (system dialog, after first frame).
/// 6. Database cleanup, feedback flush, cache refresh (after first frame).
/// 7. App launched inside [UncontrolledProviderScope] so all providers
///    share the same [appContainer].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SnackbarHelper.messengerKey = rootMessengerKey;

  if (kDebugMode) {
    SemanticsBinding.instance.ensureSemantics();
  }

  await dotenv.load();
  logInfo('Environment loaded');

  // Create the shared container before any startup task that needs
  // services, so everything (including _handleAppUpdate) consumes the
  // same singleton instances as the widget tree.
  appContainer = ProviderContainer();

  if (AppConfig.firebaseEnabled) {
    try {
      await Firebase.initializeApp();
      logInfo('Firebase initialized successfully');
      await FirebaseAuth.instance.signInAnonymously();
      logInfo('Anonymous auth initialized');
    } on Exception catch (e) {
      logWarning('Firebase init/auth failed (graceful degradation): $e');
    }
  }

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

  InternetConnectionChecker.instance.configure(
    addresses: [
      AddressCheckOption(
        uri: Uri.parse('https://world.openfoodfacts.org'),
      ),
      AddressCheckOption(
        uri: Uri.parse('https://fdc.nal.usda.gov'),
      ),
    ],
    timeout: const Duration(seconds: 10),
    interval: const Duration(seconds: 10),
  );
  logInfo('InternetConnectionChecker configured with OFF endpoints');

  await _handleAppUpdate();

  try {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool(kOnboardingKey) ?? false;
    appContainer
        .read(onboardingProvider.notifier)
        .initial(value: onboardingCompleted);
    logInfo('Onboarding flag loaded: $onboardingCompleted');
  } on Exception catch (e) {
    logWarning('Failed to load onboarding flag before runApp: $e');
  }

  try {
    final notifService = appContainer.read(notificationServiceProvider);
    await notifService.initialize(
      onDidReceiveResponse: _handleNotificationTap,
      onDidReceiveBackgroundResponse: notificationTapBackground,
    );
    logInfo('Notification service initialized before runApp');
  } on Exception catch (e) {
    logWarning('Notification init before runApp failed: $e');
    // Continue — the notification service will be unavailable on the first
    // frame, but widgets already handle `!initialized` gracefully.
  }

  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: const PantryApp(),
    ),
  );
  logInfo('App started');

  // Post-first-frame tasks (do not block startup).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _runPostInitTasks();
  });

  // Notification permission request — needs the Activity to be visible.
  // This runs ~100ms after the first frame so the system dialog does not
  // overlap the initial UI setup.
  unawaited(
    Future<void>.delayed(
      const Duration(milliseconds: 100),
      _requestNotificationPermission,
    ),
  );
}

/// Runs non-critical post-init tasks sequentially with delays to avoid
/// janking the first few frames.
void _runPostInitTasks() {
  unawaited(_handleColdStartNotification());
  unawaited(_scheduleCacheRefresh());
  unawaited(
    Future<void>.delayed(
      const Duration(milliseconds: 200),
      _runDatabaseCleanup,
    ),
  );
  unawaited(
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      _flushFeedbackQueue,
    ),
  );
  unawaited(
    Future<void>.delayed(
      const Duration(milliseconds: 600),
      _schedulePostInitNotifications,
    ),
  );
  unawaited(
    Future<void>.delayed(
      const Duration(milliseconds: 800),
      _flushProductSubmissionQueue,
    ),
  );
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 8),
      _refreshFirebaseCache,
    ),
  );
}

/// Requests notification permission after the first frame.
///
/// On Android 13+ this shows a system dialog. On older Android the call
/// is a no-op. Failure is silently logged — the user can grant permission
/// later from Settings.
Future<void> _requestNotificationPermission() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final rationaleShown =
        prefs.getBool('notification_rationale_shown') == true;
    if (!rationaleShown) {
      logInfo(
        'Rationale not yet shown — deferring permission request to Settings',
      );
      return;
    }
    final notifService = appContainer.read(notificationServiceProvider);
    if (!notifService.initialized) {
      logWarning('Cannot request permission — notification service not ready');
      return;
    }
    final granted = await notifService.requestPermission();
    if (granted != false) {
      unawaited(_rescheduleNotifications());
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_denied_warning', true);
      logInfo(
        'Notification permission denied — flagged warning for PantryShell',
      );
    }
  } on Exception catch (e) {
    logWarning('Notification permission request failed: $e');
  }
}

/// Checks whether the app was launched by tapping a notification and, if so,
/// navigates to the product detail screen.
///
/// This handles cold-start deep links where the app is started by the system
/// in response to a notification tap, before the widget tree is fully mounted.
/// Runs after the first frame so the navigator is available.
Future<void> _handleColdStartNotification() async {
  try {
    final notifService = appContainer.read(notificationServiceProvider);
    final details = await notifService.getLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return;
    final payload = details?.notificationResponse?.payload;
    if (payload == null || payload.isEmpty) return;
    if (payload == 'inactivity_reminder') return;

    logInfo('Cold-start notification: payload=$payload');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_navigateToProduct(payload));
    });
  } on Exception catch (e) {
    logWarning('Cold-start notification handling failed: $e');
  }
}

/// Clears the product database and image cache when the app version changes.
///
/// This ensures products cached before the Nutri-Score badge feature (or any
/// other schema change) get re-fetched from Open Food Facts with fresh data.
///
/// The changelog detection is content-hash‑driven (compares the hash of
/// CHANGELOG.md file) so that new Unreleased entries surface even when the
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
    final raw = await rootBundle.loadString('USER_CHANGELOG.md');
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
    await appContainer.read(imageCacheProvider).clearCache();

    // Clear only API‑fetched product records so they get re‑fetched with
    // fresh OFF data (including fields added in newer versions).
    // Manual products entered by the user are preserved.
    final db = appContainer.read(databaseProvider);
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
    final repo = appContainer.read(productRepositoryProvider);
    if (!await repo.isCacheOverdue()) {
      logInfo('Cache is fresh — skipping scheduled refresh');
      return;
    }
    logInfo('Cache is overdue — scheduling background refresh');
    // Set the timestamp *before* firing refreshes so that
    // [HomeScreen._refreshIfOverdue] sees a non‑overdue cache and
    // does not duplicate the work.
    await repo.setLastRefreshTime();
    final db = appContainer.read(databaseProvider);
    final inventories = await db.getInventories();
    await Future.wait(
      inventories.map(
        (inv) => repo.refreshInventoryProducts(inv['id'] as int),
      ),
    );
    logInfo(
      'Refreshed products for ${inventories.length} inventories',
    );
    appContainer.invalidate(pantryProvider);
  } on Exception catch (e) {
    logError('Scheduled cache refresh failed: $e');
  }
}

/// Removes stale inventory items and orphaned products.
void _runDatabaseCleanup() {
  unawaited(_runDatabaseCleanupAsync());
}

Future<void> _runDatabaseCleanupAsync() async {
  logInfo('Starting database cleanup');
  try {
    final prefs = await SharedPreferences.getInstance();
    final retentionDays = prefs.getInt('retentionDays') ?? 60;
    final dbHelper = appContainer.read(databaseProvider);
    await dbHelper.cleanupOldEntries(retentionDays: retentionDays);
    logInfo('Database cleanup completed');
  } on Exception catch (e) {
    logError('Database cleanup failed: $e');
  }
}

/// Flushes any queued feedback issues at startup.
void _flushFeedbackQueue() {
  unawaited(_flushFeedbackQueueAsync());
}

Future<void> _flushFeedbackQueueAsync() async {
  logInfo('Checking for pending feedback issues');
  await GithubIssueService.initPreferences();
  try {
    final service = appContainer.read(githubIssueServiceProvider);
    final result = await service.flushQueue();
    if (result.submitted > 0) {
      logInfo('Flushed ${result.submitted} queued feedback issues');
    }
    if (result.failed > 0) {
      logWarning('${result.failed} feedback issues failed to flush');
    }
  } on Exception catch (e) {
    logWarning('Feedback queue flush skipped: $e');
  }
}

/// Reschedules expiry and inactivity reminders after startup.
void _schedulePostInitNotifications() {
  unawaited(_rescheduleNotifications());
  unawaited(_scheduleInactivityReminder());
}

/// Flushes queued product submissions to Open Food Facts.
Future<void> _flushProductSubmissionQueue() async {
  logInfo('Checking for pending product submissions');
  try {
    final service = appContainer.read(productSubmissionServiceProvider);
    final submitted = await service.flushQueue();
    if (submitted > 0) {
      logInfo('Flushed $submitted pending product submissions');
    }
  } on Exception catch (e) {
    logWarning('Product submission queue flush failed: $e');
  }
}

/// Refreshes stale Firebase cache entries in the background.
///
/// Runs 8 seconds after startup to avoid competing with other
/// post-init tasks for network bandwidth. If Firebase is not
/// available (feature flag off, missing config, runtime error)
/// this is a no-op.
Future<void> _refreshFirebaseCache() async {
  try {
    final cacheService = appContainer.read(firebaseCacheProvider);
    if (cacheService.isAvailable) {
      final refreshed = await cacheService.refreshStaleEntries();
      if (refreshed > 0) {
        logInfo('Firebase cache: $refreshed entries refreshed');
      }
    }
  } on Exception catch (e) {
    logWarning('Firebase cache refresh failed: $e');
  }
}

/// Handles a notification tap by navigating to the product detail screen.
///
/// Reads the barcode from [NotificationResponse.payload] and looks up
/// the product in the database. Inactivity reminders are ignored since
/// they have no associated product.
void _handleNotificationTap(
  NotificationResponse response,
) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) {
    logWarning('Notification tap with empty payload — ignoring');
    return;
  }

  if (payload == 'inactivity_reminder') {
    logInfo('Notification tap for inactivity reminder — no navigation');
    return;
  }

  logInfo('Notification tap: payload=$payload, actionId=${response.actionId}');
  unawaited(_navigateToProduct(payload));
}

/// Looks up the product by [barcode] and navigates to its detail screen.
Future<void> _navigateToProduct(String barcode) async {
  final context = appNavigatorKey.currentContext;
  if (context == null) {
    logWarning('No navigator context for notification tap');
    return;
  }

  try {
    final db = appContainer.read(databaseProvider);
    final product = await db.getProduct(barcode);
    if (product == null) {
      logWarning('Product not found for barcode: $barcode');
      if (!context.mounted) return;
      SnackbarHelper.showInfo(context, 'Product not found');
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  } on Exception catch (e) {
    logError('Failed to navigate to product from notification tap: $e');
  }
}

/// Reschedules all expiry reminders for items with future expiry dates.
Future<void> _rescheduleNotifications() async {
  logInfo('Rescheduling expiry notifications');
  try {
    final notifService = appContainer.read(notificationServiceProvider);
    if (!notifService.initialized) {
      logWarning('Notification service not initialized, skipping reschedule');
      return;
    }
    final db = appContainer.read(databaseProvider);
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
    final settings = appContainer.read(settingsProvider);
    if (!settings.notificationsEnabled) {
      logInfo('Notifications disabled in settings, skipping reschedule');
      return;
    }

    final barcodeToName = <String, String>{};
    final products = await db.getAllProducts();
    for (final p in products) {
      if (p.name.isNotEmpty && p.name != 'Unknown') {
        barcodeToName[p.barcode] = p.name;
      }
    }

    final locale = PlatformDispatcher.instance.locale;
    final l10n = lookupAppLocalizations(
      <String>{'en', 'pt'}.contains(locale.languageCode)
          ? locale
          : const Locale('en'),
    );
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
  } on Exception catch (e) {
    logError('Notification reschedule failed: $e');
  }
}

/// Checks the inactivity threshold and schedules a daily reminder if the user
/// has not added any product for more than [Settings.inactivityThresholdDays]
/// days.
Future<void> _scheduleInactivityReminder() async {
  logInfo('Scheduling inactivity reminder check');
  try {
    final notifService = appContainer.read(notificationServiceProvider);
    if (!notifService.initialized) {
      logWarning(
        'Notification service not initialized, skipping inactivity reminder',
      );
      return;
    }
    final db = appContainer.read(databaseProvider);
    final lastAddDateEpoch = await db.getLastAddDate();
    final settings = appContainer.read(settingsProvider);

    if (!settings.inactivityReminderEnabled) {
      logInfo('Inactivity reminder disabled in settings, skipping');
      return;
    }

    final locale = PlatformDispatcher.instance.locale;
    final l10n = lookupAppLocalizations(
      <String>{'en', 'pt'}.contains(locale.languageCode)
          ? locale
          : const Locale('en'),
    );
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
  } on Exception catch (e) {
    logError('Inactivity reminder scheduling failed: $e');
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
          navigatorKey: appNavigatorKey,
          scaffoldMessengerKey: rootMessengerKey,
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
