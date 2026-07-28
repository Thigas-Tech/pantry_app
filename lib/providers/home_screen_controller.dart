import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/services/produce_purchase_tracker.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_screen_controller.g.dart';

/// Immutable state for the home screen controller.
class HomeScreenState {
  /// All fields default to their zero/empty values.
  const HomeScreenState({
    this.selectionMode = false,
    this.selectedIds = const {},
    this.loadingProduce = const {},
  });

  /// Whether multi-selection mode is active.
  final bool selectionMode;

  /// The set of selected inventory item IDs.
  final Set<int> selectedIds;

  /// Produce names currently being resolved (loading indicator shown).
  final Set<String> loadingProduce;

  /// Returns a copy with the given fields replaced.
  HomeScreenState copyWith({
    bool? selectionMode,
    Set<int>? selectedIds,
    Set<String>? loadingProduce,
  }) {
    return HomeScreenState(
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      loadingProduce: loadingProduce ?? this.loadingProduce,
    );
  }
}

/// Notifier that manages ephemeral home screen UI state.
///
/// Owns selection mode, search query, produce loading state, and the
/// overdue cache refresh gate. Persistent pantry data lives in
/// [pantryProvider].
@riverpod
class HomeScreenController extends _$HomeScreenController {
  @override
  HomeScreenState build() => const HomeScreenState();

  /// Exits multi-selection mode and clears the selection.
  void exitSelectionMode() {
    state = state.copyWith(selectionMode: false, selectedIds: {});
  }

  /// Toggles the selection of the item with the given [id].
  void toggleSelection(int id) {
    final selected = {...state.selectedIds};
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    state = state.copyWith(selectedIds: selected);
  }

  /// Enters multi-selection mode and selects the item with the given [id].
  void enterSelectionMode(int id) {
    if (!state.selectionMode) {
      state = state.copyWith(selectionMode: true, selectedIds: {id});
    }
  }

  /// Deletes all selected inventory items from the database.
  ///
  /// Invalidates [pantryProvider] afterwards so the UI reflects the change.
  Future<void> deleteSelected() async {
    if (state.selectedIds.isEmpty) return;
    final db = ref.read(databaseProvider);
    for (final id in state.selectedIds) {
      await db.deleteInventoryItem(id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(pantryProvider);
    });
    exitSelectionMode();
  }

  /// Moves all selected items to the given [targetInventoryId].
  ///
  /// Invalidates [pantryProvider] afterwards so the UI reflects the change.
  Future<void> moveSelected(int targetInventoryId) async {
    if (state.selectedIds.isEmpty) return;
    final db = ref.read(databaseProvider);
    await db.moveItemsToInventory(
      state.selectedIds.toList(),
      targetInventoryId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(pantryProvider);
    });
    exitSelectionMode();
  }

  /// Resolves a produce product by name.
  ///
  /// Returns the resolved [Product] on success, or `null` on failure.
  /// The caller is responsible for navigation.
  Future<Product?> handleQuickProduceAdd(String produceName) async {
    if (state.loadingProduce.contains(produceName)) return null;
    state = state.copyWith(
      loadingProduce: {...state.loadingProduce, produceName},
    );

    final repo = ref.read(productRepositoryProvider);

    try {
      final product = await repo.resolveProduceProduct(produceName);
      state = state.copyWith(
        loadingProduce: {...state.loadingProduce}..remove(produceName),
      );
      await ProducePurchaseTracker().recordPurchase(produceName);
      return product;
    } on Exception catch (e) {
      logError('Failed to resolve produce product: $e');
      state = state.copyWith(
        loadingProduce: {...state.loadingProduce}..remove(produceName),
      );
      return null;
    }
  }

  bool _hasCheckedOverdue = false;

  /// Checks whether the product cache is overdue and refreshes if so.
  ///
  /// Only performs the check once per lifecycle. Deferred cache invalidation
  /// prevents setState during build errors.
  Future<void> refreshIfOverdue() async {
    if (_hasCheckedOverdue) return;
    _hasCheckedOverdue = true;
    try {
      final repo = ref.read(productRepositoryProvider);
      final online = await ref.read(hasConnectionProvider.future);
      if (!online) return;
      if (!await repo.isCacheOverdue()) return;
      final activeId = ref.read(activeInventoryProvider);
      await repo.refreshInventoryProducts(activeId);
      await repo.setLastRefreshTime();
      // Defer invalidation to the next frame so that any pending
      // build phase completes before dependent providers recompute.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(pantryProvider);
      });
    } on Exception catch (e) {
      logWarning('Overdue cache check failed: $e');
    }
  }
}
