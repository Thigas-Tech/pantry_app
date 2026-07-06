import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/widgets/scanner_overlay_painter.dart';

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
            onDetect: (capture) {
              if (_hasScanned) {
                logInfo('Scan already captured — ignoring duplicate');
                return;
              }
              final barcode = capture.barcodes.first;
              if (barcode.rawValue == null) return;
              _hasScanned = true;
              logInfo('Barcode scanned via camera: ${barcode.rawValue}');
              unawaited(HapticFeedback.mediumImpact());
              Navigator.of(context).pop(barcode.rawValue);
            },
          ),
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
