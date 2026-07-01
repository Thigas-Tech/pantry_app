import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Entry point of the Pantry application (Android).
///
/// This function performs all one‑time initialisation steps before the Flutter
/// framework takes over:
///
/// 1. **Flutter binding** – required to interact with the platform before
///    calling [runApp].
/// 2. **Notifications** – requests the Android notification permission
///    (POST_NOTIFICATIONS on Android 13+). The call is fire‑and‑forget using
///    [unawaited] because it is not critical for the first frame and must not
///    delay the app startup.
/// 3. **Database cleanup** – scheduled after the first frame to remove
///    inventory entries older than the user's configured retention period
///    and orphaned products. The retention days are read from
///    [settingsProvider]. The cleanup no longer blocks the initial render.
/// 4. **Riverpod scope** – wraps the entire app in a [ProviderScope] so that
///    all Riverpod providers are available throughout the widget tree.
///
/// After these steps, the [PantryApp] widget is launched.
void main() {
  // Ensure that Flutter's platform bindings are initialised.
  WidgetsFlutterBinding.ensureInitialized();

  // Request permission on Android 13+ (POST_NOTIFICATIONS).
  unawaited(NotificationService.requestPermission());

  // Start the app immediately – database cleanup runs after the first frame.
  runApp(const ProviderScope(child: PantryApp()));
  logInfo('App started');

  // Run the cleanup in the background, now that the UI is visible.
  final container = ProviderContainer();
  unawaited(_runDatabaseCleanup(container));
}

/// Removes stale inventory items and orphaned products without blocking the
/// UI thread.
///
/// The retention period is read from the user's settings via
/// [settingsProvider]. If no custom period has been set, the default of
/// 60 days is used. The [container] is disposed after the cleanup completes.
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
///
/// [PantryApp] is a [MaterialApp] that:
/// - Sets the app title to "Pantry" (used by the OS task switcher).
/// - Uses [DynamicColorBuilder] to seed the colour scheme from the device
///   wallpaper, falling back to a teal palette when dynamic colours are
///   unavailable.
/// - Respects the user's theme preference (light, dark, or system) via
///   [themeModeProvider].
/// - Directly shows the [HomeScreen] as the initial route.
///
/// No routing or authentication logic is needed at this stage – the app is
/// intentionally single‑screen with modal navigation for scanning and detail
/// views.
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
