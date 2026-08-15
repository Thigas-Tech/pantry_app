import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/scanner_overlay_painter.dart';

void main() {
  group('computeScannerCutout', () {
    test('caps at 250x250 on large full-screen surfaces', () {
      final rect = computeScannerCutout(const Size(400, 700));
      expect(rect.width, 250);
      expect(rect.height, 250);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(700));
    });

    test('stays near the vertical centre on large surfaces', () {
      final rect = computeScannerCutout(const Size(400, 700));
      // The cutout centre must sit close to the preview centre (the reserved
      // hint band only offsets it by the band/margin half), not at the
      // bottom of the preview.
      final offset = (rect.center.dy - 350).abs();
      expect(offset, lessThanOrEqualTo(40));
    });

    test('shrinks to fit a short embedded preview box', () {
      final rect = computeScannerCutout(const Size(360, 200));
      expect(rect.height, lessThanOrEqualTo(200));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(200));
    });

    test('shrinks to fit a narrow preview box', () {
      final rect = computeScannerCutout(const Size(250, 700));
      expect(rect.width, lessThanOrEqualTo(250));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(250));
    });

    test('never returns a degenerate rectangle on tiny surfaces', () {
      final rect = computeScannerCutout(const Size(200, 160));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(160));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(200));
    });
  });

  group('computeHintRect', () {
    const textSize = Size(180, 20);

    test('sits above the cutout and inside the preview', () {
      const size = Size(400, 700);
      final cutout = computeScannerCutout(size);
      final hint = computeHintRect(size, cutout, textSize);

      expect(hint.top, greaterThanOrEqualTo(0));
      expect(hint.bottom, lessThanOrEqualTo(cutout.top));
      expect(hint.right, lessThanOrEqualTo(size.width));
      expect(hint.left, greaterThanOrEqualTo(0));
    });

    test('is centred horizontally', () {
      const size = Size(400, 700);
      final cutout = computeScannerCutout(size);
      final hint = computeHintRect(size, cutout, textSize);

      expect((hint.center.dx - size.width / 2).abs(), lessThanOrEqualTo(1));
    });

    test('clamps into the short embedded preview', () {
      const size = Size(360, 200);
      final cutout = computeScannerCutout(size);
      final hint = computeHintRect(size, cutout, textSize);

      expect(hint.top, greaterThanOrEqualTo(0));
      expect(hint.bottom, lessThanOrEqualTo(cutout.top));
      expect(hint.bottom, lessThanOrEqualTo(size.height));
    });
  });
}
