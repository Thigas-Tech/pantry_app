import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/scan_history_provider.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scanner_providers.g.dart';

// ---------------------------------------------------------------------------
// Scan resolution state
// ---------------------------------------------------------------------------

/// The state of a barcode or PLU resolution attempt.
sealed class ScanResolution {
  const ScanResolution();
}

/// A resolution attempt is in progress (loading state).
class ScanResolving extends ScanResolution {
  /// Creates a [ScanResolving] state.
  const ScanResolving();
}

/// A barcode or PLU was successfully resolved to a [Product].
class ScanResolved extends ScanResolution {
  /// Creates a [ScanResolved] state with the resolved [product].
  const ScanResolved(this.product);

  /// The resolved product.
  final Product product;
}

/// A barcode or PLU resolution attempt failed.
class ScanFailed extends ScanResolution {
  /// Creates a [ScanFailed] state with an error [message].
  ///
  /// [barcode] carries the barcode that failed to resolve, when known, so
  /// callers can act on it (e.g. open a contribution form).
  const ScanFailed(this.message, {this.barcode});

  /// The error message describing why resolution failed.
  final String message;

  /// The barcode that failed to resolve, when known.
  final String? barcode;
}

// ---------------------------------------------------------------------------
// Camera state
// ---------------------------------------------------------------------------

/// Immutable state for the scanner camera preview and scan resolution.
class ScannerCameraState {
  /// Creates a [ScannerCameraState] with the given values.
  const ScannerCameraState({
    this.isStreaming = false,
    this.isStarting = false,
    this.cameraError,
    this.torchState = TorchState.unavailable,
    this.scannerKey = 0,
    this.scanResolution,
  });

  /// Whether the camera preview is actively streaming.
  final bool isStreaming;

  /// Whether the camera controller is in the process of starting.
  final bool isStarting;

  /// The current camera error, if any.
  final MobileScannerException? cameraError;

  /// The current torch / flashlight state.
  final TorchState torchState;

  /// Incremented to force-rebuild the [MobileScanner] widget on retry.
  final int scannerKey;

  /// The current scan resolution attempt, if any.
  final ScanResolution? scanResolution;

  /// Whether the overlay should be drawn on top of the camera preview.
  bool get showOverlay => isStreaming && cameraError == null;

  /// Creates a copy of this state with the given fields replaced.
  ScannerCameraState copyWith({
    bool? isStreaming,
    bool? isStarting,
    MobileScannerException? cameraError,
    TorchState? torchState,
    int? scannerKey,
    ScanResolution? scanResolution,
    bool clearError = false,
    bool clearScanResolution = false,
  }) {
    return ScannerCameraState(
      isStreaming: isStreaming ?? this.isStreaming,
      isStarting: isStarting ?? this.isStarting,
      cameraError: clearError ? null : (cameraError ?? this.cameraError),
      torchState: torchState ?? this.torchState,
      scannerKey: scannerKey ?? this.scannerKey,
      scanResolution: clearScanResolution
          ? null
          : (scanResolution ?? this.scanResolution),
    );
  }
}

// ---------------------------------------------------------------------------
// Controller provider
// ---------------------------------------------------------------------------

/// Provides a [MobileScannerController] for the scanner camera.
///
/// Created lazily and disposed when the provider is no longer watched
/// (auto-dispose). The controller is created with autoStart false so
/// that permission is checked before calling [MobileScannerController.start].
@riverpod
MobileScannerController mobileScannerController(Ref ref) {
  final controller = MobileScannerController(
    autoStart: false,
    autoZoom: true,
  );
  ref.onDispose(controller.dispose);
  return controller;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Notifier that manages the scanner camera lifecycle and scan resolution.
///
/// Owns the [MobileScannerController] (created with autoStart false),
/// tracks camera streaming state, handles permission requests, and resolves
/// barcodes/PLU codes via [productRepositoryProvider].
@riverpod
class ScannerCamera extends _$ScannerCamera {
  MobileScannerController? _controller;

  @override
  ScannerCameraState build() {
    _controller = ref.watch(mobileScannerControllerProvider);
    ref.onDispose(() {
      _controller?.removeListener(_onControllerState);
      _controller = null;
    });

    _controller!.addListener(_onControllerState);

    // Kick off permission check (async — controller starts on grant).
    unawaited(_checkPermission());

    return const ScannerCameraState();
  }

  void _onControllerState() {
    final ms = _controller!.value;
    if (ms.error != null && ms.error != state.cameraError) {
      logWarning('Camera error: ${ms.error!.errorCode.name}');
    }
    state = state.copyWith(
      isStreaming: ms.isRunning,
      isStarting: ms.isStarting,
      cameraError: ms.error,
      torchState: ms.torchState,
    );
  }

  Future<void> _checkPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        logInfo('Camera permission already granted — starting controller');
        await _startController();
      } else if (status.isPermanentlyDenied) {
        logWarning('Camera permission permanently denied');
        _setPermissionDenied();
      } else {
        logInfo('Camera permission not yet determined — requesting');
        await requestPermission();
      }
    } on Exception catch (e) {
      logWarning('Camera permission check failed: $e');
    }
  }

  /// Requests camera permission and starts the controller if granted.
  Future<void> requestPermission() async {
    try {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        logInfo('Camera permission granted after request');
        state = state.copyWith(clearError: true);
        await _startController();
      } else if (result.isPermanentlyDenied) {
        logWarning('Camera permission permanently denied after request');
        _setPermissionDenied();
      } else {
        logWarning('Camera permission denied');
        _setPermissionDenied();
      }
    } on Exception catch (e) {
      logWarning('Camera permission request failed: $e');
    }
  }

  void _setPermissionDenied() {
    logWarning('Setting permission denied error in state');
    state = state.copyWith(
      cameraError: const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      ),
    );
  }

  /// Retries scanner after an error: clears error state, increments
  /// the scanner key so the [MobileScanner] widget recreates itself, and
  /// restarts the controller.
  Future<void> retryScanner() async {
    state = state.copyWith(
      isStreaming: false,
      scannerKey: state.scannerKey + 1,
      clearError: true,
    );
    // Start the controller directly — permission was checked when the user
    // tapped retry (the caller should ensure permission is granted).
    await _startController();
  }

  Future<void> _startController() async {
    if (_controller == null) return;
    logInfo('Starting camera controller');
    try {
      await _controller!.start();
      logInfo('Camera controller started successfully');
    } on Exception catch (e) {
      logWarning('Camera controller failed to start: $e');
    }
  }

  /// Stops the camera controller to save resources when the user switches
  /// to manual or PLU entry mode.
  Future<void> stopCamera() async {
    logInfo('Stopping camera controller');
    try {
      await _controller?.stop();
      state = state.copyWith(isStreaming: false);
    } on Exception catch (e) {
      logWarning('Failed to stop camera: $e');
    }
  }

  /// Toggles the camera torch on / off.
  Future<void> toggleTorch() async {
    logInfo('Toggling torch');
    try {
      await _controller?.toggleTorch();
    } on Exception catch (e) {
      logWarning('Torch toggle failed: $e');
    }
  }

  /// Resolves a [barcode] via [productRepositoryProvider].
  ///
  /// Sets [ScanResolved] on success or [ScanFailed] on failure. Calls while
  /// a resolution is already in progress are silently ignored.
  ///
  /// If resolution takes longer than [timeout], a [TimeoutException] is
  /// caught and [ScanFailed] with message 'TIMEOUT' is emitted.
  Future<void> resolveBarcode(
    String barcode, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (state.scanResolution != null) return;
    logInfo('Resolving barcode: $barcode');
    state = state.copyWith(scanResolution: const ScanResolving());
    try {
      final repo = ref.read(productRepositoryProvider);
      final product = await repo.getProduct(barcode).timeout(timeout);
      logInfo('Barcode resolved: ${product.name}');
      state = state.copyWith(scanResolution: ScanResolved(product));
      await _recordScan(product);
    } on ProductNotFoundException {
      logInfo('Product not found for barcode: $barcode');
      state = state.copyWith(
        scanResolution: ScanFailed('PRODUCT_NOT_FOUND', barcode: barcode),
      );
    } on TimeoutException {
      logWarning('Barcode resolution timed out: $barcode');
      state = state.copyWith(scanResolution: const ScanFailed('TIMEOUT'));
    } on Exception catch (e) {
      logError('Barcode resolution failed: $e');
      state = state.copyWith(scanResolution: ScanFailed(e.toString()));
    }
  }

  /// Resolves a PLU code by searching the OFF API.
  ///
  /// Sets [ScanResolved] with an enriched produce product on success, or
  /// [ScanFailed] with 'PLU_NOT_FOUND' when the OFF search returns no
  /// results.
  ///
  /// If resolution takes longer than [timeout], a [TimeoutException] is
  /// caught and [ScanFailed] with message 'TIMEOUT' is emitted.
  Future<void> resolvePlu({
    required String pluCode,
    required String produceName,
    required String languageCode,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (state.scanResolution != null) return;
    logInfo('Resolving PLU: $pluCode ($produceName)');
    state = state.copyWith(scanResolution: const ScanResolving());
    try {
      final api = ref.read(apiServiceProvider);
      final results = await api
          .searchProducts(
            produceName,
            languageCode: languageCode,
          )
          .timeout(timeout);
      if (results.isNotEmpty) {
        final best = results.firstWhere(
          (p) => p.name.toLowerCase().contains(produceName.toLowerCase()),
          orElse: () => results.first,
        );
        final enriched = best.copyWith(
          productType: ProductType.produce,
          pluCode: pluCode,
        );
        logInfo('PLU resolved: ${enriched.name} (${enriched.barcode})');
        state = state.copyWith(scanResolution: ScanResolved(enriched));
        await _recordScan(enriched);
      } else {
        logInfo('No OFF results found for PLU: $pluCode ($produceName)');
        state = state.copyWith(
          scanResolution: const ScanFailed('PLU_NOT_FOUND'),
        );
      }
    } on TimeoutException {
      logWarning('PLU resolution timed out: $pluCode ($produceName)');
      state = state.copyWith(scanResolution: const ScanFailed('TIMEOUT'));
    } on Exception catch (e) {
      logError('PLU resolution failed: $e');
      state = state.copyWith(scanResolution: ScanFailed(e.toString()));
    }
  }

  /// Records a successful scan into the scan history.
  ///
  /// The write is best-effort: failures are logged and swallowed so that a
  /// database error never breaks the scan resolution flow. Products without a
  /// barcode are skipped.
  Future<void> _recordScan(Product product) async {
    if (product.barcode.isEmpty) return;
    logInfo('Recording scan for ${product.barcode}');
    try {
      await ref
          .read(scanHistoryProvider.notifier)
          .record(
            ScanHistoryEntry(
              barcode: product.barcode,
              name: product.name,
              scannedAt: DateTime.now().millisecondsSinceEpoch,
              imageUrl: product.imageUrl,
            ),
          );
    } on Object catch (e) {
      logError('Failed to record scan for ${product.barcode}: $e');
    }
  }

  /// Clears the current scan resolution so the user can scan again.
  void clearResolution() {
    logInfo('Clearing scan resolution');
    state = state.copyWith(clearScanResolution: true);
  }
}
