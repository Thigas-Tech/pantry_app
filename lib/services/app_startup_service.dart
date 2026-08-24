import 'dart:async';

import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/cache_refresh_coordinator_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/notification_coordinator_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/ui_flags_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/services/app_update_handler.dart';
import 'package:pantry_app/services/notification_coordinator.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/navigator_key.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the post-first-frame startup orchestration for the app.
///
/// Previously all of this lived as top-level functions in main.dart: fourteen
/// async orchestrators plus navigation and app-update bookkeeping made the
/// entry point a god-file. [AppStartupService] bundles them so main.dart
/// keeps only the raw wiring and the app widget.
///
/// The constructor takes the shared [ProviderContainer] (so every provider
/// read resolves the same singletons as the widget tree) plus two injectable
/// seams for tests: a delay function used between post-init tasks and an
/// anonymous sign-in implementation.
class AppStartupService {
  /// Creates an [AppStartupService].
  ///
  /// The delay function defaults to [Future.delayed]. Both the delay and the
  /// version source are injectable so tests can avoid real timers and
  /// platform calls.
  AppStartupService({
    required this.container,
    Future<void> Function(Duration delay)? delay,
    this.versionInfo,
  }) : _delay = delay ?? _defaultDelay;

  /// The shared [ProviderContainer] every provider read resolves against.
  final ProviderContainer container;

  final Future<void> Function(Duration delay) _delay;

  /// Injectable version source, or null to use the platform implementation.
  VersionInfoSource? versionInfo;

  AppUpdateHandler? _appUpdateHandler;
  bool _appUpdateVersionChanged = false;

  /// Compares the installed app version with the last-seen one before the
  /// first frame (a single fast platform call), remembering whether an
  /// update happened so the cache flush can run post-frame.
  ///
  /// The changelog content-hash check and the cache flush run in
  /// [runAppUpdatePostFrame] so startup does not block on asset loads or
  /// database writes.
  Future<void> checkAppUpdateBeforeFrame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final handler = AppUpdateHandler(
        prefs: prefs,
        db: container.read(databaseProvider),
        imageCache: container.read(imageCacheProvider),
        versionInfo: versionInfo,
      );
      _appUpdateHandler = handler;
      _appUpdateVersionChanged = await handler.checkVersionChanged();
    } on Exception catch (e) {
      logError('App update check failed: $e');
    }
  }

  /// Runs the post-frame half of app-update handling: flags the changelog
  /// badge when its content changed and, on a version change, clears the
  /// image cache and API-fetched products so they are re-fetched with
  /// fresh OFF data (manual products are preserved).
  Future<void> runAppUpdatePostFrame() async {
    try {
      final handler = _appUpdateHandler;
      if (handler == null) return;
      final showChangelog = await handler.updateChangelogFlag();
      if (showChangelog) {
        await container.read(uiFlagsProvider.future);
        container
            .read(uiFlagsProvider.notifier)
            .setChangelogShowPending(
              value: true,
            );
      }
      if (_appUpdateVersionChanged) {
        await handler.flushCaches();
      }
    } on Exception catch (e) {
      logError('App update handling failed: $e');
    }
  }

  /// Runs non-critical post-init tasks sequentially with delays to avoid
  /// janking the first few frames.
  Future<void> schedulePostInitTasks() async {
    await runAppUpdatePostFrame();
    await _handleColdStartNotification();
    await _scheduleCacheRefresh();
    await _delay(const Duration(milliseconds: 200));
    await _runDatabaseCleanup();
    await _delay(const Duration(milliseconds: 400));
    await _delay(const Duration(milliseconds: 600));
    await _schedulePostInitNotifications();
    await _delay(const Duration(milliseconds: 800));
    await _flushProductSubmissionQueue();
  }

  /// Requests notification permission after the first frame.
  ///
  /// On Android 13+ this shows a system dialog. On older Android the call
  /// is a no-op. When the rationale has not been shown yet (first install)
  /// the request is deferred to the Settings screen. A denial flags the
  /// PantryShell warning; a grant reschedules expiry reminders.
  Future<void> requestNotificationPermission() async {
    try {
      final flags = await container.read(uiFlagsProvider.future);
      if (!flags.notificationRationaleShown) {
        logInfo(
          'Rationale not yet shown — deferring permission request to Settings',
        );
        return;
      }
      final notifService = container.read(notificationServiceProvider);
      if (!notifService.initialized) {
        logWarning(
          'Cannot request permission — notification service not ready',
        );
        return;
      }
      final granted = await notifService.requestPermission();
      if (granted != false) {
        unawaited(_rescheduleNotifications());
      } else {
        container
            .read(uiFlagsProvider.notifier)
            .setNotificationDeniedWarning(
              value: true,
            );
        logInfo(
          'Notification permission denied — flagged warning for PantryShell',
        );
      }
    } on Exception catch (e) {
      logWarning('Notification permission request failed: $e');
    }
  }

  /// Handles a notification tap by navigating to the product detail screen.
  ///
  /// Reads the barcode from [NotificationResponse.payload] and looks up
  /// the product in the database. Inactivity reminders are ignored since
  /// they have no associated product.
  void handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      logWarning('Notification tap with empty payload — ignoring');
      return;
    }

    if (payload == 'inactivity_reminder') {
      logInfo('Notification tap for inactivity reminder — no navigation');
      return;
    }

    if (payload == 'weekly_recipe_suggestion') {
      logInfo('Notification tap for weekly recipe suggestion — no navigation');
      return;
    }

    logInfo(
      'Notification tap: payload=$payload, actionId=${response.actionId}',
    );
    unawaited(_navigateToProduct(payload));
  }

  /// Checks whether the app was launched by tapping a notification and, if so,
  /// navigates to the product detail screen.
  ///
  /// This handles cold-start deep links where the app is started by the
  /// system in response to a notification tap, before the widget tree is
  /// fully mounted.
  Future<void> _handleColdStartNotification() async {
    try {
      final notifService = container.read(notificationServiceProvider);
      final details = await notifService.getLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return;
      final payload = details?.notificationResponse?.payload;
      if (payload == null || payload.isEmpty) return;
      if (payload == 'inactivity_reminder') return;
      if (payload == 'weekly_recipe_suggestion') return;

      logInfo('Cold-start notification: payload=$payload');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_navigateToProduct(payload));
      });
    } on Exception catch (e) {
      logWarning('Cold-start notification handling failed: $e');
    }
  }

  /// Looks up the product by [barcode] and navigates to its detail screen.
  Future<void> _navigateToProduct(String barcode) async {
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      logWarning('No navigator context for notification tap');
      return;
    }

    try {
      final db = container.read(databaseProvider);
      final product = await db.getProduct(barcode);
      if (product == null) {
        logWarning('Product not found for barcode: $barcode');
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showInfo(context, l10n.productNotFound);
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

  /// Checks whether the cached product data needs refreshing and, if so,
  /// fires a background refresh for every inventory.
  Future<void> _scheduleCacheRefresh() async {
    try {
      final coordinator = container.read(cacheRefreshCoordinatorProvider);
      final refreshed = await coordinator.refreshIfOverdue();
      if (refreshed > 0) {
        container.invalidate(pantryProvider);
      }
    } on Exception catch (e) {
      logError('Scheduled cache refresh failed: $e');
    }
  }

  /// Removes stale inventory items and orphaned products.
  Future<void> _runDatabaseCleanup() async {
    try {
      logInfo('Starting database cleanup');
      final prefs = await SharedPreferences.getInstance();
      final retentionDays = prefs.getInt('retentionDays') ?? 60;
      final priceRetentionDays = prefs.getInt('priceRetentionDays') ?? 0;
      final dbHelper = container.read(databaseProvider);
      await dbHelper.cleanupOldEntries(
        retentionDays: retentionDays,
        priceRetentionDays: priceRetentionDays,
      );
      logInfo('Database cleanup completed');
    } on Exception catch (e) {
      logError('Database cleanup failed: $e');
    }
  }

  /// Reschedules expiry and inactivity reminders after startup via the
  /// [NotificationCoordinator].
  Future<void> _schedulePostInitNotifications() async {
    try {
      final coordinator = container.read(notificationCoordinatorProvider);
      final settings = await container.read(settingsProvider.future);
      await coordinator.rescheduleAll(
        l10n: _currentL10n(),
        settings: settings,
      );
    } on Exception catch (e) {
      logError('Notification reschedule failed: $e');
    }
  }

  /// Flushes queued product submissions to Open Food Facts.
  Future<void> _flushProductSubmissionQueue() async {
    logInfo('Checking for pending product submissions');
    try {
      final service = container.read(productSubmissionServiceProvider);
      final submitted = await service.flushQueue();
      if (submitted > 0) {
        logInfo('Flushed $submitted pending product submissions');
      }
    } on Exception catch (e) {
      logWarning('Product submission queue flush failed: $e');
    }
  }

  /// Reschedules all expiry reminders through the shared
  /// [NotificationCoordinator] after notification permission is granted.
  Future<void> _rescheduleNotifications() async {
    try {
      final coordinator = container.read(notificationCoordinatorProvider);
      final settings = await container.read(settingsProvider.future);
      await coordinator.rescheduleExpiryReminders(
        l10n: _currentL10n(),
        settings: settings,
      );
    } on Exception catch (e) {
      logError('Notification reschedule failed: $e');
    }
  }

  /// Resolves the [AppLocalizations] for the current device locale, falling
  /// back to English when the language is not supported.
  AppLocalizations _currentL10n() {
    final locale = PlatformDispatcher.instance.locale;
    return lookupAppLocalizations(
      <String>{'en', 'pt'}.contains(locale.languageCode)
          ? locale
          : const Locale('en'),
    );
  }

  static Future<void> _defaultDelay(Duration delay) =>
      Future<void>.delayed(delay);
}
