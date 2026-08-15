/// Suppresses duplicate barcode detections from the camera.
///
/// A scanner reports the same barcode repeatedly while an item stays in
/// frame, and after a scan is handled the resolution clears, so the next
/// detection of the same barcode would otherwise fire again. This class
/// ignores re-detections of the *same* barcode within a short [window] after
/// it was last dispatched, while always allowing a *different* barcode
/// through so rapid scans of distinct items are not dropped.
class ScanDedupe {
  /// Creates a [ScanDedupe] with the given [window] and clock.
  ///
  /// [now] is injectable for tests and defaults to [DateTime.now].
  ScanDedupe({
    this.window = const Duration(milliseconds: 2500),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// How long re-detections of the same barcode are ignored.
  final Duration window;

  /// Injectable clock.
  final DateTime Function() _now;

  String? _lastBarcode;
  DateTime? _lastScanAt;

  /// Whether a detection of [barcode] should be handled (i.e. not a
  /// duplicate). Empty barcodes are always suppressed.
  bool shouldDispatch(String barcode) {
    if (barcode.isEmpty) return false;
    final last = _lastBarcode;
    final lastScan = _lastScanAt;
    if (last == null || lastScan == null) return true;
    if (barcode != last) return true;
    return _now().difference(lastScan) >= window;
  }

  /// Records that [barcode] was just handled, starting its cooldown window.
  ///
  /// Call only after a scan is actually dispatched so re-detections during
  /// resolution are still suppressed correctly.
  void markDispatched(String barcode) {
    _lastBarcode = barcode;
    _lastScanAt = _now();
  }
}
