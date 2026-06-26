import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/utils/platform_utils.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return isMobile ? const _MobileScannerView() : const _ManualEntryView();
  }
}

// ---------- Mobile: real camera scanner ----------
class _MobileScannerView extends StatefulWidget {
  const _MobileScannerView();

  @override
  State<_MobileScannerView> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<_MobileScannerView> {
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
          Navigator.of(context).pop(barcode.rawValue);
        },
      ),
    );
  }
}

// ---------- Desktop: manual entry fallback ----------
class _ManualEntryView extends StatefulWidget {
  const _ManualEntryView();

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
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
