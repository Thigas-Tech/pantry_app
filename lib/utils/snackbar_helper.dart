import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/logger.dart';

/// A thin wrapper around [ScaffoldMessenger] that shows styled snackbars.
///
/// Every method displays a floating snackbar with rounded corners, a leading
/// icon that matches the severity level, and a **short auto‑dismiss duration**.
/// Info, warning, and error snackbars disappear after 3 seconds **without any
/// user interaction**. The undo snackbar stays for 5 seconds to give the user
/// time to tap the undo action, and then dismisses automatically.
///
/// To ensure snackbars survive route transitions (e.g., when shown right
/// before popping a page), assign a [GlobalKey<ScaffoldMessengerState>] to
/// [messengerKey] and pass the same key to
/// [MaterialApp.scaffoldMessengerKey]. The helper will then use the root
/// messenger rather than the current route's messenger.
class SnackbarHelper {
  const SnackbarHelper._();

  /// A global key for the root scaffold messenger.
  ///
  /// When set, all snackbars are shown through this key, making them
  /// independent of the current route's [ScaffoldMessenger]. This is
  /// especially useful when a snackbar is shown immediately before a
  /// [Navigator.pop].
  ///
  /// Example:
  /// ```dart
  /// final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();
  ///
  /// MaterialApp(
  ///   scaffoldMessengerKey: rootMessengerKey,
  ///   // ...
  /// );
  ///
  /// SnackbarHelper.messengerKey = rootMessengerKey;
  /// ```
  static GlobalKey<ScaffoldMessengerState>? messengerKey;

  /// Shows an informational snackbar (blue) that auto-dismisses after 3 seconds
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
    );
    logInfo('Info from SnackBar: $message');
  }

  /// Shows a warning snackbar (amber) that auto-dismisses after 3 seconds.
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.amber.shade800,
      foregroundColor: Colors.white,
    );
    logWarning('Warning from SnackBar: $message');
  }

  /// Shows an error snackbar (red) that auto-dismisses after 3 seconds.
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
    );
    logError('Error from SnackBar: $message');
  }

  /// Shows an info snackbar with an **undo** action, auto-dismissing after
  /// 5 seconds.
  static void showUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo,
  ) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      onUndo: onUndo,
      undoLabel: AppLocalizations.of(context)!.undo,
      duration: const Duration(seconds: 5),
    );
    logInfo('Info from SnackBar (undo): $message');
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    VoidCallback? onUndo,
    String? undoLabel,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      action: onUndo != null && undoLabel != null
          ? SnackBarAction(label: undoLabel, onPressed: onUndo)
          : null,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: duration,
    );

    final messenger = messengerKey?.currentState;
    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }
}
