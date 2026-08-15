import 'package:flutter/material.dart';

/// Computes the scanning cutout rectangle for a camera preview of [size].
///
/// The cutout scales to fit the available space so it works both in the
/// full-screen scanner and in short embedded previews (such as the market
/// trip's camera box). On large surfaces the cutout is capped at 250x250 and
/// sits slightly above centre; on small surfaces it shrinks and stays fully
/// inside the bounds with a small margin.
Rect computeScannerCutout(Size size) {
  const maxCutout = 250.0;
  final width = (size.width - 32).clamp(80.0, maxCutout);
  final height = (size.height - 48).clamp(80.0, maxCutout);
  final top = (size.height / 2 - 40).clamp(8.0, size.height - height - 8);
  return Rect.fromLTWH(
    (size.width - width) / 2,
    top,
    width,
    height,
  );
}

/// Paints a semi‑transparent dark overlay with a rounded‑rectangle cutout
/// and an animated horizontal scanning line inside the cutout.
///
/// The cutout is created using a path with [PathFillType.evenOdd] so that
/// it works on all rendering backends (Impeller and Skia).
class ScannerOverlayPainter extends CustomPainter {
  /// Creates a [ScannerOverlayPainter].
  const ScannerOverlayPainter({
    required this.animationValue,
    required this.hintText,
  });

  /// Value between 0.0 and 1.0 that controls the vertical position of the
  /// scanning line inside the cutout.
  final double animationValue;

  /// The localised hint text shown below the cutout.
  final String hintText;

  @override
  void paint(Canvas canvas, Size size) {
    final cutoutRect = computeScannerCutout(size);
    final cutoutRRect = RRect.fromRectAndRadius(
      cutoutRect,
      const Radius.circular(16),
    );

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRRect)
      ..fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()..color = Colors.black54;
    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(cutoutRRect, borderPaint);

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
      _Corner.topLeft,
    );
    _drawCorner(
      canvas,
      cutoutRect.topRight,
      cornerPaint,
      cornerLength,
      _Corner.topRight,
    );
    _drawCorner(
      canvas,
      cutoutRect.bottomLeft,
      cornerPaint,
      cornerLength,
      _Corner.bottomLeft,
    );
    _drawCorner(
      canvas,
      cutoutRect.bottomRight,
      cornerPaint,
      cornerLength,
      _Corner.bottomRight,
    );

    final lineY = cutoutRect.top + (cutoutRect.height * animationValue);
    final linePaint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 2;
    final lineStart = Offset(cutoutRect.left + 10, lineY);
    final lineEnd = Offset(cutoutRect.right - 10, lineY);
    canvas.drawLine(lineStart, lineEnd, linePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: hintText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Keep the hint inside the preview even in short embedded boxes.
    final hintTop = (cutoutRect.bottom + 12).clamp(
      0.0,
      size.height - textPainter.height - 4,
    );
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        hintTop,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        hintText != oldDelegate.hintText;
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

void _drawCorner(
  Canvas canvas,
  Offset corner,
  Paint paint,
  double length,
  _Corner type,
) {
  switch (type) {
    case _Corner.topLeft:
      canvas
        ..drawLine(corner, Offset(corner.dx + length, corner.dy), paint)
        ..drawLine(corner, Offset(corner.dx, corner.dy + length), paint);
    case _Corner.topRight:
      canvas
        ..drawLine(corner, Offset(corner.dx - length, corner.dy), paint)
        ..drawLine(corner, Offset(corner.dx, corner.dy + length), paint);
    case _Corner.bottomLeft:
      canvas
        ..drawLine(corner, Offset(corner.dx + length, corner.dy), paint)
        ..drawLine(corner, Offset(corner.dx, corner.dy - length), paint);
    case _Corner.bottomRight:
      canvas
        ..drawLine(corner, Offset(corner.dx - length, corner.dy), paint)
        ..drawLine(corner, Offset(corner.dx, corner.dy - length), paint);
  }
}
