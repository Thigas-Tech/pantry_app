import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/pantry_shell.dart';
import 'package:pantry_app/services/image_cache_service.dart';
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

  await _handleAppUpdate();

  runApp(const ProviderScope(child: PantryApp()));
  logInfo('App started');

  unawaited(_scheduleCacheRefresh());

  final container = ProviderContainer();
  unawaited(container.read(notificationServiceProvider).requestPermission());
  await container.read(notificationServiceProvider).initialize();
  unawaited(_runDatabaseCleanup(container));
}

/// Clears the product database and image cache when the app version changes.
///
/// This ensures products cached before the Nutri-Score badge feature (or any
/// other schema change) get re-fetched from Open Food Facts with fresh data.
///
/// The changelog tracking runs unconditionally (before the version-match
/// guard) so that the `[Unreleased]` section is still surfaced on upgrades
/// even when the app version string has not changed.
Future<void> _handleAppUpdate() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    final currentVersion = '${info.version}+${info.buildNumber}';
    final lastVersion = prefs.getString('app_version');

    // Changelog tracking — always runs, regardless of cache-flush guard.
    final lastSeenChangelog = prefs.getString('changelog_last_seen');
    if (lastSeenChangelog != null && lastSeenChangelog != currentVersion) {
      unawaited(prefs.setString('changelog_show_pending', 'true'));
      logInfo(
        'Changelog flagged: last seen $lastSeenChangelog, '
        'now $currentVersion',
      );
    }
    // Always store the current version so future updates are detected and
    // the parser knows where to start filtering (handles first install too).
    await prefs.setString('changelog_last_seen', currentVersion);

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
        final darkScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            );

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
