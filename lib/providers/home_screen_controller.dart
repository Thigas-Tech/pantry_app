import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_screen_controller.g.dart';

/// Immutable state for the home screen controller.
class HomeScreenState {
  /// All fields default to their zero/empty values.
  const HomeScreenState({
    this.selectionMode = false,
    this.selectedIds = const {},
  });

  /// Whether multi-selection mode is active.
  final bool selectionMode;

  /// The set of selected inventory item IDs.
  final Set<int> selectedIds;

  /// Returns a copy with the given fields replaced.
  HomeScreenState copyWith({
    bool? selectionMode,
    Set<int>? selectedIds,
  }) {
    return HomeScreenState(
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

/// Notifier that manages ephemeral home screen UI state.
///
/// Owns selection mode and the overdue cache refresh gate. Persistent pantry
/// data lives in [pantryProvider].
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
    final repo = ref.read(productRepositoryProvider);
    for (final id in state.selectedIds) {
      await repo.deleteInventoryItem(id);
    }
    if (ref.mounted) ref.invalidate(pantryProvider);
    exitSelectionMode();
  }

  /// Moves all selected items to the given [targetInventoryId].
  ///
  /// Invalidates [pantryProvider] afterwards so the UI reflects the change.
  Future<void> moveSelected(int targetInventoryId) async {
    if (state.selectedIds.isEmpty) return;
    final repo = ref.read(productRepositoryProvider);
    await repo.moveItemsToInventory(
      state.selectedIds.toList(),
      targetInventoryId,
    );
    if (ref.mounted) ref.invalidate(pantryProvider);
    exitSelectionMode();
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
      final activeId = await ref.read(activeInventoryProvider.future);
      await repo.refreshInventoryProducts(activeId);
      await repo.setLastRefreshTime();
      if (ref.mounted) ref.invalidate(pantryProvider);
    } on Exception catch (e) {
      logWarning('Overdue cache refresh failed: $e');
    }
  }
}
