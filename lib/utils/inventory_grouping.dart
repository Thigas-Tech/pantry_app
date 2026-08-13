import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/utils/date_helpers.dart';

/// The expiry-based buckets shown on the home inventory list.
///
/// Order of the sections on screen: [InventorySection.expired],
/// [InventorySection.expiringSoon], then [InventorySection.good].
enum InventorySection {
  /// Items whose expiry date is strictly before today.
  expired,

  /// Items expiring within the configured expiringSoonDays window.
  expiringSoon,

  /// Items expiring later than the window, or without an expiry date.
  good,
}

/// One entry of the flattened home inventory list: either a section header
/// or a single inventory item.
sealed class InventoryListEntry {
  /// Creates an [InventoryListEntry].
  const InventoryListEntry();
}

/// Marks the start of an [InventorySection] in the flattened list.
final class InventorySectionEntry extends InventoryListEntry {
  /// Creates a section header entry for [section].
  const InventorySectionEntry(this.section);

  /// The section this entry introduces.
  final InventorySection section;
}

/// Carries a single inventory item to render as a card.
final class InventoryItemEntry extends InventoryListEntry {
  /// Creates an item entry wrapping [item].
  const InventoryItemEntry(this.item);

  /// The inventory item to display.
  final InventoryWithProduct item;
}

/// An immutable partition of the home inventory items by expiry status.
///
/// [InventoryGrouping.partition] parses each expiry date exactly once, so the
/// result can be memoized by the widget and reused across builds until the
/// underlying items, the expiring-soon window, or the calendar day change.
class InventoryGrouping {
  const InventoryGrouping._({
    required this.expired,
    required this.expiringSoon,
    required this.good,
    required this.addedThisWeek,
  });

  /// Partitions [items] into expiry buckets using [expiringSoonDays] as the
  /// expiring-soon window, relative to [now] (defaults to [DateTime.now]).
  ///
  /// An item is expired when its expiry date is strictly before today, is
  /// expiring soon when it falls within the window, and is good otherwise
  /// (including items without an expiry date). Order within each bucket
  /// matches the original [items] order.
  factory InventoryGrouping.partition(
    List<InventoryWithProduct> items,
    int expiringSoonDays, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final todayStart = DateTime(current.year, current.month, current.day);
    final soonThreshold = todayStart.add(Duration(days: expiringSoonDays));
    final weekAgo = current
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;

    final expired = <InventoryWithProduct>[];
    final expiringSoon = <InventoryWithProduct>[];
    final good = <InventoryWithProduct>[];
    var addedThisWeek = 0;

    for (final item in items) {
      final dateAdded = item.dateAdded;
      if (dateAdded != null && dateAdded >= weekAgo) {
        addedThisWeek++;
      }
      final expiry = parseExpiryDate(item.expiryDate);
      if (expiry == null || !expiry.isBefore(soonThreshold)) {
        good.add(item);
      } else if (expiry.isBefore(todayStart)) {
        expired.add(item);
      } else {
        expiringSoon.add(item);
      }
    }

    return InventoryGrouping._(
      expired: expired,
      expiringSoon: expiringSoon,
      good: good,
      addedThisWeek: addedThisWeek,
    );
  }

  /// Items whose expiry date is strictly before today.
  final List<InventoryWithProduct> expired;

  /// Items expiring within the expiring-soon window.
  final List<InventoryWithProduct> expiringSoon;

  /// Items expiring later than the window, or without an expiry date.
  final List<InventoryWithProduct> good;

  /// Number of items whose [InventoryWithProduct.dateAdded] falls within the
  /// last 7 days.
  final int addedThisWeek;

  /// The flattened list of section headers and items in display order.
  ///
  /// Empty buckets are omitted entirely.
  List<InventoryListEntry> get entries {
    final result = <InventoryListEntry>[];
    if (expired.isNotEmpty) {
      result
        ..add(const InventorySectionEntry(InventorySection.expired))
        ..addAll(expired.map(InventoryItemEntry.new));
    }
    if (expiringSoon.isNotEmpty) {
      result
        ..add(const InventorySectionEntry(InventorySection.expiringSoon))
        ..addAll(expiringSoon.map(InventoryItemEntry.new));
    }
    if (good.isNotEmpty) {
      result
        ..add(const InventorySectionEntry(InventorySection.good))
        ..addAll(good.map(InventoryItemEntry.new));
    }
    return result;
  }
}
