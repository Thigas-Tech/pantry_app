import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/logger.dart';

/// A thin wrapper around [ScaffoldMessenger] that shows styled snackbars.
///
/// Every method shows a floating snackbar with a short duration, rounded
/// corners, and a leading icon that matches the severity level.
///
/// See [SnackbarHelper.showInfo], [SnackbarHelper.showWarning],
/// [SnackbarHelper.showError], and [SnackbarHelper.showUndo].
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
  /// added to the snackbar. When neither is provided, a dismiss action is
  /// added instead. The [duration] defaults to 3 seconds; undo snackbars
  /// typically use 5 seconds.
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
      action: onUndo != null
          ? SnackBarAction(label: undoLabel!, onPressed: onUndo)
          : SnackBarAction(
              label: AppLocalizations.of(context)!.dismiss,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
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
