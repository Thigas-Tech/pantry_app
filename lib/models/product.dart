import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String barcode,
    required String name,
    String? brand,
    String? imageUrl,
    String? category,
    String? ingredients, // comma-separated or future JSON list
    String? servingSize,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    double? saltG,
    int? lastSynced, // epoch timestamp
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
