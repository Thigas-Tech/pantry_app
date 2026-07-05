import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';
import 'package:pantry_app/utils/logger.dart';

/// Entry point of the Pantry application.
///
/// Startup sequence:
/// 1. Flutter binding.
/// 2. Environment variables loaded via `flutter_dotenv`.
/// 3. Connectivity check; if online, refresh cached product data.
/// 4. Notification permission request and initialization.
/// 5. Database cleanup (after first frame).
/// 6. App launched inside `ProviderScope`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  logInfo('Environment loaded');

  final isOnline = await InternetConnectionChecker.instance.hasConnection;
  if (isOnline) {
    logInfo('Connected — refreshing cached products');
    unawaited(_refreshCachedProducts());
  } else {
    logInfo('Offline — skipping cached product refresh');
  }

  runApp(const ProviderScope(child: PantryApp()));
  logInfo('App started');

  final container = ProviderContainer();
  unawaited(container.read(notificationServiceProvider).requestPermission());
  await container.read(notificationServiceProvider).initialize();
  unawaited(_runDatabaseCleanup(container));
}

Future<void> _refreshCachedProducts() async {
  logInfo('Starting cached product refresh');
  try {
    final dbHelper = DatabaseHelper();
    final products = await dbHelper.getAllProducts();
    if (products.isEmpty) {
      logInfo('No cached products to refresh');
      return;
    }
    logInfo('Refreshing ${products.length} cached products');
    final api = OpenFoodFactsApi(
      Dio(),
      userId: AppConfig.offUserId,
      password: AppConfig.offPassword,
      contactEmail: AppConfig.contactEmail,
    );
    for (final product in products) {
      try {
        final updated = await api.getByBarcode(product.barcode);
        await dbHelper.insertProduct(updated);
      } on Exception {
        // Skip individual failures; continue with next product.
      }
    }
    logInfo('Cached product refresh completed');
  } on Exception catch (e) {
    logError('Cached product refresh failed: $e');
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
          home: const HomeScreen(),
        );
      },
    );
  }
}
