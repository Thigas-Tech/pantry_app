import 'package:dio/dio.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/product_api_service.dart';

class OpenFoodFactsApi implements ProductApiService {
  OpenFoodFactsApi(this._dio);
  final Dio _dio;

  @override
  Future<Product> getByBarcode(String barcode) async {
    final url = 'https://world.openfoodfacts.org/api/v2/product/$barcode.json';
    final response = await _dio.get(url);
    final data = response.data as Map<String, dynamic>;

    if (data['status'] != 1 || data['product'] == null) {
      throw ProductNotFoundException('Product not found: $barcode');
    }

    final productJson = data['product'] as Map<String, dynamic>;
    return _parseProduct(productJson);
  }

  Product _parseProduct(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};

    return Product(
      barcode: json['_id'] as String? ?? '',
      name: json['product_name'] as String? ?? 'Unknown',
      brand: json['brands'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['categories'] as String?,
      ingredients: (json['ingredients_text'] as String?),
      servingSize: json['serving_size'] as String?,
      energyKcal: _parseDouble(nutriments['energy-kcal_100g']),
      proteinG: _parseDouble(nutriments['proteins_100g']),
      carbsG: _parseDouble(nutriments['carbohydrates_100g']),
      fatG: _parseDouble(nutriments['fat_100g']),
      fiberG: _parseDouble(nutriments['fiber_100g']),
      saltG: _parseDouble(nutriments['salt_100g']),
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class ProductNotFoundException implements Exception {
  ProductNotFoundException(this.message);
  final String message;

  @override
  String toString() => message;
}
