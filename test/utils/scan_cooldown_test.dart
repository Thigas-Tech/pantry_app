import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/scan_cooldown.dart';

void main() {
  group('ScanDedupe', () {
    var now = DateTime(2026, 8, 15, 12);
    final dedupe = ScanDedupe(
      window: const Duration(seconds: 2),
      now: () => now,
    );

    test('first detection of a barcode is dispatched', () {
      expect(dedupe.shouldDispatch('789'), isTrue);
      dedupe.markDispatched('789');
    });

    test('same barcode within the window is suppressed', () {
      now = now.add(const Duration(seconds: 1));
      expect(dedupe.shouldDispatch('789'), isFalse);
    });

    test('same barcode after the window is dispatched again', () {
      now = now.add(const Duration(seconds: 2));
      expect(dedupe.shouldDispatch('789'), isTrue);
      dedupe.markDispatched('789');
    });

    test('a different barcode is dispatched immediately', () {
      now = now.add(const Duration(milliseconds: 100));
      expect(dedupe.shouldDispatch('456'), isTrue);
    });

    test('boundary scan exactly at the window is dispatched', () {
      now = now.add(const Duration(seconds: 2));
      expect(dedupe.shouldDispatch('456'), isTrue);
      dedupe.markDispatched('456');
    });

    test('empty barcode is never dispatched', () {
      expect(dedupe.shouldDispatch(''), isFalse);
    });

    test('dedupe restarts its window per barcode', () {
      // 456 just dispatched; 789 was long ago, so 789 is allowed again.
      now = now.add(const Duration(seconds: 1));
      expect(dedupe.shouldDispatch('789'), isTrue);
    });
  });
}
