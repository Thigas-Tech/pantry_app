import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// The available theme modes for the app.
enum ThemeModeOption {
  /// Follow the system setting.
  system,

  /// Always use the light theme.
  light,

  /// Always use the dark theme.
  dark,
}

/// A [Notifier] that holds the current `ThemeModeOption`.
///
/// Used by [themeModeProvider] so that the settings screen (or any widget)
/// can read and change the theme mode via the `state` property.
class ThemeModeNotifier extends Notifier<ThemeModeOption> {
  @override
  ThemeModeOption build() => ThemeModeOption.system;
}

/// A [NotifierProvider] for [ThemeModeNotifier].
///
/// Changing the value triggers a rebuild of the [DynamicColorBuilder] and
/// the widget tree, switching between light, dark, and system themes.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeModeOption>(
  ThemeModeNotifier.new,
);

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
///    inventory entries older than 60 days and orphaned products. It no
///    longer blocks the initial render.
/// 4. **Riverpod scope** – wraps the entire app in a [ProviderScope] so that
///    all Riverpod providers are available throughout the widget tree.
///
/// After these steps, the [PantryApp] widget is launched.
void main() {
  // Ensure that Flutter’s platform bindings are initialised.
  WidgetsFlutterBinding.ensureInitialized();

  // Request permission on Android 13+ (POST_NOTIFICATIONS).
  unawaited(NotificationService.requestPermission());

  // Start the app immediately – database cleanup runs after the first frame.
  runApp(const ProviderScope(child: PantryApp()));
  logInfo('App started');

  // Run the cleanup in the background, now that the UI is visible.
  unawaited(_runDatabaseCleanup());
}

/// Removes stale inventory items and orphaned products without blocking the
/// UI thread.
Future<void> _runDatabaseCleanup() async {
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.cleanupOldEntries();
    logInfo('Database cleanup completed');
  } on Exception catch (e) {
    logError('Database cleanup failed: $e');
  }
}

/// The root widget of the Pantry application.
///
/// [PantryApp] is a [MaterialApp] that:
/// - Sets the app title to “Pantry” (used by the OS task switcher).
/// - Uses [DynamicColorBuilder] to seed the colour scheme from the device
///   wallpaper, falling back to a teal palette when dynamic colours are
///   unavailable.
/// - Respects the user’s theme preference (light, dark, or system) via
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
          home: const HomeScreen(),
        );
      },
    );
  }
}
