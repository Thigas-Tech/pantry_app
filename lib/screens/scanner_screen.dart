import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A barcode input screen for Android.
///
/// Offers two modes:
/// - **Camera scanner** – uses [MobileScanner] to detect a barcode in real
///   time. On the first detection it pops and returns the barcode string.
///   Includes a semi‑transparent overlay with a scanning‑line animation.
/// - **Manual entry** – a text field where the user can type or paste a
///   barcode. Useful for damaged labels or low‑resolution cameras.
///
/// The user switches between modes with the icon button in the app bar.
/// The screen always returns a [String] (the barcode) when popped, or
/// `null` if the user navigates back without submitting.
class ScannerScreen extends StatefulWidget {
  /// Creates a [ScannerScreen] widget.
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

class _MobileScannerViewState extends State<_MobileScannerView>
    with SingleTickerProviderStateMixin {
  bool _hasScanned = false;

  /// Controls the scanning‑line animation.
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
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            onDetect: (capture) {
              if (_hasScanned) return;
              final barcode = capture.barcodes.first;
              if (barcode.rawValue == null) return;
              _hasScanned = true;
              unawaited(HapticFeedback.mediumImpact());
              Navigator.of(context).pop(barcode.rawValue);
            },
          ),
          // Overlay with cutout and animated line
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ScannerOverlayPainter(
                  animationValue: _animationController.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Paints a semi‑transparent dark overlay with a rounded‑rectangle cutout
/// and an animated horizontal scanning line inside the cutout.
class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({required this.animationValue});

  /// Value between 0.0 and 1.0 that controls the vertical position of the
  /// scanning line inside the cutout.
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Dimensions of the cutout (the scanning area)
    const cutoutWidth = 250.0;
    const cutoutHeight = 250.0;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: cutoutWidth,
      height: cutoutHeight,
    );
    final cutoutRRect = RRect.fromRectAndRadius(
      cutoutRect,
      const Radius.circular(16),
    );

    // 1. Draw the semi‑transparent dark background everywhere…
    final backgroundPaint = Paint()..color = Colors.black54;
    canvas
      ..drawRect(rect, backgroundPaint)
      // 2. …then “punch out” the rounded rectangle so the camera shows through.
      ..drawRRect(
        cutoutRRect,
        Paint()..blendMode = BlendMode.clear,
      );

    // 3. Draw the white border around the cutout.
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(cutoutRRect, borderPaint);

    // 4. Draw the corner accents (four small L‑shaped lines).
    const cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.tealAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    _drawCorner(
      canvas,
      cutoutRect.topLeft,
      cornerPaint,
      cornerLength,
      Corner.topLeft,
    );
    _drawCorner(
      canvas,
      cutoutRect.topRight,
      cornerPaint,
      cornerLength,
      Corner.topRight,
    );
    _drawCorner(
      canvas,
      cutoutRect.bottomLeft,
      cornerPaint,
      cornerLength,
      Corner.bottomLeft,
    );
    _drawCorner(
      canvas,
      cutoutRect.bottomRight,
      cornerPaint,
      cornerLength,
      Corner.bottomRight,
    );

    // 5. Draw the animated scanning line.
    final lineY = cutoutRect.top + (cutoutRect.height * animationValue);
    final linePaint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 2;
    final lineStart = Offset(cutoutRect.left + 10, lineY);
    final lineEnd = Offset(cutoutRect.right - 10, lineY);
    canvas.drawLine(lineStart, lineEnd, linePaint);

    // 6. Draw a small hint text below the cutout.
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Align the barcode inside the frame',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        cutoutRect.bottom + 16,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

/// The position of a corner accent line.
enum Corner {
  /// The top‑left corner.
  topLeft,

  /// The top‑right corner.
  topRight,

  /// The bottom‑left corner.
  bottomLeft,

  /// The bottom‑right corner.
  bottomRight,
}

void _drawCorner(
  Canvas canvas,
  Offset corner,
  Paint paint,
  double length,
  Corner type,
) {
  switch (type) {
    case Corner.topLeft:
      canvas
        ..drawLine(corner, Offset(corner.dx + length, corner.dy), paint)
        ..drawLine(corner, Offset(corner.dx, corner.dy + length), paint);
    case Corner.topRight:
      canvas
        ..drawLine(corner, Offset(corner.dx - length, corner.dy), paint)
        ..drawLine(corner, Offset(corner.dx, corner.dy + length), paint);
    case Corner.bottomLeft:
      canvas
        ..drawLine(corner, Offset(corner.dx + length, corner.dy), paint)
        ..drawLine(corner, Offset(corner.dx, corner.dy - length), paint);
    case Corner.bottomRight:
      canvas
        ..drawLine(corner, Offset(corner.dx - length, corner.dy), paint)
        ..drawLine(corner, Offset(corner.dx, corner.dy - length), paint);
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
        padding: const EdgeInsets.all(24),
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
