import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/utils/inventory_grouping.dart';

InventoryWithProduct _item(
  int id,
  String name, {
  DateTime? expiryDate,
  int? dateAdded,
}) {
  return InventoryWithProduct(
    id: id,
    barcode: '$id',
    quantity: 1,
    unit: 'pcs',
    location: 'pantry',
    productName: name,
    expiryDate: expiryDate?.toIso8601String().substring(0, 10),
    dateAdded: dateAdded,
    inventoryId: 1,
  );
}

void main() {
  final now = DateTime(2026, 8, 12, 15, 30);

  group('InventoryGrouping.partition', () {
    test('buckets items by expiry status with a fixed now', () {
      final grouping = InventoryGrouping.partition(
        [
          _item(1, 'expired', expiryDate: DateTime(2026, 8, 10)),
          _item(2, 'soon', expiryDate: DateTime(2026, 8, 13)),
          _item(3, 'far', expiryDate: DateTime(2026, 9)),
          _item(4, 'no expiry'),
        ],
        3,
        now: now,
      );

      expect(grouping.expired.map((i) => i.productName), ['expired']);
      expect(grouping.expiringSoon.map((i) => i.productName), ['soon']);
      expect(grouping.good.map((i) => i.productName), ['far', 'no expiry']);
    });

    test('treats an expiry exactly expiringSoonDays away as good', () {
      final grouping = InventoryGrouping.partition(
        [
          _item(1, 'exact', expiryDate: DateTime(2026, 8, 15)),
          _item(2, 'one less', expiryDate: DateTime(2026, 8, 14)),
        ],
        3,
        now: now,
      );

      expect(grouping.expiringSoon.map((i) => i.productName), ['one less']);
      expect(grouping.good.map((i) => i.productName), ['exact']);
    });

    test('treats today as expiring soon, never expired', () {
      final grouping = InventoryGrouping.partition(
        [
          _item(1, 'today', expiryDate: DateTime(2026, 8, 12)),
        ],
        3,
        now: now,
      );

      expect(grouping.expired, isEmpty);
      expect(grouping.expiringSoon.map((i) => i.productName), ['today']);
    });

    test('preserves the original order within each bucket', () {
      final grouping = InventoryGrouping.partition(
        [
          _item(1, 'a', expiryDate: DateTime(2026, 8, 20)),
          _item(2, 'b', expiryDate: DateTime(2026, 8, 10)),
          _item(3, 'c', expiryDate: DateTime(2026, 8, 30)),
          _item(4, 'd', expiryDate: DateTime(2026, 8, 12)),
        ],
        3,
        now: now,
      );

      expect(grouping.good.map((i) => i.productName), ['a', 'c']);
      expect(grouping.expiringSoon.map((i) => i.productName), ['d']);
      expect(grouping.expired.map((i) => i.productName), ['b']);
    });

    test('counts items added within the last 7 days', () {
      final weekAgo = now.subtract(const Duration(days: 7));
      final grouping = InventoryGrouping.partition(
        [
          _item(
            1,
            'old',
            dateAdded: weekAgo
                .subtract(const Duration(minutes: 1))
                .millisecondsSinceEpoch,
          ),
          _item(2, 'boundary', dateAdded: weekAgo.millisecondsSinceEpoch),
          _item(3, 'fresh', dateAdded: now.millisecondsSinceEpoch),
          _item(4, 'unknown'),
        ],
        3,
        now: now,
      );

      expect(grouping.addedThisWeek, 2);
    });

    test('empty input yields empty grouping', () {
      final grouping = InventoryGrouping.partition(const [], 3, now: now);

      expect(grouping.expired, isEmpty);
      expect(grouping.expiringSoon, isEmpty);
      expect(grouping.good, isEmpty);
      expect(grouping.addedThisWeek, 0);
      expect(grouping.entries, isEmpty);
    });
  });

  group('InventoryGrouping.entries', () {
    test('flattens sections with headers before each non-empty bucket', () {
      final grouping = InventoryGrouping.partition(
        [
          _item(1, 'expired', expiryDate: DateTime(2026, 8, 10)),
          _item(2, 'soon', expiryDate: DateTime(2026, 8, 13)),
        ],
        3,
        now: now,
      );

      final entries = grouping.entries;
      expect(entries, hasLength(4));
      expect(entries[0], isA<InventorySectionEntry>());
      expect(
        (entries[0] as InventorySectionEntry).section,
        InventorySection.expired,
      );
      expect((entries[1] as InventoryItemEntry).item.productName, 'expired');
      expect(
        (entries[2] as InventorySectionEntry).section,
        InventorySection.expiringSoon,
      );
      expect((entries[3] as InventoryItemEntry).item.productName, 'soon');
    });

    test('omits headers for empty buckets', () {
      final grouping = InventoryGrouping.partition(
        [_item(1, 'good', expiryDate: DateTime(2026, 9))],
        3,
        now: now,
      );

      final entries = grouping.entries;
      expect(entries, hasLength(2));
      expect(
        (entries[0] as InventorySectionEntry).section,
        InventorySection.good,
      );
      expect((entries[1] as InventoryItemEntry).item.productName, 'good');
    });
  });
}
