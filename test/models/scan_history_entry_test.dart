import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/scan_history_entry.dart';

void main() {
  group('ScanHistoryEntry', () {
    test('creates with required fields', () {
      const entry = ScanHistoryEntry(
        barcode: '5012345678900',
        name: 'Chocolate Bar',
        scannedAt: 1000,
      );
      expect(entry.barcode, '5012345678900');
      expect(entry.name, 'Chocolate Bar');
      expect(entry.scannedAt, 1000);
      expect(entry.imageUrl, isNull);
      expect(entry.id, isNull);
    });

    test('creates with all fields', () {
      const entry = ScanHistoryEntry(
        id: 1,
        barcode: '5012345678900',
        name: 'Chocolate Bar',
        scannedAt: 2000,
        imageUrl: 'https://example.com/img.jpg',
      );
      expect(entry.id, 1);
      expect(entry.barcode, '5012345678900');
      expect(entry.name, 'Chocolate Bar');
      expect(entry.scannedAt, 2000);
      expect(entry.imageUrl, 'https://example.com/img.jpg');
    });

    test('copyWith preserves unset fields', () {
      const entry = ScanHistoryEntry(
        id: 1,
        barcode: '5012345678900',
        name: 'Chocolate Bar',
        scannedAt: 1000,
      );
      final copied = entry.copyWith(name: 'Milk Chocolate');
      expect(copied.id, 1);
      expect(copied.barcode, '5012345678900');
      expect(copied.name, 'Milk Chocolate');
      expect(copied.scannedAt, 1000);
      expect(copied.imageUrl, isNull);
    });

    test('equality works', () {
      const a = ScanHistoryEntry(
        id: 1,
        barcode: '5012345678900',
        name: 'Chocolate Bar',
        scannedAt: 1000,
      );
      const b = ScanHistoryEntry(
        id: 1,
        barcode: '5012345678900',
        name: 'Chocolate Bar',
        scannedAt: 1000,
      );
      const c = ScanHistoryEntry(
        id: 2,
        barcode: '5012345678900',
        name: 'Chocolate Bar',
        scannedAt: 1000,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
