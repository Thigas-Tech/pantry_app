import 'package:flutter/material.dart';

/// A thin wrapper around [ScaffoldMessenger] that shows styled snackbars.
///
/// Every method shows a floating snackbar with a short duration, rounded
/// corners, and a leading icon that matches the severity level.
///
/// ## Usage
///
/// ```dart
/// SnackbarHelper.showInfo(context, 'Product found');
/// SnackbarHelper.showWarning(context, 'Expiring soon');
/// SnackbarHelper.showError(context, 'Export failed');
/// ```
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
