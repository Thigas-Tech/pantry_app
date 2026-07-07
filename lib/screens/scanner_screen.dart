import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/scanner_overlay_painter.dart';
import 'package:permission_handler/permission_handler.dart';

/// A barcode input screen.
///
/// Offers two modes: camera scanner via [MobileScanner] and manual text entry.
///
/// The user is prompted for confirmation before navigating away with no result.
class ScannerScreen extends StatefulWidget {
  /// Creates a [ScannerScreen] widget.
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _showManualEntry = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final l10n = AppLocalizations.of(context)!;
        final stay = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.confirmExitScanner),
            content: Text(l10n.confirmExitScannerHint),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.stay),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.leave),
              ),
            ],
          ),
        );
        if (stay == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _showManualEntry
          ? _ManualEntryView(
              onSwitchToCamera: () {
                logInfo('Switched to camera scanner');
                setState(() => _showManualEntry = false);
              },
            )
          : _MobileScannerView(
              onSwitchToManual: () {
                logInfo('Switched to manual entry');
                setState(() => _showManualEntry = true);
              },
            ),
    );
  }
}

// ---------- Camera scanner ----------

class _MobileScannerView extends StatefulWidget {
  const _MobileScannerView({required this.onSwitchToManual});

  final VoidCallback onSwitchToManual;

  @override
  State<_MobileScannerView> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<_MobileScannerView>
    with SingleTickerProviderStateMixin {
  bool _hasScanned = false;
  bool _scannerErrorOccurred = false;
  int _scannerKey = 0;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_animationController.repeat(reverse: true));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _retry() {
    logInfo('Retrying scanner');
    _hasScanned = false;
    _scannerErrorOccurred = false;
    setState(() => _scannerKey++);
  }

  Future<void> _openSettings() async {
    logInfo('Opening app settings for camera permission');
    final l10n = AppLocalizations.of(context)!;
    final opened = await openAppSettings();
    if (!opened && mounted) {
      SnackbarHelper.showError(context, l10n.couldNotOpenPlayStore);
    }
  }

  Widget _buildError(BuildContext context, MobileScannerException exception) {
    logError('Scanner error: ${exception.errorCode.name}');
    if (!_scannerErrorOccurred) {
      _scannerErrorOccurred = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    return ScannerErrorContent(
      exception: exception,
      onRetry: _retry,
      onSwitchToManual: widget.onSwitchToManual,
      onOpenSettings: _openSettings,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return const ColoredBox(
      color: Colors.black87,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanBarcode),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.manualEntryTooltip,
            onPressed: widget.onSwitchToManual,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            key: ValueKey(_scannerKey),
            onDetect: (capture) {
              if (_hasScanned) {
                logInfo('Scan already captured — ignoring duplicate');
                return;
              }
              if (capture.barcodes.isEmpty) {
                logWarning('Barcode capture received with empty barcodes list');
                return;
              }
              final barcode = capture.barcodes.first;
              if (barcode.rawValue == null) return;
              _hasScanned = true;
              logInfo('Barcode scanned via camera: ${barcode.rawValue}');
              unawaited(HapticFeedback.mediumImpact());
              Navigator.of(context).pop(barcode.rawValue);
            },
            onDetectError: (error, stackTrace) {
              logException('Barcode detection error', error, stackTrace);
            },
            errorBuilder: _buildError,
            placeholderBuilder: _buildPlaceholder,
          ),
          if (!_scannerErrorOccurred)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: ScannerOverlayPainter(
                    animationValue: _animationController.value,
                    hintText: l10n.scanHint,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Displays scanner error content based on the error code.
///
/// Used as the [MobileScanner.errorBuilder] content. Extracted as a separate
/// widget so it can be tested with specific error codes.
@visibleForTesting
class ScannerErrorContent extends StatelessWidget {
  /// Creates a [ScannerErrorContent] widget.
  const ScannerErrorContent({
    required this.exception,
    required this.onRetry,
    required this.onSwitchToManual,
    required this.onOpenSettings,
    super.key,
  });

  /// The exception that caused the scanner error.
  final MobileScannerException exception;

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  /// Called when the user switches to manual barcode entry.
  final VoidCallback onSwitchToManual;

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

// ---------- Manual entry ----------

class _ManualEntryView extends StatefulWidget {
  const _ManualEntryView({required this.onSwitchToCamera});

  final VoidCallback onSwitchToCamera;

  @override
  State<_ManualEntryView> createState() => _ManualEntryViewState();
}

class _ManualEntryViewState extends State<_ManualEntryView> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      logInfo('Barcode entered manually: $text');
      unawaited(HapticFeedback.mediumImpact());
      Navigator.of(context).pop(text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.enterBarcode),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: l10n.cameraTooltip,
            onPressed: widget.onSwitchToCamera,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.typeOrPasteBarcode, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.barcodeLabel,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(l10n.submit),
            ),
          ],
        ),
      ),
    );
  }
}
