import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/utils/deferred_refresh.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';

/// A unified input screen for barcodes.
///
/// Offers two modes:
/// - Camera scanner via [ScannerCameraView] for barcodes.
/// - Manual barcode text entry.
///
/// Automatically navigates to [ProductDetailScreen] when a barcode is
/// successfully resolved via [scannerCameraProvider].
class ScannerScreen extends ConsumerStatefulWidget {
  /// Creates a [ScannerScreen] widget.
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _showManualEntry = false;

  void _onScanStateChanged(
    ScannerCameraState? prev,
    ScannerCameraState next,
  ) {
    final resolution = next.scanResolution;
    if (resolution == null) return;
    if (prev?.scanResolution == resolution && resolution is! ScanResolving) {
      return;
    }

    switch (resolution) {
      case ScanResolved(:final product):
        logInfo('Scan resolved: ${product.name}');
        unawaited(_navigateToProduct(product));
      case ScanFailed(:final message, :final barcode)
          when message == 'PRODUCT_NOT_FOUND':
        final code = barcode;
        if (code == null) {
          logWarning(
            'Product not found without a barcode — clearing resolution',
          );
          ref.read(scannerCameraProvider.notifier).clearResolution();
        } else {
          logInfo('Product not found for barcode: $code');
          unawaited(_navigateToSubmit(code));
        }
      case ScanFailed(:final message):
        logWarning('Scan resolution failed: $message');
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showError(context, l10n.scanFailed);
        ref.read(scannerCameraProvider.notifier).clearResolution();
      case ScanResolving():
        break;
    }
  }

  Future<void> _navigateToProduct(Product product) async {
    logInfo('Navigating to ProductDetailScreen: ${product.name}');
    final navigator = Navigator.of(context);
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
    logInfo('Returned from ProductDetailScreen — clearing resolution');
    ref.read(scannerCameraProvider.notifier).clearResolution();
    if (!mounted) return;
    afterFrame(() {
      if (mounted) ref.invalidate(pantryProvider);
    });
  }

  /// Opens the contribution form for a [barcode] that is not in the database.
  ///
  /// Pushes [AddProductScreen] in submit mode so the user can contribute the
  /// product to Open Food Facts. When the form closes the scan resolution is
  /// cleared and the pantry is refreshed in case the product was saved.
  Future<void> _navigateToSubmit(String barcode) async {
    logInfo('Navigating to AddProductScreen for contribution: $barcode');
    final navigator = Navigator.of(context);
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(barcode: barcode, submitToOff: true),
      ),
    );
    if (!mounted) return;
    logInfo('Returned from AddProductScreen — clearing resolution');
    ref.read(scannerCameraProvider.notifier).clearResolution();
    if (!mounted) return;
    afterFrame(() {
      if (mounted) ref.invalidate(pantryProvider);
    });
  }

  void _submitBarcode(String barcode) {
    logInfo('Manual barcode submitted: $barcode');
    unawaited(
      ref.read(scannerCameraProvider.notifier).resolveBarcode(barcode),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scannerCameraProvider, _onScanStateChanged);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        logInfo('Showing confirm-exit dialog');
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
          logInfo('User chose to leave scanner');
          Navigator.of(context).pop();
        } else {
          logInfo('User chose to stay in scanner');
        }
      },
      child: _buildCurrentMode(),
    );
  }

  Widget _buildCurrentMode() {
    if (_showManualEntry) {
      return _ManualEntryView(
        onSwitchToCamera: () {
          logInfo('Switched to camera scanner');
          unawaited(ref.read(scannerCameraProvider.notifier).retryScanner());
          setState(() => _showManualEntry = false);
        },
        onSubmitBarcode: _submitBarcode,
      );
    }
    return ScannerCameraView(
      onSwitchToManual: () {
        logInfo('Switched to manual entry');
        unawaited(ref.read(scannerCameraProvider.notifier).stopCamera());
        setState(() => _showManualEntry = true);
      },
    );
  }
}

// ---------- Manual entry ----------

/// A widget that allows the user to type or paste a barcode number.
class _ManualEntryView extends StatefulWidget {
  const _ManualEntryView({
    required this.onSwitchToCamera,
    required this.onSubmitBarcode,
  });

  final VoidCallback onSwitchToCamera;
  final void Function(String barcode) onSubmitBarcode;

  @override
  State<_ManualEntryView> createState() => _ManualEntryViewState();
}

class _ManualEntryViewState extends State<_ManualEntryView> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length < 4 || !RegExp(r'^\d+$').hasMatch(text)) {
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showWarning(context, l10n.invalidBarcode);
      return;
    }
    logInfo('Barcode entered manually: $text');
    unawaited(HapticFeedback.mediumImpact());
    widget.onSubmitBarcode(text);
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
