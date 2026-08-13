import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/price_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPriceRepository extends Mock implements PriceRepository {}

FakeSettingsNotifier _defaultSettings() => FakeSettingsNotifier();

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier([this.initial = const Settings()]);

  final Settings initial;

  @override
  Future<Settings> build() async => initial;
}

void main() {
  late ProviderContainer container;
  late MockPriceRepository mockRepo;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'active_inventory_id': 1});
    mockRepo = MockPriceRepository();
    container = ProviderContainer(
      overrides: [
        priceRepositoryProvider.overrideWithValue(mockRepo),
        settingsProvider.overrideWith(_defaultSettings),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('priceHistoryProvider', () {
    test('delegates to repository.getPriceHistory with inventoryId', () async {
      final prices = [const Price(barcode: '123', price: 5.99)];
      when(
        () => mockRepo.getPriceHistory(
          '123',
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => prices);

      final result = await container.read(
        priceHistoryProvider(('123', 1)).future,
      );
      expect(result, prices);
      verify(
        () => mockRepo.getPriceHistory('123', inventoryId: 1),
      ).called(1);
    });

    test('is cache-isolated per inventory', () async {
      final inv1 = [const Price(barcode: '123', price: 5.99)];
      final inv2 = [const Price(barcode: '123', price: 9.99, inventoryId: 2)];
      when(
        () => mockRepo.getPriceHistory('123', inventoryId: 1),
      ).thenAnswer((_) async => inv1);
      when(
        () => mockRepo.getPriceHistory('123', inventoryId: 2),
      ).thenAnswer((_) async => inv2);

      final a = await container.read(priceHistoryProvider(('123', 1)).future);
      final b = await container.read(priceHistoryProvider(('123', 2)).future);
      expect(a.single.price, 5.99);
      expect(b.single.price, 9.99);
      verify(
        () => mockRepo.getPriceHistory('123', inventoryId: 1),
      ).called(1);
      verify(
        () => mockRepo.getPriceHistory('123', inventoryId: 2),
      ).called(1);
    });
  });

  group('latestPriceProvider', () {
    test('delegates to repository.getLatestPrice with inventoryId', () async {
      const price = Price(barcode: '123', price: 5.99);
      when(
        () => mockRepo.getLatestPrice(
          '123',
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => price);

      final result = await container.read(
        latestPriceProvider(('123', 1)).future,
      );
      expect(result, price);
      verify(
        () => mockRepo.getLatestPrice('123', inventoryId: 1),
      ).called(1);
    });

    test('returns null when no price exists', () async {
      when(
        () => mockRepo.getLatestPrice(
          '456',
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => null);

      final result = await container.read(
        latestPriceProvider(('456', 1)).future,
      );
      expect(result, isNull);
    });
  });

  group('pricesHiddenProvider', () {
    test('reads from settings.pricesHidden', () {
      expect(container.read(pricesHiddenProvider), false);
    });
  });

  group('inventoryValueProvider', () {
    test('delegates to repository.totalInventoryValue', () async {
      when(
        () => mockRepo.totalInventoryValue(1),
      ).thenAnswer((_) async => 42.50);

      final result = await container.read(
        inventoryValueProvider.future,
      );
      expect(result, 42.5);
    });

    test('returns null when value is null', () async {
      when(
        () => mockRepo.totalInventoryValue(1),
      ).thenAnswer((_) async => null);

      final result = await container.read(inventoryValueProvider.future);
      expect(result, isNull);
    });
  });

  group('averagePriceProvider', () {
    test('delegates to repository.averageItemPrice', () async {
      when(
        () => mockRepo.averageItemPrice(1),
      ).thenAnswer((_) async => 3.33);

      final result = await container.read(averagePriceProvider.future);
      expect(result, 3.33);
    });

    test('returns null when avg is null', () async {
      when(
        () => mockRepo.averageItemPrice(1),
      ).thenAnswer((_) async => null);

      final result = await container.read(averagePriceProvider.future);
      expect(result, isNull);
    });
  });

  group('pricedItemCountProvider', () {
    test('delegates to repository.pricedItemCount', () async {
      when(() => mockRepo.pricedItemCount(1)).thenAnswer((_) async => 7);

      final result = await container.read(pricedItemCountProvider.future);
      expect(result, 7);
    });
  });

  group('pendingSyncCountProvider', () {
    test('delegates to repository.getPendingSyncCount', () async {
      when(() => mockRepo.getPendingSyncCount()).thenAnswer((_) async => 2);

      final result = await container.read(pendingSyncCountProvider.future);
      expect(result, 2);
      verify(() => mockRepo.getPendingSyncCount()).called(1);
      verifyNever(() => mockRepo.getPendingSyncPrices());
    });
  });
}
