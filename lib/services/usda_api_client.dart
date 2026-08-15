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

  /// Words in food descriptions that indicate a non-produce item or processed
  /// derivative rather than raw, unprocessed produce. Used to filter USDA
  /// search results. Each word is matched as a standalone word boundary, so
  /// "bread" does not match "breadfruit" and "egg" does not match "eggplant".
  static const _nonProduceMarkers = {
    // ---- Processing methods ----
    'canned', 'dried', 'dehydrated', 'frozen', 'powder',
    'sauce', 'paste', 'puree', 'pickled', 'stewed', 'creamed',
    'cooked', 'boiled', 'baked', 'fried', 'roasted', 'grilled',
    'smoked', 'candied', 'juice', 'ketchup', 'soup',
    'preserved', 'fermented', 'brined', 'concentrate', 'extract',
    // ---- Baked goods & pastries ----
    'croissant', 'croissants', 'strudel', 'danish', 'pastry', 'pastries',
    'muffin', 'muffins', 'coffeecake', 'coffeecakes', 'pie', 'cake', 'cakes',
    'cookie', 'cookies', 'doughnut', 'donut', 'brownie', 'cupcake',
    'pancake', 'waffle', 'pudding', 'biscuit', 'bagel', 'cracker',
    'cheesecake', 'tart', 'bread', 'bun', 'buns',
    // ---- Dairy & alternatives ----
    'butter', 'butters', 'yogurt', 'yoghurt', 'yogurts', 'yoghurts',
    'kefir', 'sherbet', 'milk', 'cheese', 'cream', 'creams',
    'buttermilk', 'lifeway', 'silk', 'nondairy',
    // ---- Beverages ----
    'beverage', 'beverages', 'tea', 'carbonated', 'soda', 'cola',
    'drink', 'drinks', 'smoothie', 'coffee', 'espresso', 'latte',
    'lemonade', 'wine', 'beer',
    // ---- Fast food / restaurant ----
    'mcdonald', 'restaurant', 'taco', 'tacos', 'burrito', 'pizza',
    'sandwich', 'burger', 'lasagna', 'entree', 'entrees', 'foods',
    // ---- Snacks & candy ----
    'snack', 'snacks', 'candy', 'candies', 'chocolate', 'mars',
    'twizzlers', 'atkins', 'snackfood', 'chip', 'chips', 'pretzel',
    'popcorn', 'granola',
    // ---- Condiments / spreads / toppings ----
    'topping', 'toppings', 'syrup', 'syrups', 'marmalade', 'jam', 'jelly',
    'honey',
    'oil',
    'vinegar',
    'mayonnaise',
    'mustard',
    'relish',
    'dip',
    'gravy',
    // ---- Diet / preparation descriptors ----
    'diet', 'unsweetened', 'unenriched', 'instant', 'dry', 'mix',
    // ---- Baby food ----
    'babyfood', 'infant',
    // ---- Prepared foods ----
    'souffle', 'appetizer', 'microwave', 'boxed', 'packaged', 'sundae',
    // ---- Meat / poultry / fish / eggs ----
    'beef', 'chicken', 'pork', 'lamb', 'turkey', 'duck',
    'fish', 'salmon', 'tuna', 'shrimp', 'crab', 'lobster',
    'meat', 'sausage', 'bacon', 'ham', 'egg', 'eggs',
    // ---- Grains (dried / processed) ----
    'pasta', 'noodle', 'noodles', 'spaghetti', 'rice', 'cereal',
    'oatmeal', 'porridge', 'grits', 'flour',
    // ---- Other non-produce ----
    'tofu', 'supplement',
  };

  final http.Client _client;
  final String _apiKey;

  /// Base URL for the FoodData Central API v1.
  static const _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  /// Returns true when [description] does not contain any non-produce
  /// marker as a standalone word, meaning it represents raw, unprocessed
  /// produce. Uses word-boundary matching to avoid false positives on
  /// embedded substrings (e.g., "bread" in "breadfruit").
  bool _isRawUnprocessed(String description) {
    final words = description.toLowerCase().split(RegExp('[^a-z0-9]+'));
    return !_nonProduceMarkers.any(words.contains);
  }

  /// Searches for foods matching [query] and returns [Product] instances.
  ///
  /// Targets Foundation and SR Legacy food datasets for the most accurate
  /// nutrition data. Filters out non-produce items (baked goods, dairy,
  /// fast food, etc.) and processed derivatives (canned, dried, powdered,
  /// etc.) keeping only raw, unprocessed produce.
  /// Returns an empty list on any error (graceful degradation).
  ///
  /// Nutrition values are already per 100g in the USDA datasets for most
  /// whole foods. Generated products use a synthetic barcode prefixed with
  /// 'plu-' and have [ProductType.produce].
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
        if (product != null && _isRawUnprocessed(product.name)) {
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
      // USDA products use synthetic plu- barcodes that cannot be re-fetched
      // from Open Food Facts, so they must never be treated as disposable
      // api cache rows (AGENTS rule 8).
      source: 'manual',
      energyKcal: energyKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Fetches the full food item from the USDA detail endpoint.
  ///
  /// Calls /v1/food/{fdcId}?format=full and returns the raw JSON
  /// response body as a Map. Returns null on any error.
  Future<Map<String, dynamic>?> _fetchFoodDetails(int fdcId) async {
    if (_apiKey.isEmpty) return null;

    final uri = Uri.parse('$_baseUrl/food/$fdcId').replace(
      queryParameters: {'api_key': _apiKey, 'format': 'full'},
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Exception {
      return null;
    }
  }

  /// Enriches a [Product] with USDA foodPortions data.
  ///
  /// Calls the detail endpoint for the given product. Only Foundation
  /// food items have foodPortions — SR Legacy items return null.
  /// Returns the enriched product or null when no portion data is
  /// available.
  Future<Product?> enrichProductWithServingData(Product product) async {
    final fdcIdStr = product.barcode.replaceFirst('plu-', '');
    final fdcId = int.tryParse(fdcIdStr);
    if (fdcId == null) return null;

    final details = await _fetchFoodDetails(fdcId);
    if (details == null) return null;

    final dataType = details['dataType'] as String?;
    if (dataType != 'Foundation') return null;

    final portions = details['foodPortions'] as List<dynamic>?;
    if (portions == null || portions.isEmpty) return null;

    final firstPortion = portions[0] as Map<String, dynamic>;
    final amount = (firstPortion['amount'] as num?)?.toDouble();
    final gramWeight = (firstPortion['gramWeight'] as num?)?.toDouble();
    if (amount == null || gramWeight == null) return null;

    final measureUnit = firstPortion['measureUnit'] as Map<String, dynamic>?;
    final unitName = measureUnit?['name'] as String?;

    return product.copyWith(
      usdaServingAmount: amount,
      usdaServingUnit: unitName,
      usdaGramWeight: gramWeight,
    );
  }
}
