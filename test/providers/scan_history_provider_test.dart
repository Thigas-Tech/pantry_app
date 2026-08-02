import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/scan_history_provider.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/pump_app.dart';

class _TestActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper db;
  late ProviderContainer container;
  late MockProductRepository mockRepo;

  ScanHistoryEntry entry(int scannedAt, {String barcode = '5012345678900'}) =>
      ScanHistoryEntry(
        barcode: barcode,
        name: 'Product $barcode',
        scannedAt: scannedAt,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = createMockProductRepository();
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeInventoryProvider.overrideWith(
          _TestActiveInventoryNotifier.new,
        ),
        productRepositoryProvider.overrideWithValue(mockRepo),
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

  group('quickAdd', () {
    test('adds to inventory when product is already cached', () async {
      const product = Product(barcode: '5012345678900', name: 'Cached');
      when(
        () => mockRepo.getProductFromCache('5012345678900'),
      ).thenAnswer((_) async => product);

      await container.read(scanHistoryProvider.notifier).quickAdd(entry(1000));

      final items = await container.read(pantryProvider.future);
      expect(items, hasLength(1));
      expect(items.single.barcode, '5012345678900');
      verifyNever(() => mockRepo.getProduct(any()));
    });

    test('fetches and caches the product when not cached', () async {
      const product = Product(barcode: '5012345678900', name: 'Fetched');
      when(
        () => mockRepo.getProductFromCache('5012345678900'),
      ).thenAnswer((_) async => null);
      when(
        () => mockRepo.getProduct('5012345678900'),
      ).thenAnswer((_) async => product);

      await container.read(scanHistoryProvider.notifier).quickAdd(entry(1000));

      verify(() => mockRepo.getProduct('5012345678900')).called(1);
      final items = await container.read(pantryProvider.future);
      expect(items, hasLength(1));
      expect(items.single.barcode, '5012345678900');
    });

    test('falls back to a manual snapshot when offline', () async {
      when(
        () => mockRepo.getProductFromCache('9999999999999'),
      ).thenAnswer((_) async => null);
      when(
        () => mockRepo.getProduct('9999999999999'),
      ).thenThrow(FetchFailedException('offline'));

      await container
          .read(scanHistoryProvider.notifier)
          .quickAdd(entry(1000, barcode: '9999999999999'));

      final items = await container.read(pantryProvider.future);
      expect(items, hasLength(1));
      expect(items.single.barcode, '9999999999999');

      // The snapshot product must exist so the FK stays valid.
      final product = await db.getProduct('9999999999999');
      expect(product, isNotNull);
      expect(product!.name, 'Product 9999999999999');
    });

    test('merges quantities for the same barcode', () async {
      const product = Product(barcode: '5012345678900', name: 'Cached');
      when(
        () => mockRepo.getProductFromCache('5012345678900'),
      ).thenAnswer((_) async => product);

      final notifier = container.read(scanHistoryProvider.notifier);
      await notifier.quickAdd(entry(1000));
      await notifier.quickAdd(entry(2000));

      final items = await container.read(pantryProvider.future);
      expect(items, hasLength(1));
      expect(items.single.quantity, 2);
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
