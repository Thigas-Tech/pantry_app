import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shows a dialog explaining that the camera permission is required and
/// offering to open the system settings.
///
/// [openSettings] is injectable for tests and defaults to
/// [openAppSettings]. Returns when the dialog is dismissed.
Future<void> showCameraPermissionDialog(
  BuildContext context, {
  Future<bool> Function() openSettings = openAppSettings,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final shouldOpenSettings = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.cameraPermissionDeniedTitle),
      content: Text(l10n.cameraPermissionDeniedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.openSettings),
        ),
      ],
    ),
  );
  if (shouldOpenSettings == true) {
    final opened = await openSettings();
    if (!opened && context.mounted) {
      SnackbarHelper.showError(context, l10n.couldNotOpenSettings);
    }
  }
}
