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
/// **Important:** If you show a snackbar immediately before popping the
/// current route (for example, after a successful save), the snackbar may
/// become stuck because its timer is tied to the now‑removed scaffold.
/// Prefer to delay the navigation slightly, or use a root
/// [ScaffoldMessenger] that outlives the page.
class SnackbarHelper {
  const SnackbarHelper._();

  /// Shows an informational snackbar (blue) that auto-dismisses after 3 seconds
  ///
  /// No dismiss button is shown – the snackbar simply fades out.
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
  ///
  /// The undo button label is resolved from the app's active locale via
  /// [AppLocalizations].
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

  /// Internal helper that builds and shows the snackbar.
  ///
  /// When [onUndo] and [undoLabel] are both provided, a [SnackBarAction] is
  /// added (e.g., for undo). Otherwise no action button is shown and the
  /// snackbar relies solely on [duration] to auto-dismiss. The default
  /// [duration] is 3 seconds.
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
      // Only show an action button when an undo callback is supplied.
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
