class InventoryWithProduct {
  const InventoryWithProduct({
    required this.barcode,
    required this.quantity,
    required this.unit,
    required this.location,
    this.id,
    this.expiryDate,
    this.notes,
    this.dateAdded,
    this.productName,
    this.productImageUrl,
  });

  factory InventoryWithProduct.fromMap(Map<String, dynamic> map) {
    return InventoryWithProduct(
      id: map['id'] as int?,
      barcode: map['barcode'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] as String? ?? 'pcs',
      expiryDate: map['expiry_date'] as String?,
      location: map['location'] as String? ?? 'pantry',
      notes: map['notes'] as String?,
      dateAdded: map['date_added'] as int?,
      productName: map['product_name'] as String?,
      productImageUrl: map['product_image_url'] as String?,
    );
  }
  final int? id;
  final String barcode;
  final double quantity;
  final String unit;
  final String? expiryDate;
  final String location;
  final String? notes;
  final int? dateAdded;
  final String? productName;
  final String? productImageUrl;
}
