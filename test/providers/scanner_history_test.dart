import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/scan_history_provider.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/pump_app.dart';

/// Fake [ScannerCamera] that skips platform controller creation.
class FakeScannerCamera extends ScannerCamera {
  @override
  ScannerCameraState build() => const ScannerCameraState();
}

class MockOffAdapter extends Mock implements OffAdapter {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(
      const ScanHistoryEntry(barcode: '', name: '', scannedAt: 0),
    );
  });

  late ProviderContainer container;
  late MockProductRepository mockRepo;
  late MockOffAdapter mockOff;
  late DatabaseHelper db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = createMockProductRepository();
    mockOff = MockOffAdapter();
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        productRepositoryProvider.overrideWithValue(mockRepo),
        apiServiceProvider.overrideWithValue(mockOff),
        scannerCameraProvider.overrideWith(FakeScannerCamera.new),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await (await db.database).close();
    });
  });

  Future<List<ScanHistoryEntry>> history() =>
      container.read(scanHistoryProvider.future);

  group('scan recording', () {
    test('resolveBarcode records a successful scan', () async {
      const barcode = '5012345678900';
      const product = Product(
        barcode: barcode,
        name: 'Test Product',
        imageUrl: 'https://example.com/img.jpg',
      );
      when(() => mockRepo.getProduct(barcode)).thenAnswer((_) async => product);

      await container
          .read(scannerCameraProvider.notifier)
          .resolveBarcode(
            barcode,
          );

      final entries = await history();
      expect(entries, hasLength(1));
      expect(entries.single.barcode, barcode);
      expect(entries.single.name, 'Test Product');
      expect(entries.single.imageUrl, 'https://example.com/img.jpg');
    });

    test('resolvePlu records a successful scan', () async {
      const pluCode = '4011';
      const produceName = 'Banana';
      when(
        () => mockOff.searchProducts(
          produceName,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => [const Product(barcode: '000000', name: 'Banana')],
      );

      await container
          .read(scannerCameraProvider.notifier)
          .resolvePlu(
            pluCode: pluCode,
            produceName: produceName,
            languageCode: 'en',
          );

      final entries = await history();
      expect(entries, hasLength(1));
      expect(entries.single.barcode, '000000');
      expect(entries.single.name, 'Banana');
    });

    test('ProductNotFoundException does not record', () async {
      const barcode = '9999999999999';
      when(
        () => mockRepo.getProduct(barcode),
      ).thenThrow(ProductNotFoundException(barcode));

      await container
          .read(scannerCameraProvider.notifier)
          .resolveBarcode(
            barcode,
          );

      final entries = await history();
      expect(entries, isEmpty);
    });

    test('generic exception does not record', () async {
      const barcode = '1234567890123';
      when(
        () => mockRepo.getProduct(barcode),
      ).thenThrow(Exception('Network error'));

      await container
          .read(scannerCameraProvider.notifier)
          .resolveBarcode(
            barcode,
          );

      final entries = await history();
      expect(entries, isEmpty);
    });

    test('duplicate concurrent resolve records only once', () async {
      const barcode = '5012345678900';
      when(
        () => mockRepo.getProduct(barcode),
      ).thenAnswer((_) async => const Product(barcode: barcode, name: 'Test'));

      final notifier = container.read(scannerCameraProvider.notifier);
      final first = notifier.resolveBarcode(barcode);
      await notifier.resolveBarcode(barcode);
      await first;

      final entries = await history();
      expect(entries, hasLength(1));
    });

    test('recording failure does not break resolution', () async {
      const barcode = '5012345678900';
      const product = Product(barcode: barcode, name: 'Test');
      when(() => mockRepo.getProduct(barcode)).thenAnswer((_) async => product);

      // Simulate a broken database so recording throws.
      final brokenDb = MockDatabaseHelper();
      when(() => brokenDb.recordScan(any())).thenThrow(
        Exception('db unavailable'),
      );
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(brokenDb),
          productRepositoryProvider.overrideWithValue(mockRepo),
          apiServiceProvider.overrideWithValue(mockOff),
          scannerCameraProvider.overrideWith(FakeScannerCamera.new),
        ],
      );

      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolveBarcode(barcode);

      final state = container.read(scannerCameraProvider);
      expect(state.scanResolution, isA<ScanResolved>());
    });
  });
}
