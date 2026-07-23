import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

/// Displays scanner error content based on the error code.
@visibleForTesting
class ScannerErrorContent extends StatelessWidget {
  /// Creates a [ScannerErrorContent] widget.
  const ScannerErrorContent({
    required this.exception,
    required this.onRetry,
    required this.onSwitchToManual,
    required this.onSwitchToPlu,
    required this.onOpenSettings,
    super.key,
  });

  /// The exception that caused the scanner error.
  final MobileScannerException exception;

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  /// Called when the user switches to manual barcode entry.
  final VoidCallback onSwitchToManual;

  /// Called when the user switches to PLU code entry.
  final VoidCallback onSwitchToPlu;

  /// Called when the user wants to open app settings.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errorCode = exception.errorCode;

    String message;
    List<Widget> actions;

    switch (errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = l10n.cameraPermissionDenied;
        actions = [
          TextButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings, color: Colors.white),
            label: Text(
              l10n.openSettings,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton.icon(
            onPressed: onSwitchToPlu,
            icon: const Icon(Icons.dialpad, color: Colors.white70),
            label: Text(
              l10n.pluEntryTooltip,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton.icon(
            onPressed: onSwitchToManual,
            icon: const Icon(Icons.edit, color: Colors.white70),
            label: Text(
              l10n.switchToManualEntry,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ];
      case MobileScannerErrorCode.unsupported:
        message = l10n.cameraNotAvailable;
        actions = [
          TextButton.icon(
            onPressed: onSwitchToPlu,
            icon: const Icon(Icons.dialpad, color: Colors.white),
            label: Text(
              l10n.pluEntryTooltip,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton.icon(
            onPressed: onSwitchToManual,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: Text(
              l10n.switchToManualEntry,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ];
      case MobileScannerErrorCode.controllerAlreadyInitialized:
      case MobileScannerErrorCode.controllerDisposed:
      case MobileScannerErrorCode.controllerUninitialized:
      case MobileScannerErrorCode.controllerInitializing:
      case MobileScannerErrorCode.controllerNotAttached:
      case MobileScannerErrorCode.genericError:
        message = l10n.scannerGenericError;
        actions = [
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              l10n.retryScan,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton.icon(
            onPressed: onSwitchToPlu,
            icon: const Icon(Icons.dialpad, color: Colors.white70),
            label: Text(
              l10n.pluEntryTooltip,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton.icon(
            onPressed: onSwitchToManual,
            icon: const Icon(Icons.edit, color: Colors.white70),
            label: Text(
              l10n.switchToManualEntry,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ];
    }

    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Icon(Icons.error_outline, color: Colors.white, size: 56),
              ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
