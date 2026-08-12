/// Represents a pantry (inventory) summary row from the inventories table.
///
/// This is the typed view of an `inventories` row (with its computed
/// item count) so that UI code never touches raw database maps. All fields
/// are immutable.
class InventorySummary {
  /// Creates an [InventorySummary].
  const InventorySummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.itemCount,
  });

  /// Maps a raw `inventories` row into an [InventorySummary].
  ///
  /// Missing or malformed values fall back to safe defaults (empty name,
  /// epoch timestamp, zero item count) instead of throwing.
  factory InventorySummary.fromMap(Map<String, Object?> map) {
    return InventorySummary(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as num?)?.toInt() ?? 0,
      ),
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// The inventory id (primary key).
  final int id;

  /// The pantry display name.
  final String name;

  /// When the pantry was created.
  final DateTime createdAt;

  /// Number of items currently stored in this pantry.
  final int itemCount;
}
