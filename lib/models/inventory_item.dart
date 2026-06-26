import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_item.freezed.dart';
part 'inventory_item.g.dart';

@freezed
abstract class InventoryItem with _$InventoryItem {
  const factory InventoryItem({
    required String barcode,
    int? id, // auto-increment, nullable for new items
    @Default(1) double quantity,
    @Default('pcs') String unit,
    String? expiryDate, // ISO 8601 format
    @Default('pantry') String location,
    String? notes,
    int? dateAdded, // epoch timestamp
  }) = _InventoryItem;

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);
}
