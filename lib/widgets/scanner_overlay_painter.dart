import 'package:flutter/material.dart';

/// Maximum side length of the scanning cutout on large previews.
const double kScannerMaxCutout = 250;

/// Minimum side length of the scanning cutout on tiny previews.
const double kScannerMinCutout = 80;

/// Vertical space reserved at the top of the preview for the hint text.
const double kScannerHintBand = 36;

/// Top margin between the preview edge and the hint band.
const double kScannerTopMargin = 12;

/// Bottom margin between the cutout and the preview edge.
const double kScannerBottomMargin = 16;

/// Horizontal margin on each side of the preview.
const double kScannerSideMargin = 16;

/// Computes the scanning cutout rectangle for a camera preview of [size].
///
/// The cutout is centered in the space below the reserved hint band (see
/// [kScannerHintBand]) so it works both in the full-screen scanner and in
/// short embedded previews (such as the market trip's camera box). On large
/// surfaces the cutout is capped at [kScannerMaxCutout] and stays near the
/// centre; on small surfaces it shrinks to fit inside the bounds with the
/// hint band and margins intact.
Rect computeScannerCutout(Size size) {
  final availableHeight =
      size.height - kScannerHintBand - kScannerTopMargin - kScannerBottomMargin;
  final height = availableHeight.clamp(kScannerMinCutout, kScannerMaxCutout);
  final width = (size.width - 2 * kScannerSideMargin).clamp(
    kScannerMinCutout,
    kScannerMaxCutout,
  );
  final top =
      kScannerHintBand + kScannerTopMargin + (availableHeight - height) / 2;
  return Rect.fromLTWH((size.width - width) / 2, top, width, height);
}

/// Computes the rectangle for the hint text, centred in the reserved band
/// between the preview top and the [cutout].
///
/// The returned rect is fully inside [size] and never overlaps the cutout;
/// on very small surfaces where the band cannot fit [textSize] it is clamped
/// to the available space.
Rect computeHintRect(Size size, Rect cutout, Size textSize) {
  const bandTop = kScannerTopMargin;
  final bandBottom = cutout.top - kScannerTopMargin;
  final available = (bandBottom - bandTop).clamp(0.0, double.infinity);
  final hintHeight = textSize.height.clamp(0.0, available);
  final maxLeft = (size.width - textSize.width).clamp(0.0, double.infinity);
  final left = ((size.width - textSize.width) / 2).clamp(0.0, maxLeft);
  final top = bandTop + (available - hintHeight) / 2;
  return Rect.fromLTWH(left, top, textSize.width, hintHeight);
}

/// Paints a semi-transparent dark overlay with a rounded-rectangle cutout
/// and an animated horizontal scanning line inside the cutout.
///
/// The hint text is drawn on a rounded scrim chip in the reserved band above
/// the cutout so it stays readable over a bright camera feed. The cutout is
/// created using a path with [PathFillType.evenOdd] so that it works on all
/// rendering backends (Impeller and Skia).
class ScannerOverlayPainter extends CustomPainter {
  /// Creates a [ScannerOverlayPainter].
  const ScannerOverlayPainter({
    required this.animationValue,
    required this.hintText,
  });

  /// Value between 0.0 and 1.0 that controls the vertical position of the
  /// scanning line inside the cutout.
  final double animationValue;

  /// The localised hint text shown above the cutout.
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
    _paintHint(canvas, size, cutoutRect, textPainter);
  }

  /// Draws the hint text on a scrim chip above the cutout.
  void _paintHint(
    Canvas canvas,
    Size size,
    Rect cutout,
    TextPainter textPainter,
  ) {
    final textSize = Size(textPainter.width, textPainter.height);
    final hintRect = computeHintRect(size, cutout, textSize);
    if (hintRect.isEmpty) return;

    const chipPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 4);
    // The chip is the hint rect expanded by the padding.
    final chip = Rect.fromLTRB(
      hintRect.left - chipPadding.left,
      hintRect.top - chipPadding.top,
      hintRect.right + chipPadding.right,
      hintRect.bottom + chipPadding.bottom,
    );
    final chipPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chip, const Radius.circular(8)),
      chipPaint,
    );
    textPainter.paint(canvas, hintRect.topLeft);
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
