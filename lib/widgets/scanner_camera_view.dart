import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/scanner_error_content.dart';
import 'package:pantry_app/widgets/scanner_overlay_painter.dart';
import 'package:permission_handler/permission_handler.dart';

/// The camera-based barcode scanner view.
///
/// Watches [scannerCameraProvider] for streaming/error state and
/// [mobileScannerControllerProvider] for the [MobileScannerController].
/// Renders the camera preview, animated overlay (only when streaming),
/// and error content when an error occurs.
///
/// When [embedded] is true, the widget renders only the camera preview
/// (plus overlay and error content) without its own [Scaffold] or [AppBar],
/// so it can be placed inside a parent screen that owns the chrome (such as
/// the market trip). The AppBar actions (torch, PLU, manual entry) are
/// omitted in embedded mode; hosts provide their own controls.
class ScannerCameraView extends ConsumerStatefulWidget {
  /// Creates a [ScannerCameraView] widget.
  const ScannerCameraView({
    required this.onSwitchToManual,
    required this.onSwitchToPlu,
    this.embedded = false,
    super.key,
  });

  /// Called when the user switches to manual barcode entry.
  final VoidCallback onSwitchToManual;

  /// Called when the user switches to PLU code entry.
  final VoidCallback onSwitchToPlu;

  /// When true, renders only the camera preview without a surrounding
  /// [Scaffold]/[AppBar] so the host screen owns the chrome.
  final bool embedded;

  @override
  ConsumerState<ScannerCameraView> createState() => _ScannerCameraViewState();
}

class _ScannerCameraViewState extends ConsumerState<ScannerCameraView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_animationController.repeat(reverse: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logDebug('App lifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      unawaited(_retryOnResume());
    } else {
      _animationController.stop();
    }
  }

  Future<void> _retryOnResume() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        logInfo('Permission granted upon resume — retrying scanner');
        await ref.read(scannerCameraProvider.notifier).retryScanner();
      } else if (mounted) {
        logInfo('Permission still denied after resume — showing hint');
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showWarning(context, l10n.cameraPermissionDenied);
      }
    } on Exception catch (e) {
      logWarning('Resume retry failed: $e');
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    final state = ref.read(scannerCameraProvider);
    if (state.scanResolution != null) return;

    logInfo('Barcode scanned: $barcode');
    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      ref.read(scannerCameraProvider.notifier).resolveBarcode(barcode),
    );
  }

  void _onDetectionError(Object error, StackTrace stackTrace) {
    logException('Barcode detection error', error, stackTrace);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: ProgressIndicatorHelper.build(color: Colors.white),
      ),
    );
  }

  Future<void> _toggleTorch() async {
    logInfo('Torch toggle requested');
    await ref.read(scannerCameraProvider.notifier).toggleTorch();
  }

  Future<void> _openSettings() async {
    final l10n = AppLocalizations.of(context)!;
    final opened = await openAppSettings();
    if (!opened && mounted) {
      SnackbarHelper.showError(context, l10n.couldNotOpenSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scannerCameraProvider, (prev, next) {
      final wasStreaming = prev?.isStreaming ?? false;
      if (!wasStreaming &&
          next.isStreaming &&
          next.cameraError == null &&
          mounted) {
        if (!_animationController.isAnimating) {
          unawaited(_animationController.repeat(reverse: true));
        }
      }
    });

    final cameraState = ref.watch(scannerCameraProvider);
    final controller = ref.watch(mobileScannerControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (cameraState.cameraError != null) {
      final errorContent = ScannerErrorContent(
        exception: cameraState.cameraError!,
        onRetry: _retryOnResume,
        onSwitchToManual: widget.onSwitchToManual,
        onSwitchToPlu: widget.onSwitchToPlu,
        onOpenSettings: _openSettings,
      );
      if (widget.embedded) return errorContent;
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
        body: errorContent,
      );
    }

    final cameraBody = Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _onBarcodeDetected,
          onDetectError: _onDetectionError,
          placeholderBuilder: _buildPlaceholder,
          tapToFocus: true,
        ),
        if (cameraState.showOverlay)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (_, _) => CustomPaint(
                painter: ScannerOverlayPainter(
                  animationValue: _animationController.value,
                  hintText: l10n.scanHint,
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.embedded) return cameraBody;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanBarcode),
        actions: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, _) {
              final torch = controller.value.torchState;
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
            icon: const Icon(Icons.dialpad),
            tooltip: l10n.pluEntryTooltip,
            onPressed: widget.onSwitchToPlu,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.manualEntryTooltip,
            onPressed: widget.onSwitchToManual,
          ),
        ],
      ),
      body: cameraBody,
    );
  }
}
