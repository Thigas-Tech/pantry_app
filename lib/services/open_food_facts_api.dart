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

  /// Submit a new product to Open Food Facts.
  /// Returns true on success, false if something goes wrong.
  Future<bool> submitProduct(Product product) async {
    try {
      final formData = <String, dynamic>{
        'code': product.barcode,
        'product_name': product.name,
        'brands': product.brand ?? '',
        'categories': product.category ?? '',
        'ingredients_text': product.ingredients ?? '',
        'serving_size': product.servingSize ?? '',
      };

      // Add nutrition fields only if they are not null
      if (product.energyKcal != null) {
        formData['nutriments.energy-kcal_100g'] = product.energyKcal.toString();
      }
      if (product.proteinG != null) {
        formData['nutriments.proteins_100g'] = product.proteinG.toString();
      }
      if (product.carbsG != null) {
        formData['nutriments.carbohydrates_100g'] = product.carbsG.toString();
      }
      if (product.fatG != null) {
        formData['nutriments.fat_100g'] = product.fatG.toString();
      }
      if (product.fiberG != null) {
        formData['nutriments.fiber_100g'] = product.fiberG.toString();
      }
      if (product.saltG != null) {
        formData['nutriments.salt_100g'] = product.saltG.toString();
      }

      final response = await _dio.post(
        'https://world.openfoodfacts.org/cgi/product_jqm2.pl',
        data: FormData.fromMap(formData),
        options: Options(
          headers: {
            'User-Agent':
                'PantryApp/1.0 (your.email@example.com)', // ← use the same contact
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 302;
    } catch (_) {
      return false;
    }
  }
}

class ProductNotFoundException implements Exception {
  ProductNotFoundException(this.message);
  final String message;

  @override
  String toString() => message;
}
