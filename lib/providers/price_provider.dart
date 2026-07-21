// The .autoDispose.family types are inferred from the value expression.
// ignore_for_file: specify_nonobvious_property_types

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';

/// Provides the price history for a specific barcode.
final priceHistoryProvider = FutureProvider.autoDispose
    .family<List<Price>, String>(
      (ref, barcode) {
        return ref.watch(priceRepositoryProvider).getPriceHistory(barcode);
      },
    );

/// Provides the most recent price for a specific barcode, or null.
final latestPriceProvider = FutureProvider.autoDispose.family<Price?, String>(
  (ref, barcode) {
    return ref.watch(priceRepositoryProvider).getLatestPrice(barcode);
  },
);

/// Whether prices are hidden for privacy.
final pricesHiddenProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).pricesHidden,
);

/// Provides the total value of the currently active inventory, converted
/// to the user's base currency.
final FutureProvider<double?> inventoryValueProvider =
    FutureProvider.autoDispose<double?>((ref) async {
      final repo = ref.watch(priceRepositoryProvider);
      final activeId = ref.watch(activeInventoryProvider);
      final settings = ref.watch(settingsProvider);
      final value = await repo.totalInventoryValue(
        activeId,
        baseCurrency: settings.baseCurrency,
      );
      if (value == null) return null;
      return double.tryParse(value.toStringAsFixed(2));
    });

/// Provides the average item price in the currently active inventory,
/// converted to the user's base currency.
final FutureProvider<double?> averagePriceProvider =
    FutureProvider.autoDispose<double?>((ref) async {
      final repo = ref.watch(priceRepositoryProvider);
      final activeId = ref.watch(activeInventoryProvider);
      final settings = ref.watch(settingsProvider);
      final avg = await repo.averageItemPrice(
        activeId,
        baseCurrency: settings.baseCurrency,
      );
      if (avg == null) return null;
      return double.tryParse(avg.toStringAsFixed(2));
    });

/// Provides the count of priced items in the currently active inventory.
final FutureProvider<int> pricedItemCountProvider =
    FutureProvider.autoDispose<int>((ref) {
      final repo = ref.watch(priceRepositoryProvider);
      final activeId = ref.watch(activeInventoryProvider);
      return repo.pricedItemCount(activeId);
    });

/// Provides the count of prices pending sync to Open Prices.
final FutureProvider<int> pendingSyncCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final repo = ref.watch(priceRepositoryProvider);
      final pending = await repo.getPendingSyncPrices();
      return pending.length;
    });
