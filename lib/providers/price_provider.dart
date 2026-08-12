import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'price_provider.g.dart';

/// Provides the price history for a specific barcode in the given inventory.
///
/// Keyed by a (barcode, inventoryId) record so each pantry keeps an
/// independent, cache-isolated history.
@riverpod
Future<List<Price>> priceHistory(Ref ref, (String, int) args) {
  final (barcode, inventoryId) = args;
  return ref
      .watch(priceRepositoryProvider)
      .getPriceHistory(barcode, inventoryId: inventoryId);
}

/// Provides the most recent price for a specific barcode in the given
/// inventory, or null.
///
/// Keyed by a (barcode, inventoryId) record.
@riverpod
Future<Price?> latestPrice(Ref ref, (String, int) args) {
  final (barcode, inventoryId) = args;
  return ref
      .watch(priceRepositoryProvider)
      .getLatestPrice(barcode, inventoryId: inventoryId);
}

/// Whether prices are hidden for privacy.
@Riverpod(keepAlive: true)
bool pricesHidden(Ref ref) {
  return ref.watch(settingsProvider).value?.pricesHidden ?? false;
}

/// Provides the total value of the currently active inventory, converted
/// to the user's base currency.
@riverpod
Future<double?> inventoryValue(Ref ref) async {
  final repo = ref.watch(priceRepositoryProvider);
  final activeId = ref.watch(activeInventoryProvider.future);
  final settings = ref.watch(settingsProvider.future);
  final value = await repo.totalInventoryValue(
    await activeId,
    baseCurrency: (await settings).baseCurrency,
  );
  if (value == null) return null;
  return double.tryParse(value.toStringAsFixed(2));
}

/// Provides the average item price in the currently active inventory,
/// converted to the user's base currency.
@riverpod
Future<double?> averagePrice(Ref ref) async {
  final repo = ref.watch(priceRepositoryProvider);
  final activeId = ref.watch(activeInventoryProvider.future);
  final settings = ref.watch(settingsProvider.future);
  final avg = await repo.averageItemPrice(
    await activeId,
    baseCurrency: (await settings).baseCurrency,
  );
  if (avg == null) return null;
  return double.tryParse(avg.toStringAsFixed(2));
}

/// Provides the count of priced items in the currently active inventory.
@riverpod
Future<int> pricedItemCount(Ref ref) {
  final repo = ref.watch(priceRepositoryProvider);
  final activeId = ref.watch(activeInventoryProvider).value ?? 1;
  return repo.pricedItemCount(activeId);
}

/// Provides the count of prices pending sync to Open Prices.
@riverpod
Future<int> pendingSyncCount(Ref ref) async {
  final repo = ref.watch(priceRepositoryProvider);
  final pending = await repo.getPendingSyncPrices();
  return pending.length;
}
