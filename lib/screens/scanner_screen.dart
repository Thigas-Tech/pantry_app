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
import 'package:pantry_app/services/plu_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';

/// A unified input screen for barcodes and produce PLU codes.
///
/// Offers three modes:
/// - Camera scanner via [ScannerCameraView] for barcodes.
/// - Manual barcode text entry.
/// - PLU code entry via numeric keypad for produce without barcodes.
///
/// Automatically navigates to [ProductDetailScreen] when a barcode or PLU
/// code is successfully resolved via [scannerCameraProvider].
class ScannerScreen extends ConsumerStatefulWidget {
  /// Creates a [ScannerScreen] widget.
  ///
  /// [pluService] can be injected for testing. When omitted, a default
  /// [PluService] instance is used.
  const ScannerScreen({this.pluService, super.key});

  /// The PLU code-to-name lookup service.
  final PluService? pluService;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _showManualEntry = false;
  bool _showPluEntry = false;

  PluService get _pluService => widget.pluService ?? const PluService();

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
    ref.invalidate(pantryProvider);
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
    ref.invalidate(pantryProvider);
  }

  void _submitBarcode(String barcode) {
    logInfo('Manual barcode submitted: $barcode');
    unawaited(
      ref.read(scannerCameraProvider.notifier).resolveBarcode(barcode),
    );
  }

  void _submitPlu(String pluCode, String produceName) {
    logInfo('PLU submitted: $pluCode — $produceName');
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      ref
          .read(scannerCameraProvider.notifier)
          .resolvePlu(
            pluCode: pluCode,
            produceName: produceName,
            languageCode: l10n.localeName,
          ),
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
    if (_showPluEntry) {
      return _PluEntryView(
        pluService: _pluService,
        onSwitchToCamera: () {
          logInfo('Switched to camera scanner from PLU');
          unawaited(ref.read(scannerCameraProvider.notifier).retryScanner());
          setState(() {
            _showPluEntry = false;
            _showManualEntry = false;
          });
        },
        onSubmitPlu: _submitPlu,
      );
    }
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
      onSwitchToPlu: () {
        logInfo('Switched to PLU entry');
        unawaited(ref.read(scannerCameraProvider.notifier).stopCamera());
        setState(() => _showPluEntry = true);
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

// ---------- PLU entry ----------

/// A widget for entering PLU (Price Look-Up) codes for produce.
class _PluEntryView extends StatefulWidget {
  const _PluEntryView({
    required this.pluService,
    required this.onSwitchToCamera,
    required this.onSubmitPlu,
  });

  final PluService pluService;
  final VoidCallback onSwitchToCamera;
  final void Function(String pluCode, String produceName) onSubmitPlu;

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
    logInfo('PLU confirmed: ${_matchedEntry!.code} -- ${_matchedEntry!.name}');
    unawaited(HapticFeedback.mediumImpact());
    widget.onSubmitPlu(_matchedEntry!.code, _matchedEntry!.name);
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
