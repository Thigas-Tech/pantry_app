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
  Settings build() => initial;
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
    test('delegates to repository.getPriceHistory', () async {
      final prices = [const Price(barcode: '123', price: 5.99)];
      when(() => mockRepo.getPriceHistory('123')).thenAnswer(
        (_) async => prices,
      );

      final result = await container.read(
        priceHistoryProvider('123').future,
      );
      expect(result, prices);
    });
  });

  group('latestPriceProvider', () {
    test('delegates to repository.getLatestPrice', () async {
      const price = Price(barcode: '123', price: 5.99);
      when(() => mockRepo.getLatestPrice('123')).thenAnswer(
        (_) async => price,
      );

      final result = await container.read(latestPriceProvider('123').future);
      expect(result, price);
    });

    test('returns null when no price exists', () async {
      when(() => mockRepo.getLatestPrice('456')).thenAnswer((_) async => null);

      final result = await container.read(latestPriceProvider('456').future);
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
    test('delegates to repository.getPendingSyncPrices', () async {
      final pending = [
        const Price(barcode: '1', price: 1, syncStatus: 'pending'),
        const Price(barcode: '2', price: 2, syncStatus: 'pending'),
      ];
      when(() => mockRepo.getPendingSyncPrices()).thenAnswer(
        (_) async => pending,
      );

      final result = await container.read(pendingSyncCountProvider.future);
      expect(result, 2);
    });
  });
}
