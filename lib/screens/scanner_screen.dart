import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A barcode input screen for Android.
///
/// Offers two modes:
/// - **Camera scanner** – uses [MobileScanner] to detect a barcode in real
///   time. On the first detection it pops and returns the barcode string.
/// - **Manual entry** – a text field where the user can type or paste a
///   barcode. Useful for damaged labels or low‑resolution cameras.
///
/// The user switches between modes with the icon button in the app bar.
/// The screen always returns a [String] (the barcode) when popped, or
/// `null` if the user navigates back without submitting.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  /// Whether the manual entry view is currently shown.
  bool _showManualEntry = false;

  @override
  Widget build(BuildContext context) {
    return _showManualEntry
        ? _ManualEntryView(
            onSwitchToCamera: () => setState(() => _showManualEntry = false),
          )
        : _MobileScannerView(
            onSwitchToManual: () => setState(() => _showManualEntry = true),
          );
  }
}

// ---------- Camera scanner ----------

/// The live camera scanner using Google ML Kit via [MobileScanner].
class _MobileScannerView extends StatefulWidget {
  const _MobileScannerView({required this.onSwitchToManual});

  /// Called when the user taps the manual entry button.
  final VoidCallback onSwitchToManual;

  @override
  State<_MobileScannerView> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<_MobileScannerView> {
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Enter barcode manually',
            onPressed: widget.onSwitchToManual,
          ),
        ],
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasScanned) return;
          final barcode = capture.barcodes.first;
          if (barcode.rawValue == null) return;
          _hasScanned = true;
          Navigator.of(context).pop(barcode.rawValue);
        },
      ),
    );
  }
}

// ---------- Manual entry ----------

/// A simple form that lets the user type or paste a barcode.
class _ManualEntryView extends StatefulWidget {
  const _ManualEntryView({required this.onSwitchToCamera});

  /// Called when the user wants to return to the camera.
  final VoidCallback onSwitchToCamera;

  @override
  State<_ManualEntryView> createState() => _ManualEntryViewState();
}

class _ManualEntryViewState extends State<_ManualEntryView> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Scan with camera',
            onPressed: widget.onSwitchToCamera,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Type or paste a barcode', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
