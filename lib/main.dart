import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/config.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/pantry_shell.dart';
import 'package:pantry_app/services/app_startup_service.dart';
import 'package:pantry_app/services/notification_background_handler.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/navigator_key.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

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
/// 3. App version comparison (one fast platform call) via
///    [AppStartupService.checkAppUpdateBeforeFrame]; the changelog flag and
///    post-update cache flush run after the first frame.
/// 4. Firebase initialized; the anonymous sign-in (a network call) is
///    deferred until after the first frame.
/// 5. Notification service initialized (timezone, channel, plugin).
/// 6. Notification permission requested (system dialog, after first frame).
/// 7. Database cleanup, feedback flush, cache refresh (after first frame),
///    all owned by [AppStartupService.schedulePostInitTasks].
/// 8. App launched inside [UncontrolledProviderScope] so all providers
///    share the same [appContainer].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SnackbarHelper.messengerKey = rootMessengerKey;

  if (kDebugMode) {
    SemanticsBinding.instance.ensureSemantics();
  }

  await dotenv.load(isOptional: true);
  logInfo('Environment loaded');

  // Create the shared container before any startup task that needs
  // services, so everything (including the app-update check) consumes the
  // same singleton instances as the widget tree.
  appContainer = ProviderContainer();
  final appStartup = AppStartupService(container: appContainer);

  if (AppConfig.firebaseEnabled) {
    try {
      await Firebase.initializeApp();
      logInfo('Firebase initialized successfully');
    } on Exception catch (e) {
      logWarning('Firebase init failed (graceful degradation): $e');
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

  await appStartup.checkAppUpdateBeforeFrame();

  try {
    final notifService = appContainer.read(notificationServiceProvider);
    await notifService.initialize(
      onDidReceiveResponse: appStartup.handleNotificationTap,
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
    unawaited(appStartup.schedulePostInitTasks());
  });

  // Anonymous sign-in is a network call; defer it past the first frame so
  // a slow or blocked network cannot delay startup. The Firebase cache
  // path already degrades gracefully when auth is unavailable.
  unawaited(appStartup.signInAnonymously());

  // Notification permission request — needs the Activity to be visible.
  // This runs ~100ms after the first frame so the system dialog does not
  // overlap the initial UI setup.
  unawaited(
    Future<void>.delayed(
      const Duration(milliseconds: 100),
      appStartup.requestNotificationPermission,
    ),
  );
}

/// The root widget of the Pantry application.
class PantryApp extends ConsumerWidget {
  /// Creates a [PantryApp] widget.
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeOption =
        ref.watch(themeModeProvider).value ?? ThemeModeOption.system;
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

        final settings = ref.watch(settingsProvider).value ?? const Settings();
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
