import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/utils/platform_utils.dart';

/// A barcode input screen that adapts to the current platform.
///
/// On **mobile** (Android / iOS) it opens a full‑screen camera view using
/// [MobileScanner] and instantly pops the first detected barcode string.
/// On **desktop** (Linux / macOS / Windows) it shows a manual text field
/// where the user can type or paste a barcode.
///
/// The screen is designed to be pushed onto the navigation stack via
/// [Navigator.push] and returns the scanned barcode as a [String] when
/// popped. If the user manually goes back without scanning / submitting,
/// the returned value is `null`.
///
/// ## Why two implementations?
///
/// The `mobile_scanner` plugin depends on Google ML Kit, which is only
/// available on Android and iOS. Attempting to use it on desktop would
/// cause a runtime crash. The [isMobile] getter (from `platform_utils.dart`)
/// cleanly separates the two implementations without the need for
/// conditional imports or compile‑time exclusions.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return isMobile ? const _MobileScannerView() : const _ManualEntryView();
  }
}

// ---------- Mobile: real camera scanner ----------

/// The mobile barcode scanner view.
///
/// Uses [MobileScanner] to continuously process camera frames. On the first
/// valid barcode detection, the screen pops and returns the raw barcode
/// value. A `_hasScanned` flag prevents duplicate pops if the scanner
/// fires multiple detection events for the same frame.
class _MobileScannerView extends StatefulWidget {
  const _MobileScannerView();

  @override
  State<_MobileScannerView> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<_MobileScannerView> {
  /// Guards against multiple pops. Set to `true` after the first barcode
  /// is returned.
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasScanned) return;
          final barcode = capture.barcodes.first;
          if (barcode.rawValue == null) return;
          _hasScanned = true;
          // Return the barcode to the calling screen and close the scanner.
          Navigator.of(context).pop(barcode.rawValue);
        },
      ),
    );
  }
}

// ---------- Desktop: manual entry fallback ----------

/// A simple text‑input screen for entering a barcode manually.
///
/// This is used on desktop platforms where camera‑based scanning is not
/// available. The user can type or paste a barcode and submit it via the
/// keyboard (Enter key) or by tapping the "Submit" button.
///
/// Only non‑empty strings are returned; empty submissions are ignored.
class _ManualEntryView extends StatefulWidget {
  const _ManualEntryView();

  @override
  State<_ManualEntryView> createState() => _ManualEntryViewState();
}

class _ManualEntryViewState extends State<_ManualEntryView> {
  /// Controller for the barcode text field.
  final _controller = TextEditingController();

  /// Validates the input and pops the screen with the barcode string.
  ///
  /// Leading and trailing whitespace is removed before submission.
  /// If the trimmed string is empty, nothing happens (the user must enter
  /// at least one character).
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
      appBar: AppBar(title: const Text('Enter Barcode')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Barcode scanning is not available on desktop.\n'
              'Please enter a barcode manually.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                border: OutlineInputBorder(),
              ),
              // Allow submission via the keyboard's Enter key.
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _submit, child: const Text('Submit')),
          ],
        ),
      ),
    );
  }
}
