import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_api_service.dart';

class OpenFoodFactsApi implements ProductApiService {
  OpenFoodFactsApi(
    this._dio, {
    required this.userId,
    required this.password,
    this.appName = 'PantryApp',
    this.appVersion = '1.0',
    this.contactEmail = 'thiago.assisfernandes@gmail.com',
    this.useStaging = true,
  });

  final Dio _dio;
  final String userId;
  final String password;
  final String appName;
  final String appVersion;
  final String contactEmail;
  final bool useStaging;

  String get _baseUrl => useStaging
      ? 'https://world.openfoodfacts.net'
      : 'https://world.openfoodfacts.org';

  String get _userAgent => '$appName/$appVersion ($contactEmail)';

  @override
  @override
  Future<Product> getByBarcode(String barcode) async {
    final url = '$_baseUrl/api/v3/product/$barcode.json';
    try {
      final response = await _dio.get(
        url,
        options: Options(headers: {'User-Agent': _userAgent}),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'success' || data['product'] == null) {
        throw ProductNotFoundException('Product not found: $barcode');
      }
      final productJson = data['product'] as Map<String, dynamic>;
      return _parseProduct(productJson);
    } on DioException catch (e) {
      // If the server returned a 404 Not Found, treat as product not found
      if (e.response?.statusCode == 404) {
        throw ProductNotFoundException('Product not found: $barcode');
      }
      // Re-throw network errors etc. – repository will handle them
      rethrow;
    }
  }

  Product _parseProduct(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};

    return Product(
      barcode: json['_id'] as String? ?? '',
      name: json['product_name'] as String? ?? 'Unknown',
      brand: json['brands'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['categories'] as String?,
      ingredients: json['ingredients_text'] as String?,
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

  /// Submit a new product to Open Food Facts using the legacy API.
  /// Returns true on success, false if something goes wrong.
  Future<bool> submitProduct(Product product) async {
    try {
      // Build query parameters with authentication
      final params = <String, dynamic>{
        'code': product.barcode,
        'user_id': userId,
        'password': password,
        'comment':
            // ignore: lines_longer_than_80_chars
            'Edit by $appName $appVersion - ${DateTime.now().millisecondsSinceEpoch}',
        // Use add_ prefix to avoid overwriting existing data
        'add_product_name': product.name,
      };

      // Add optional fields with add_ prefix
      if (product.brand != null && product.brand!.isNotEmpty) {
        params['add_brands'] = product.brand;
      }
      if (product.category != null && product.category!.isNotEmpty) {
        params['add_categories'] = product.category;
      }
      if (product.ingredients != null && product.ingredients!.isNotEmpty) {
        params['add_ingredients_text'] = product.ingredients;
      }
      if (product.servingSize != null && product.servingSize!.isNotEmpty) {
        params['add_serving_size'] = product.servingSize;
      }

      // Nutrition fields
      if (product.energyKcal != null) {
        params['add_nutriments_energy-kcal_100g'] = product.energyKcal
            .toString();
      }
      if (product.proteinG != null) {
        params['add_nutriments_proteins_100g'] = product.proteinG.toString();
      }
      if (product.carbsG != null) {
        params['add_nutriments_carbohydrates_100g'] = product.carbsG.toString();
      }
      if (product.fatG != null) {
        params['add_nutriments_fat_100g'] = product.fatG.toString();
      }
      if (product.fiberG != null) {
        params['add_nutriments_fiber_100g'] = product.fiberG.toString();
      }
      if (product.saltG != null) {
        params['add_nutriments_salt_100g'] = product.saltG.toString();
      }

      // Send as query parameters (the legacy API expects this)
      final url = '$_baseUrl/cgi/product_jqm2.pl';
      final response = await _dio.post(
        url,
        queryParameters: params,
        options: Options(
          headers: {
            'User-Agent': _userAgent,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      // Check for success (200 OK or 302 redirect)
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      // Log the error for debugging
      debugPrint('Error submitting product: $e');
      return false;
    }
  }

  /// Alternative: Use the new v3 PATCH API (recommended for new integrations).
  /// Note: This requires a session cookie from a prior login.
  Future<bool> submitProductV3(Product product, String sessionCookie) async {
    try {
      final url = '$_baseUrl/api/v3/product/${product.barcode}';

      // Build the structured product data
      final productData = <String, dynamic>{'product_name': product.name};

      if (product.brand != null && product.brand!.isNotEmpty) {
        productData['brands'] = product.brand;
      }
      if (product.category != null && product.category!.isNotEmpty) {
        productData['categories'] = product.category;
      }
      if (product.ingredients != null && product.ingredients!.isNotEmpty) {
        productData['ingredients_text'] = product.ingredients;
      }
      if (product.servingSize != null && product.servingSize!.isNotEmpty) {
        productData['serving_size'] = product.servingSize;
      }

      final nutriments = <String, dynamic>{};
      if (product.energyKcal != null) {
        nutriments['energy-kcal_100g'] = product.energyKcal;
      }
      if (product.proteinG != null) {
        nutriments['proteins_100g'] = product.proteinG;
      }
      if (product.carbsG != null) {
        nutriments['carbohydrates_100g'] = product.carbsG;
      }
      if (product.fatG != null) {
        nutriments['fat_100g'] = product.fatG;
      }
      if (product.fiberG != null) {
        nutriments['fiber_100g'] = product.fiberG;
      }
      if (product.saltG != null) {
        nutriments['salt_100g'] = product.saltG;
      }
      if (nutriments.isNotEmpty) {
        productData['nutriments'] = nutriments;
      }

      final response = await _dio.patch(
        url,
        data: {'product': productData},
        options: Options(
          headers: {
            'User-Agent': _userAgent,
            'Cookie': sessionCookie,
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error submitting product via v3: $e');
      return false;
    }
  }
}
