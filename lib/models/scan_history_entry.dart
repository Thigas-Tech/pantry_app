import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_history_entry.freezed.dart';

/// An immutable record of a single successful barcode or PLU scan.
///
/// Each [ScanHistoryEntry] captures the scanned product's barcode, the
/// product name known at scan time, the moment it was scanned, and an
/// optional image URL. The entry is self-contained (it does not reference
/// the products table) so history survives cache flushes and remains
/// available for products that were scanned but never added to inventory.
@freezed
abstract class ScanHistoryEntry with _$ScanHistoryEntry {
  /// Creates a [ScanHistoryEntry].
  ///
  /// [barcode], [name], and [scannedAt] are required. [imageUrl] defaults to
  /// null for products without an image. [id] is the auto-generated primary
  /// key from the scan_history table and is null before insertion.
  const factory ScanHistoryEntry({
    /// The scanned product's barcode or PLU code.
    required String barcode,

    /// The product name known at scan time.
    required String name,

    /// Epoch millis timestamp of when the scan happened.
    required int scannedAt,

    /// Auto-increment primary key from the scan_history table.
    int? id,

    /// Optional product image URL for display in recent-scans lists.
    String? imageUrl,
  }) = _ScanHistoryEntry;
}
