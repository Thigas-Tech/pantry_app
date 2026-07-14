import 'package:flutter/foundation.dart';

/// The result of a scanner interaction.
///
/// The scanner screen can return either a barcode (from camera or manual
/// entry) or a PLU code (from the numeric PLU keypad). This sealed class
/// lets the caller handle both uniformly via pattern matching.
sealed class ScanResult {
  /// Creates a [ScanResult].
  const ScanResult();
}

/// A barcode captured by the scanner or entered manually.
@immutable
class BarcodeResult extends ScanResult {
  /// Creates a [BarcodeResult] with the given [barcode].
  const BarcodeResult(this.barcode);

  /// The scanned or manually entered barcode string.
  final String barcode;

  @override
  bool operator ==(Object other) =>
      other is BarcodeResult && other.barcode == barcode;

  @override
  int get hashCode => barcode.hashCode;

  @override
  String toString() => 'BarcodeResult($barcode)';
}

/// A PLU code entered on the numeric keypad.
@immutable
class PluResult extends ScanResult {
  /// Creates a [PluResult] with the given PLU code and produce name.
  const PluResult({
    required this.pluCode,
    required this.produceName,
  });

  /// The PLU (Price Look-Up) code entered by the user.
  final String pluCode;

  /// The human-readable produce name resolved from the PLU code.
  final String produceName;

  @override
  bool operator ==(Object other) =>
      other is PluResult &&
      other.pluCode == pluCode &&
      other.produceName == produceName;

  @override
  int get hashCode => Object.hash(pluCode, produceName);

  @override
  String toString() => 'PluResult($pluCode: $produceName)';
}
