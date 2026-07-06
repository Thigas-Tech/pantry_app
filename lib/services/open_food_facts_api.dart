import 'package:dio/dio.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/utils/logger.dart';

/// Open Food Facts API client.
///
/// Fetches product data by barcode from the Open Food Facts database (v3
/// API). It supports both the production server (`world.openfoodfacts.org`)
/// and the staging server (`world.openfoodfacts.net`) for testing.
class OpenFoodFactsApi {
  /// Creates an [OpenFoodFactsApi] client.
  OpenFoodFactsApi(
    this._dio, {
    required this.userId,
    required this.password,
    required this.contactEmail,
    this.appName = 'PantryApp',
    this.appVersion = '1.0',
    this.useStaging = true,
  });

  final Dio _dio;

  /// The Open Food Facts user ID for API authentication.
  final String userId;

  /// The Open Food Facts password for API authentication.
  final String password;

  /// The application name used in the `User-Agent` header.
  final String appName;

  /// The application version used in the `User-Agent` header.
  final String appVersion;

  /// The contact email used in the `User-Agent` header.
  final String contactEmail;

  /// Whether to use the staging server (`true`) or production (`false`).
  final bool useStaging;

  /// Returns the base URL based on [useStaging].
  String get _baseUrl => useStaging
      ? 'https://world.openfoodfacts.net'
      : 'https://world.openfoodfacts.org';

  /// Constructs the `User-Agent` header as required by Open Food Facts.
  String get _userAgent => '$appName/$appVersion ($contactEmail)';

  /// Fetches a product from Open Food Facts by its [barcode].
  ///
  /// Retries up to 3 times with exponential backoff (1s, 2s, 4s) when:
  /// - HTTP 429 (rate limited)
  /// - HTTP 5xx (server error)
  /// - Connection timeout, receive timeout, or connection refused
  ///
  /// HTTP 404 is **not** retried — it always throws
  /// [ProductNotFoundException] immediately.
  ///
  /// Throws [ProductNotFoundException] if the barcode is unknown or if all
  /// retries are exhausted on a retryable error.
  Future<Product> getByBarcode(String barcode) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);
    final url = '$_baseUrl/api/v3/product/$barcode.json';

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      logInfo('GET $url (attempt ${attempt + 1})');
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          url,
          options: Options(headers: {'User-Agent': _userAgent}),
        );
        logInfo('Response status: ${response.statusCode}');
        final data = response.data;
        if (data == null ||
            data['status'] != 'success' ||
            data['product'] == null) {
          throw ProductNotFoundException(barcode);
        }
        final productJson = data['product'] as Map<String, dynamic>;
        return _parseProduct(productJson);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          logWarning('404 for $barcode');
          throw ProductNotFoundException(barcode);
        }
        if (attempt < maxRetries && _isRetryable(e)) {
          final delay = baseDelay * (1 << attempt); // 1s, 2s, 4s
          logWarning(
            'Retryable error for $barcode (${_describeError(e)})'
            ' — retrying in ${delay.inSeconds}s',
          );
          await Future<void>.delayed(delay);
          continue;
        }
        logError('DioException for $barcode: ${e.message}');
        rethrow;
      } on Exception catch (e) {
        logError('Unexpected error fetching $barcode: $e');
        rethrow;
      }
    }
    // Unreachable — either the request succeeds or an exception is thrown.
    throw ProductNotFoundException(barcode);
  }

  /// Returns `true` when a [DioException] should be retried.
  bool _isRetryable(DioException e) {
    // Rate limited
    if (e.response?.statusCode == 429) return true;
    // Server error
    if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
      return true;
    }
    // Timeout / connection errors (no response)
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }
    return false;
  }

  /// Searches Open Food Facts by product name or barcode prefix.
  ///
  /// Uses the legacy search API at `$_baseUrl/cgi/search.pl`.
  /// Returns at most [pageSize] results (default 20).
  ///
  /// Returns an empty list on network errors (failures are silently logged).
  Future<List<Product>> searchProducts(
    String query, {
    int pageSize = 20,
  }) async {
    try {
      final url = '$_baseUrl/cgi/search.pl';
      logInfo('Searching OFF for "$query" (pageSize=$pageSize)');
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {
          'search_terms': query,
          'page_size': pageSize,
          'json': 1,
        },
        options: Options(headers: {'User-Agent': _userAgent}),
      );
      final data = response.data;
      if (data == null || data['products'] == null) {
        logInfo('OFF search returned no results for "$query"');
        return [];
      }
      final productsJson = data['products'] as List<dynamic>;
      final products = productsJson
          .cast<Map<String, dynamic>>()
          .map(_parseProduct)
          .where((p) => p.barcode.isNotEmpty)
          .toList();
      logInfo('OFF search returned ${products.length} products for "$query"');
      return products;
    } on DioException catch (e) {
      logWarning('OFF search failed for "$query": ${e.message}');
      return [];
    } on Exception catch (e) {
      logWarning('OFF search unexpected error for "$query": $e');
      return [];
    }
  }

  /// Returns a short human‑readable label for a [DioException] reason.
  String _describeError(DioException e) {
    if (e.response?.statusCode == 429) return '429';
    if (e.response?.statusCode != null) return '${e.response!.statusCode}';
    return switch (e.type) {
      DioExceptionType.connectionTimeout => 'connection timeout',
      DioExceptionType.receiveTimeout => 'receive timeout',
      DioExceptionType.sendTimeout => 'send timeout',
      DioExceptionType.connectionError => 'connection error',
      _ => e.message ?? 'unknown',
    };
  }

  Product _parseProduct(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};
    final nutriscoreData = json['nutriscore_data'] as Map<String, dynamic>?;

    return Product(
      barcode: json['_id'] as String? ?? '',
      name: json['product_name'] as String? ?? 'Unknown',
      brand: json['brands'] as String?,
      imageUrl: json['image_url'] as String?,
      offNutritionImageUrl: json['image_nutrition_url'] as String?,
      offIngredientsImageUrl: json['image_ingredients_url'] as String?,
      offProductImageUrl: json['image_front_url'] as String?,
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
      nutriscoreGrade: json['nutriscore_grade'] as String?,
      nutriscoreNotApplicableCategory:
          nutriscoreData?['nutriscore_not_applicable_for_category'] as String?,
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Submits a new product using the legacy Open Food Facts API.
  ///
  /// Returns `true` on success (HTTP 200 or 302).
  Future<bool> submitProduct(Product product) async {
    if (userId.isEmpty || password.isEmpty) {
      logWarning('Cannot submit product — no OFF credentials configured.');
      return false;
    }
    logInfo('Submitting product ${product.barcode} via legacy API');
    try {
      final params = <String, dynamic>{
        'code': product.barcode,
        'user_id': userId,
        'password': password,
        'comment':
            '''Edit by $appName $appVersion - ${DateTime.now().millisecondsSinceEpoch}''',
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
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        queryParameters: params,
        options: Options(
          headers: {
            'User-Agent': _userAgent,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status == 200 || status == 302,
        ),
      );

      final success = response.statusCode == 200 || response.statusCode == 302;
      if (success) {
        logInfo('Product ${product.barcode} submitted successfully');
      } else {
        logWarning(
          '''Product ${product.barcode} submission returned status ${response.statusCode}''',
        );
      }
      return success;
    } on Exception catch (e) {
      logError('Failed to submit product ${product.barcode}: $e');
      return false;
    }
  }

  /// Submits a product using the v3 PATCH API (requires a session cookie).
  Future<bool> submitProductV3(Product product, String sessionCookie) async {
    logInfo('Submitting product ${product.barcode} via v3 API');
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

      final response = await _dio.patch<Map<String, dynamic>>(
        url,
        data: {'product': productData},
        options: Options(
          headers: {
            'User-Agent': _userAgent,
            'Cookie': sessionCookie,
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status == 200 || status == 302,
        ),
      );

      final success = response.statusCode == 200;
      if (success) {
        logInfo('Product ${product.barcode} submitted successfully via v3');
      } else {
        logWarning(
          '''Product ${product.barcode} v3 submission returned status ${response.statusCode}''',
        );
      }
      return success;
    } on Exception catch (e) {
      logError('Failed to submit product ${product.barcode} via v3: $e');
      return false;
    }
  }

  /// Uploads a product image to Open Food Facts.
  ///
  /// Posts to `/cgi/product_image_upload.pl` with `user_id`, `password`,
  /// `code`, `imagefield`, and the binary image data.
  ///
  /// [barcode] is the product code. [imageField] determines the image type
  /// (e.g. `'front'`, `'ingredients'`, `'nutrition'`). [imageBytes] is the
  /// raw file content. [languageCode] (optional) appends a language suffix
  /// to the image field (e.g. `'front_en'`).
  ///
  /// Returns `true` if the upload succeeded (status `"status ok"`).
  ///
  /// **Not yet wired to the UI** — callers should check that credentials
  /// are configured before invoking this method.
  Future<bool> uploadProductImage({
    required String barcode,
    required String imageField,
    required List<int> imageBytes,
    String? languageCode,
  }) async {
    if (userId.isEmpty || password.isEmpty) {
      logWarning('Cannot upload image — no OFF credentials configured.');
      return false;
    }

    final field = languageCode != null
        ? '${imageField}_$languageCode'
        : imageField;
    logInfo('Uploading $field image for $barcode');

    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'password': password,
        'code': barcode,
        'imagefield': field,
        'imgupload_$field': MultipartFile.fromBytes(
          imageBytes,
          filename: '$field.jpg',
        ),
      });

      final url = '$_baseUrl/cgi/product_image_upload.pl';
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: formData,
        options: Options(
          headers: {'User-Agent': _userAgent},
        ),
      );

      final status = response.data?['status'] as String?;
      final success = status == 'status ok';
      if (success) {
        logInfo(
          'Image uploaded $barcode ($field) —'
          ' imgid: ${response.data?['imgid']}',
        );
      } else {
        logWarning('Image upload for $barcode failed: $status');
      }
      return success;
    } on Exception catch (e) {
      logError('Failed to upload image for $barcode: $e');
      return false;
    }
  }
}
