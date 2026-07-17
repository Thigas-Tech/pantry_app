import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pantry_app/config.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/utils/logger.dart';

/// Client for the USDA FoodData Central REST API.
///
/// Searches for food items by name and returns normalized [Product] instances
/// with nutrition values per 100g. Used as a fallback when the Open Food
/// Facts API has insufficient produce data.
///
/// Requires a USDA Data.gov API key configured in [AppConfig.usdaApiKey].
/// The key is free and can be obtained at https://fdc.nal.usda.gov/api-key-signup.html.
class UsdaApiClient {
  /// Creates a [UsdaApiClient].
  ///
  /// [httpClient] and [apiKey] are injectable for testing. When omitted
  /// they default to a real [http.Client] and the configured key.
  UsdaApiClient({
    http.Client? httpClient,
    String? apiKey,
  }) : _client = httpClient ?? http.Client(),
       _apiKey = apiKey ?? AppConfig.usdaApiKey;

  final http.Client _client;
  final String _apiKey;

  /// Base URL for the FoodData Central API v1.
  static const _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  /// Searches for foods matching [query] and returns [Product] instances.
  ///
  /// Targets Foundation and SR Legacy food datasets for the most accurate
  /// nutrition data. Returns an empty list on any error (graceful degradation).
  ///
  /// Nutrition values are already per 100g in the USDA datasets for most
  /// whole foods. Generated products use a synthetic barcode prefixed with
  /// `'plu-'` and have [ProductType.produce].
  Future<List<Product>> searchFood(String query) async {
    if (_apiKey.isEmpty) {
      logWarning('USDA API key not configured — skipping USDA search');
      return [];
    }

    final uri = Uri.parse('$_baseUrl/foods/search').replace(
      queryParameters: {'api_key': _apiKey},
    );

    try {
      logInfo('Searching USDA for "$query"');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'dataType': ['Foundation', 'SR Legacy'],
          'pageSize': 10,
        }),
      );

      if (response.statusCode == 403) {
        logWarning(
          'USDA API returned 403 — check your API key in .env (USDA_API_KEY)',
        );
        return [];
      }
      if (response.statusCode != 200) {
        logWarning(
          'USDA search returned ${response.statusCode} for "$query"',
        );
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final foods = body['foods'] as List<dynamic>?;
      if (foods == null || foods.isEmpty) {
        logInfo('USDA: no results for "$query"');
        return [];
      }

      final products = <Product>[];
      for (final food in foods) {
        final product = _parseFood(food as Map<String, dynamic>);
        if (product != null) {
          products.add(product);
        }
      }

      logInfo('USDA: ${products.length} results for "$query"');
      return products;
    } on Exception catch (e) {
      logWarning('USDA search failed for "$query": $e');
      return [];
    }
  }

  /// Parses a food item from the USDA response into a [Product].
  Product? _parseFood(Map<String, dynamic> food) {
    final fdcId = food['fdcId'] as int?;
    final description = food['description'] as String?;
    if (fdcId == null || description == null) return null;

    final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];
    double? energyKcal;
    double? proteinG;
    double? carbsG;
    double? fatG;
    double? fiberG;

    for (final n in nutrients) {
      final nutrient = n as Map<String, dynamic>;
      final id = nutrient['nutrientId'] as int?;
      final value = (nutrient['value'] as num?)?.toDouble();
      if (value == null) continue;

      switch (id) {
        case 1008: // Energy (kcal)
          energyKcal = value;
        case 1003: // Protein
          proteinG = value;
        case 1005: // Carbohydrate
          carbsG = value;
        case 1004: // Fat
          fatG = value;
        case 1079: // Fiber
          fiberG = value;
      }
    }

    return Product(
      barcode: 'plu-$fdcId',
      name: description,
      productType: ProductType.produce,
      energyKcal: energyKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
