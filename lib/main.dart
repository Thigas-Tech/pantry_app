import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/services/notification_service.dart';

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
/// 3. **Database cleanup** – removes inventory entries that are older than 60
///    days and deletes any product records that are no longer referenced by
///    inventory items. This keeps the local SQLite database small and fast.
///    This step is awaited because we want to finish purging stale data before
///    the UI tries to display the inventory list.
/// 4. **Riverpod scope** – wraps the entire app in a [ProviderScope] so that
///    all Riverpod providers are available throughout the widget tree.
///
/// After these steps, the [PantryApp] widget is launched.
void main() async {
  // Ensure that Flutter’s platform bindings are initialised.
  WidgetsFlutterBinding.ensureInitialized();

  // Request permission on Android 13+ (POST_NOTIFICATIONS).
  // If the user denies, notifications will simply not appear, which is
  // acceptable for a pantry manager.
  unawaited(NotificationService.requestPermission());

  // Remove items that haven’t been re‑added in 60 days.
  // This prevents the database from growing indefinitely.
  final dbHelper = DatabaseHelper();
  await dbHelper.cleanupOldEntries();

  // Start the app with Riverpod dependency injection.
  runApp(const ProviderScope(child: PantryApp()));
}

/// The root widget of the Pantry application.
///
/// [PantryApp] is a minimal [MaterialApp] that:
/// - Sets the app title to “Pantry” (used by the OS task switcher).
/// - Configures a Material 3 theme with a teal colour scheme.
/// - Directly shows the [HomeScreen] as the initial route.
///
/// No routing or authentication logic is needed at this stage – the app is
/// intentionally single‑screen with modal navigation for scanning and detail
/// views.
class PantryApp extends StatelessWidget {
  /// Creates a [PantryApp] widget.
  ///
  /// The [key] parameter is forwarded to the superclass and can be used by
  /// tests or parent widgets to control this widget’s identity.
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pantry',
      // Material 3 provides a fresh, modern look with automatic colour
      // generation from the seed colour.
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
