import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';

/// Provides the price history for a specific barcode.
// ignore: specify_nonobvious_property_types
final priceHistoryProvider = FutureProvider.autoDispose
    .family<List<Price>, String>(
      (ref, barcode) {
        return ref.watch(priceRepositoryProvider).getPriceHistory(barcode);
      },
    );

/// Provides the most recent price for a specific barcode, or `null`.
// ignore: specify_nonobvious_property_types
final latestPriceProvider = FutureProvider.autoDispose.family<Price?, String>(
  (ref, barcode) {
    return ref.watch(priceRepositoryProvider).getLatestPrice(barcode);
  },
);

/// Whether prices are hidden for privacy.
final pricesHiddenProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).pricesHidden,
);

/// Provides the total value of the currently active inventory.
// ignore: specify_nonobvious_property_types
final inventoryValueProvider = FutureProvider.autoDispose<double?>((ref) async {
  final repo = ref.watch(priceRepositoryProvider);
  final activeId = ref.watch(activeInventoryProvider);
  final value = await repo.totalInventoryValue(activeId);
  if (value == null) return null;
  return double.tryParse(value.toStringAsFixed(2));
});

/// Provides the average item price in the currently active inventory.
// ignore: specify_nonobvious_property_types
final averagePriceProvider = FutureProvider.autoDispose<double?>((ref) async {
  final repo = ref.watch(priceRepositoryProvider);
  final activeId = ref.watch(activeInventoryProvider);
  final avg = await repo.averageItemPrice(activeId);
  if (avg == null) return null;
  return double.tryParse(avg.toStringAsFixed(2));
});

/// Provides the count of priced items in the currently active inventory.
// ignore: specify_nonobvious_property_types
final pricedItemCountProvider = FutureProvider.autoDispose<int>((ref) {
  final repo = ref.watch(priceRepositoryProvider);
  final activeId = ref.watch(activeInventoryProvider);
  return repo.pricedItemCount(activeId);
});

/// Provides the count of prices pending sync to Open Prices.
// ignore: specify_nonobvious_property_types
final pendingSyncCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(priceRepositoryProvider);
  final pending = await repo.getPendingSyncPrices();
  return pending.length;
});
