import 'package:flutter/material.dart';
import 'package:pantry_app/utils/logger.dart';

/// A thin wrapper around [ScaffoldMessenger] that shows styled snackbars.
///
/// Every method shows a floating snackbar with a short duration, rounded
/// corners, and a leading icon that matches the severity level.
///
/// See [SnackbarHelper.showInfo], [SnackbarHelper.showWarning], and
/// [SnackbarHelper.showError] for the individual severity levels.
class SnackbarHelper {
  const SnackbarHelper._();

  /// Shows an informational snackbar (blue).
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

  /// Shows a warning snackbar (amber).
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

  /// Shows an error snackbar (red).
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

  /// Shows an info snackbar with an undo action.
  static void showUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo,
  ) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: onUndo,
      ),
      backgroundColor: Colors.blue.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
    logInfo('Info from SnackBar (undo): $message');
  }

  /// Internal helper that builds and shows the snackbar.
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
