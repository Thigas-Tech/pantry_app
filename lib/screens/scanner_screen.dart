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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _hasScanned = false;
  MobileScannerException? _currentException;
  int _scannerKey = 0;

  late final AnimationController _animationController;
  late final MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_animationController.repeat(reverse: true));
    _scannerController = MobileScannerController(autoZoom: true);
    _scannerController.addListener(_onScannerStateChanged);
    unawaited(_requestCameraPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.removeListener(_onScannerStateChanged);
    _animationController.dispose();
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _animationController.stop();
      case AppLifecycleState.resumed:
        unawaited(_animationController.repeat(reverse: true));
    }
  }

  void _onScannerStateChanged() {
    final error = _scannerController.value.error;
    if (error != null && _currentException == null) {
      logError('Scanner controller error: ${error.errorCode.name}');
      _currentException = error;
      if (mounted) setState(() {});
    }
  }

  Future<void> _requestCameraPermission() async {
    logInfo('Checking camera permissions');
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        logInfo('Camera permission already granted');
        return;
      }
      if (status.isPermanentlyDenied) {
        logWarning('Camera permission permanently denied');
        _setError(
          const MobileScannerException(
            errorCode: MobileScannerErrorCode.permissionDenied,
          ),
        );
        return;
      }
      final result = await Permission.camera.request();
      if (result.isGranted) {
        logInfo('Camera permission granted');
      } else if (result.isPermanentlyDenied) {
        logWarning('Camera permission permanently denied after request');
        _setError(
          const MobileScannerException(
            errorCode: MobileScannerErrorCode.permissionDenied,
          ),
        );
      } else {
        logWarning('Camera permission denied');
        _setError(
          const MobileScannerException(
            errorCode: MobileScannerErrorCode.permissionDenied,
          ),
        );
      }
    } on Exception catch (e) {
      logWarning('Camera permission check failed (likely in test): $e');
    }
  }

  void _setError(MobileScannerException exception) {
    if (_currentException != null) return;
    _currentException = exception;
    if (mounted) setState(() {});
  }

  void _retry() {
    logInfo('Retrying scanner');
    _hasScanned = false;
    _currentException = null;
    setState(() => _scannerKey++);
    unawaited(_requestCameraPermission());
  }

  Future<void> _openSettings() async {
    logInfo('Opening app settings for camera permission');
    final l10n = AppLocalizations.of(context)!;
    final opened = await openAppSettings();
    if (!opened && mounted) {
      SnackbarHelper.showError(context, l10n.couldNotOpenSettings);
    }
  }

  void _toggleTorch() {
    unawaited(_scannerController.toggleTorch());
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) {
      logInfo('Scan already captured -- ignoring duplicate');
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
    if (context.mounted) {
      Navigator.of(context).pop(barcode.rawValue);
    }
  }

  void _onDetectionError(Object error, StackTrace stackTrace) {
    logException('Barcode detection error', error, stackTrace);
  }

  Widget _onScannerError(
    BuildContext context,
    MobileScannerException exception,
  ) {
    if (_currentException == null) {
      _currentException = exception;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    return _buildErrorContent(exception);
  }

  Widget _buildErrorContent(MobileScannerException exception) {
    logError('Scanner error: ${exception.errorCode.name}');
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

    if (_currentException != null) {
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
        body: _buildErrorContent(_currentException!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanBarcode),
        actions: [
          AnimatedBuilder(
            animation: _scannerController,
            builder: (_, _) {
              final torch = _scannerController.value.torchState;
              final available = torch != TorchState.unavailable;
              return IconButton(
                icon: Icon(
                  torch == TorchState.on ? Icons.flash_on : Icons.flash_off,
                ),
                tooltip: l10n.toggleTorch,
                onPressed: available ? _toggleTorch : null,
              );
            },
          ),
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
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
            onDetectError: _onDetectionError,
            errorBuilder: _onScannerError,
            placeholderBuilder: _buildPlaceholder,
            tapToFocus: true,
          ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, _) => CustomPaint(
              painter: ScannerOverlayPainter(
                animationValue: _animationController.value,
                hintText: l10n.scanHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays scanner error content based on the error code.
///
/// Extracted as a separate widget so it can be tested with specific error
/// codes.
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
    if (text.isEmpty || text.length < 8 || !RegExp(r'^\d+$').hasMatch(text)) {
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showWarning(context, l10n.invalidBarcode);
      return;
    }
    logInfo('Barcode entered manually: $text');
    unawaited(HapticFeedback.mediumImpact());
    Navigator.of(context).pop(text);
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
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
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
      ),
    );
  }
}
