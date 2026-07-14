import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/produce_quick_add_item.dart';
import 'package:pantry_app/services/plu_service.dart';
import 'package:pantry_app/services/produce_icon_service.dart';
import 'package:pantry_app/services/produce_purchase_tracker.dart';
import 'package:pantry_app/services/produce_serving_presets.dart';
import 'package:pantry_app/services/scan_result.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/quick_add_produce.dart';
import 'package:pantry_app/widgets/scanner_overlay_painter.dart';
import 'package:permission_handler/permission_handler.dart';

/// A unified input screen for barcodes and produce PLU codes.
///
/// Offers three modes:
/// - Camera scanner via [MobileScanner] for barcodes.
/// - Manual barcode text entry.
/// - PLU code entry via numeric keypad for produce without barcodes.
///
/// Returns a [ScanResult] via [Navigator.pop]. The user is prompted for
/// confirmation before navigating away with no result.
class ScannerScreen extends StatefulWidget {
  /// Creates a [ScannerScreen] widget.
  ///
  /// [pluService] can be injected for testing. When omitted, a default
  /// [PluService] instance is used.
  const ScannerScreen({this.pluService, super.key});

  /// The PLU code→name lookup service.
  final PluService? pluService;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _showManualEntry = false;
  bool _showPluEntry = false;
  List<ProduceQuickAddItem> _quickAddItems = [];
  bool _quickAddLoading = false;

  PluService get _pluService => widget.pluService ?? const PluService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadQuickAddItems());
    });
  }

  Future<void> _loadQuickAddItems() async {
    if (_quickAddLoading) return;
    setState(() => _quickAddLoading = true);
    try {
      // Scanner shows only default produce list for quick adding.
      // Full personalization + seasonal is on the HomeScreen.
      final items = ProducePurchaseTracker.getDefaultList().map((name) {
        return ProduceQuickAddItem(
          name: name.toLowerCase(),
          displayName: name,
          icon: ProduceIconService.forName(name),
          weightHintG: ProduceServingPresets.forName(name)?['Medium'],
          source: ProduceItemSource.fallback,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _quickAddItems = items;
          _quickAddLoading = false;
        });
      }
    } on Exception catch (e) {
      logWarning('Failed to load scanner quick-add: $e');
      if (mounted) setState(() => _quickAddLoading = false);
    }
  }

  Widget _buildQuickAddCarousel() {
    final l10n = AppLocalizations.of(context)!;
    if (_quickAddLoading) {
      return const SizedBox(height: 48, child: SizedBox.shrink());
    }
    return QuickAddProduce(
      items: _quickAddItems,
      onProduceSelected: (_) {
        // Quick-add on the scanner screen does nothing — items are
        // added from the HomeScreen carousel. The scanner's carousel
        // serves as a visual reference and can be added later.
        return;
      },
      sectionTitle: l10n.quickAddProduceTitle,
      infoTooltip: l10n.quickAddProduceTooltip,
      emptyMessage: l10n.quickAddProduceEmpty,
    );
  }

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
      child: Column(
        children: [
          Expanded(child: _buildCurrentMode()),
          _buildQuickAddCarousel(),
        ],
      ),
    );
  }

  Widget _buildCurrentMode() {
    if (_showPluEntry) {
      return _PluEntryView(
        pluService: _pluService,
        onSwitchToCamera: () {
          logInfo('Switched to camera scanner from PLU');
          setState(() {
            _showPluEntry = false;
            _showManualEntry = false;
          });
        },
      );
    }
    if (_showManualEntry) {
      return _ManualEntryView(
        onSwitchToCamera: () {
          logInfo('Switched to camera scanner');
          setState(() => _showManualEntry = false);
        },
      );
    }
    return _MobileScannerView(
      onSwitchToManual: () {
        logInfo('Switched to manual entry');
        setState(() => _showManualEntry = true);
      },
      onSwitchToPlu: () {
        logInfo('Switched to PLU entry');
        setState(() => _showPluEntry = true);
      },
    );
  }
}

// ---------- Camera scanner ----------

/// The camera scanner view that uses [MobileScanner] to scan barcodes.
///
/// Displays a camera preview with an animated overlay and handles
/// permission requests, errors, and torch control.
class _MobileScannerView extends StatefulWidget {
  const _MobileScannerView({
    required this.onSwitchToManual,
    required this.onSwitchToPlu,
  });

  /// Callback to switch to manual barcode entry.
  final VoidCallback onSwitchToManual;

  /// Callback to switch to PLU code entry.
  final VoidCallback onSwitchToPlu;

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
        unawaited(_checkPermissionAndRetry());
    }
  }

  Future<void> _checkPermissionAndRetry() async {
    final status = await Permission.camera.status;
    if (status.isGranted &&
        _currentException?.errorCode ==
            MobileScannerErrorCode.permissionDenied) {
      logInfo('Permission granted upon resume — retrying scanner');
      _retry();
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
        if (_currentException != null) {
          _retry();
        }
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
      Navigator.of(context).pop(BarcodeResult(barcode.rawValue!));
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
      onSwitchToPlu: widget.onSwitchToPlu,
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
      ),
    );
  }
}

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

// ---------- Manual entry ----------

/// A widget that allows the user to type or paste a barcode number.
///
/// Validates that the input is numeric and of sufficient length before
/// popping the screen with a [BarcodeResult].
class _ManualEntryView extends StatefulWidget {
  const _ManualEntryView({required this.onSwitchToCamera});

  /// Callback to switch back to the camera scanner.
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
    Navigator.of(context).pop(BarcodeResult(text));
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

// ---------- PLU entry ----------

/// A widget for entering PLU (Price Look-Up) codes for produce.
///
/// Uses a numeric keypad optimized for 4-5 digit codes. Each digit press
/// triggers an immediate lookup via [PluService]; when a match is found
/// the produce name is shown and the user can confirm.
class _PluEntryView extends StatefulWidget {
  const _PluEntryView({
    required this.pluService,
    required this.onSwitchToCamera,
  });

  /// The PLU lookup service.
  final PluService pluService;

  /// Callback to switch back to the camera scanner.
  final VoidCallback onSwitchToCamera;

  @override
  State<_PluEntryView> createState() => _PluEntryViewState();
}

class _PluEntryViewState extends State<_PluEntryView> {
  String _code = '';
  PluEntry? _matchedEntry;

  void _onDigit(String digit) {
    if (_code.length >= 5) return;
    setState(() {
      _code += digit;
      _matchedEntry = widget.pluService.lookup(_code);
    });
  }

  void _onDelete() {
    if (_code.isEmpty) return;
    setState(() {
      _code = _code.substring(0, _code.length - 1);
      _matchedEntry = widget.pluService.lookup(_code.isEmpty ? '' : _code);
    });
  }

  void _onConfirm() {
    if (_matchedEntry == null) return;
    logInfo('PLU confirmed: ${_matchedEntry!.code} — ${_matchedEntry!.name}');
    unawaited(HapticFeedback.mediumImpact());
    Navigator.of(context).pop(
      PluResult(
        pluCode: _matchedEntry!.code,
        produceName: _matchedEntry!.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.enterPluCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: l10n.cameraTooltip,
            onPressed: widget.onSwitchToCamera,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Code display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _code.isEmpty ? '----' : _code.padRight(5, '_'),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                letterSpacing: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Matched name
          SizedBox(
            height: 32,
            child: _matchedEntry != null
                ? Text(
                    _matchedEntry!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : _code.length >= 4
                ? Text(
                    l10n.pluCodeNotFound,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          // Numeric keypad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _key('1', l10n),
                    _key('2', l10n),
                    _key('3', l10n),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _key('4', l10n),
                    _key('5', l10n),
                    _key('6', l10n),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _key('7', l10n),
                    _key('8', l10n),
                    _key('9', l10n),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _deleteKey(l10n),
                    _key('0', l10n),
                    _confirmKey(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _key(String digit, AppLocalizations l10n) {
    return SizedBox(
      width: 72,
      height: 64,
      child: ElevatedButton(
        onPressed: () => _onDigit(digit),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24),
          semanticsLabel: '${l10n.digitLabel} $digit',
        ),
      ),
    );
  }

  Widget _deleteKey(AppLocalizations l10n) {
    return SizedBox(
      width: 72,
      height: 64,
      child: IconButton(
        onPressed: _code.isNotEmpty ? _onDelete : null,
        icon: const Icon(Icons.backspace_outlined),
        tooltip: l10n.deleteDigit,
      ),
    );
  }

  Widget _confirmKey() {
    return SizedBox(
      width: 72,
      height: 64,
      child: FilledButton(
        onPressed: _matchedEntry != null ? _onConfirm : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Icon(Icons.check),
      ),
    );
  }
}
