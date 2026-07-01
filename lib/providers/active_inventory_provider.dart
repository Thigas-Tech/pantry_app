import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the ID of the currently selected inventory (pantry).
///
/// Defaults to `1` (the built‑in "Home" inventory created during migration).
/// When the user switches inventories in the home screen, this notifier's
/// state is updated. All inventory‑related queries and providers read this
/// to filter their data.
class ActiveInventoryNotifier extends Notifier<int> {
  @override
  int build() => 1;

  /// The current active inventory ID.
  int get value => state;

  /// Updates the active inventory ID.
  set value(int id) => state = id;
}

/// The provider for [ActiveInventoryNotifier].
final activeInventoryProvider = NotifierProvider<ActiveInventoryNotifier, int>(
  ActiveInventoryNotifier.new,
);
