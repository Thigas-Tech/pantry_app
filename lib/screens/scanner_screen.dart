import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A full‑screen barcode scanner for Android.
///
/// Opens the device’s camera using [MobileScanner] and instantly pops the
/// first detected barcode as a [String] when a valid barcode is found.
///
/// The screen is designed to be pushed onto the navigation stack via
/// [Navigator.push] and returns the scanned barcode as a [String] when
/// popped. If the user manually goes back without scanning, the returned
/// value is `null`.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MobileScannerView();
  }
}

/// The camera view that performs continuous barcode detection.
///
/// Uses [MobileScanner] to process camera frames. On the first valid
/// detection, the screen pops and returns the raw barcode value. A
/// `_hasScanned` flag prevents duplicate pops if the scanner fires
/// multiple events for the same frame.
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
