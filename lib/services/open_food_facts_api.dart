import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_api_service.dart';

/// Open Food Facts API client.
///
/// Implements [ProductApiService] to fetch product data by barcode from
/// the Open Food Facts database (v3 API). It supports both the production
/// server (`world.openfoodfacts.org`) and the staging server
/// (`world.openfoodfacts.net`) for testing.
///
/// ## Authentication
///
/// The constructor requires a [userId] and [password] for product
/// submissions. These are sent as query parameters to the legacy
/// `/cgi/product_jqm2.pl` endpoint. For the v3 PATCH endpoint, a session
/// cookie is needed instead.
///
/// ## User‑Agent
///
/// Open Food Facts requires a descriptive `User-Agent` header. This is
/// generated automatically from [appName], [appVersion], and [contactEmail].
///
/// ## Parsing
///
/// Product JSON from the v3 API is parsed into a [Product] model inside
/// `_parseProduct`. Nutrition values are extracted from the `nutriments`
/// map and are always per 100 g / 100 ml.
class OpenFoodFactsApi implements ProductApiService {
  /// Creates an [OpenFoodFactsApi] client.
  ///
  /// The [dio] instance is injected via the provider system.
  /// [userId] and [password] are **required** for product submission.
  /// [useStaging] determines which server to target.
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

  /// Whether to use the staging server (`true`) or production (`false`).
  final bool useStaging;

  /// Returns the base URL based on [useStaging].
  String get _baseUrl => useStaging
      ? 'https://world.openfoodfacts.net'
      : 'https://world.openfoodfacts.org';

  /// Constructs the `User-Agent` header as required by Open Food Facts.
  String get _userAgent => '$appName/$appVersion ($contactEmail)';

  /// Fetches product information for the given [barcode] from the v3 API.
  ///
  /// Throws [ProductNotFoundException] if the product does not exist
  /// (HTTP 404 or status `"failure"`). For other network errors, the
  /// underlying [DioException] is rethrown so the repository can handle it.
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
      if (e.response?.statusCode == 404) {
        throw ProductNotFoundException('Product not found: $barcode');
      }
      rethrow;
    }
  }

  /// Parses a raw v3 product JSON into a [Product] model.
  ///
  /// All nutrition values are extracted from the `nutriments` map.
  /// Missing values are left as `null`. Numeric fields may arrive as
  /// integers, doubles, or strings, so `_parseDouble` handles all cases.
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

  /// Converts a dynamic API value to a [double], handling integers and
  /// strings.
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Submits a new product using the legacy Open Food Facts API.
  ///
  /// Returns `true` on success (HTTP 200 or 302). All fields use the
  /// `add_` prefix to avoid overwriting existing data.
  Future<bool> submitProduct(Product product) async {
    try {
      final params = <String, dynamic>{
        'code': product.barcode,
        'user_id': userId,
        'password': password,
        'comment':
            // ignore: lines_longer_than_80_chars
            'Edit by $appName $appVersion - ${DateTime.now().millisecondsSinceEpoch}',
        'add_product_name': product.name,
      };

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

      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      debugPrint('Error submitting product: $e');
      return false;
    }
  }

  /// Submits a product using the v3 PATCH API (requires a session cookie).
  ///
  /// This is the recommended method for new integrations but requires the
  /// user to be logged in first.
  Future<bool> submitProductV3(Product product, String sessionCookie) async {
    try {
      final url = '$_baseUrl/api/v3/product/${product.barcode}';
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
      if (product.fatG != null) nutriments['fat_100g'] = product.fatG;
      if (product.fiberG != null) nutriments['fiber_100g'] = product.fiberG;
      if (product.saltG != null) nutriments['salt_100g'] = product.saltG;
      if (nutriments.isNotEmpty) productData['nutriments'] = nutriments;

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
