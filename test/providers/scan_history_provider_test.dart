import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/scan_history_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper db;
  late ProviderContainer container;

  ScanHistoryEntry entry(int scannedAt, {String barcode = '5012345678900'}) =>
      ScanHistoryEntry(
        barcode: barcode,
        name: 'Product $barcode',
        scannedAt: scannedAt,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await (await db.database).close();
    });
  });

  group('scanHistoryProvider', () {
    test('returns an empty list when no history exists', () async {
      final history = await container.read(scanHistoryProvider.future);
      expect(history, isEmpty);
    });

    test('returns recorded entries newest first', () async {
      await db.recordScan(entry(100));
      await db.recordScan(entry(300));
      await db.recordScan(entry(200));

      final history = await container.read(scanHistoryProvider.future);
      expect(history.map((e) => e.scannedAt).toList(), [300, 200, 100]);
    });
  });

  group('record', () {
    test('inserts an entry and refreshes the provider', () async {
      final id = await container
          .read(scanHistoryProvider.notifier)
          .record(entry(1000));
      expect(id, isNonNegative);

      final history = await container.read(scanHistoryProvider.future);
      expect(history, hasLength(1));
      expect(history.first.barcode, '5012345678900');
    });
  });

  group('clear', () {
    test('removes all entries and refreshes the provider', () async {
      await db.recordScan(entry(1000));
      final cleared = await container
          .read(scanHistoryProvider.notifier)
          .clear();

      expect(cleared, 1);
      final history = await container.read(scanHistoryProvider.future);
      expect(history, isEmpty);
    });
  });
}
