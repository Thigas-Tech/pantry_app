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
}
