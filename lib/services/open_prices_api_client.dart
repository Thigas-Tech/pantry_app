import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pantry_app/config.dart';
import 'package:pantry_app/utils/logger.dart';

/// A price observation fetched from the Open Prices API.
///
/// Maps to the `/api/v1/prices` response item. Only fields relevant to the
/// app are extracted; the full response includes deeply nested `product`,
/// `location`, and `proof` objects.
///
/// Reference: https://openfoodfacts.github.io/open-prices/
class RemotePrice {
  /// Creates a [RemotePrice].
  const RemotePrice({
    required this.id,
    required this.productCode,
    required this.price,
    required this.currency,
    this.productName,
    this.store,
    this.date,
  });

  /// Creates a [RemotePrice] from a JSON map returned by the Open Prices API.
  factory RemotePrice.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final proof = json['proof'] as Map<String, dynamic>?;
    return RemotePrice(
      id: json['id'] as int,
      productCode: json['product_code'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      productName:
          json['product_name'] as String? ??
          product?['product_name'] as String?,
      store:
          location?['osm_name'] as String? ??
          location?['osm_display_name'] as String?,
      date: json['date'] as String? ?? proof?['date'] as String?,
    );
  }

  /// Open Prices identifier.
  final int id;

  /// Product barcode (e.g. `"5449000000996"`).
  final String productCode;

  /// Monetary amount.
  final double price;

  /// ISO 4217 currency code (e.g. `"EUR"`, `"BRL"`).
  final String currency;

  /// Product display name, if available.
  final String? productName;

  /// Store name from the associated OSM location.
  final String? store;

  /// ISO date string (`YYYY-MM-DD`).
  final String? date;
}

/// Result of fetching prices from the Open Prices API.
class FetchPricesResult {
  /// Creates a [FetchPricesResult].
  const FetchPricesResult({
    required this.prices,
    required this.total,
    this.page,
    this.pages,
  });

  /// Parsed price observations for the current page.
  final List<RemotePrice> prices;

  /// Total count across all pages.
  final int total;

  /// Current page number.
  final int? page;

  /// Total number of pages.
  final int? pages;
}

/// Result of a price submission to Open Prices.
class SubmitPriceResult {
  /// Creates a [SubmitPriceResult].
  const SubmitPriceResult({
    required this.success,
    this.remoteId,
    this.errorMessage,
  });

  /// Whether the submission succeeded.
  final bool success;

  /// The remote price ID on Open Prices, if created.
  final int? remoteId;

  /// An error description, if the submission failed.
  final String? errorMessage;
}

/// HTTP client for the Open Prices community API.
///
/// ## Base URL
///
/// Production: `https://prices.openfoodfacts.org/api/v1`
/// Pre-production: `https://prices.openfoodfacts.net/api/v1`
///
/// ## Authentication
///
/// Most read endpoints are public. Write endpoints require a Bearer token
/// generated from an Open Food Facts account. The token is read from
/// [AppConfig.openPricesToken] by default, or overridden via the
/// [token] constructor parameter.
///
/// **How to get a token:**
/// 1. Create/Log in at https://world.openfoodfacts.org
/// 2. Post to `https://prices.openfoodfacts.org/api/v1/auth/token` with
///    your OFF credentials to generate an Open Prices token.
///
/// ## Error handling
///
/// Network errors and non-2xx responses are caught and returned as
/// [FetchPricesResult] with an empty list, or [SubmitPriceResult] with
/// `success = false`. No exceptions are thrown.
///
/// Reference: https://openfoodfacts.github.io/open-prices/guides/API/
class OpenPricesApiClient {
  /// Creates an [OpenPricesApiClient].
  OpenPricesApiClient({
    http.Client? client,
    String? baseUrl,
    this.token,
    String? contactEmail,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? 'https://prices.openfoodfacts.org/api/v1',
       _contactEmail = contactEmail ?? AppConfig.contactEmail;

  final http.Client _client;
  final String _baseUrl;
  final String _contactEmail;

  /// Optional Bearer token override. When null, falls back to
  /// [AppConfig.openPricesToken].
  final String? token;

  String get _effectiveToken => token ?? AppConfig.openPricesToken;

  /// Whether a non-empty token is configured.
  bool get hasToken => _effectiveToken.isNotEmpty;

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'User-Agent': 'PantryApp/0.0.5+1 ($_contactEmail)',
    if (_effectiveToken.isNotEmpty) 'Authorization': 'Bearer $_effectiveToken',
  };

  /// Fetches prices for the given [barcode] from the Open Prices API.
  ///
  /// The API uses `product_code` as the query parameter (the normalized
  /// barcode string). Results are ordered by date descending (newest first).
  Future<FetchPricesResult> fetchPricesByBarcode(
    String barcode, {
    int page = 1,
    int pageSize = 25,
  }) async {
    final uri = Uri.parse('$_baseUrl/prices').replace(
      queryParameters: {
        'product_code': barcode,
        'order': 'desc',
        'page': page.toString(),
        'size': pageSize.toString(),
      },
    );
    try {
      final response = await _client.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['items'] as List<dynamic>?) ?? [];
        return FetchPricesResult(
          prices: items
              .map((e) => RemotePrice.fromJson(e as Map<String, dynamic>))
              .toList(),
          total: (body['total'] as num?)?.toInt() ?? 0,
          page: (body['page'] as num?)?.toInt(),
          pages: (body['pages'] as num?)?.toInt(),
        );
      }
      logWarning(
        'Open Prices API fetch failed: ${response.statusCode}',
      );
      return const FetchPricesResult(prices: [], total: 0);
    } on Exception catch (e) {
      logWarning('Open Prices API fetch error: $e');
      return const FetchPricesResult(prices: [], total: 0);
    }
  }

  /// Validates the configured Bearer token against the Open Prices API.
  ///
  /// Calls a lightweight authenticated endpoint (`GET /api/v1/prices` with
  /// `page=1&size=1`). Returns `true` on 200, `false` on 401 or network
  /// error.
  Future<bool> validateToken() async {
    if (_effectiveToken.isEmpty) return false;
    final uri = Uri.parse('$_baseUrl/prices').replace(
      queryParameters: {'page': '1', 'size': '1'},
    );
    try {
      final response = await _client.get(uri, headers: _authHeaders);
      return response.statusCode == 200;
    } on Exception catch (e) {
      logWarning('Open Prices API token validation error: $e');
      return false;
    }
  }

  /// Submits a new price to the Open Prices API.
  ///
  /// **Important:** The Open Prices API requires a [Proof](https://openfoodfacts.github.io/open-prices/topics/core/)
  /// (receipt or shelf-label image) for every price write. Until the app
  /// supports proof upload, this method is a placeholder.
  ///
  /// Required fields on the API: `product_code`, `price`, `currency`,
  /// `proof_id`, `type`. The [proofId] parameter is mandatory.
  Future<SubmitPriceResult> submitPrice({
    required String barcode,
    required double price,
    required String currency,
    required int proofId,
    int? locationOsmId,
    String? locationOsmType,
    String? date,
    String? store,
  }) async {
    if (_effectiveToken.isEmpty) {
      return const SubmitPriceResult(
        success: false,
        errorMessage: 'No API token configured',
      );
    }

    final uri = Uri.parse('$_baseUrl/prices');
    final body = <String, dynamic>{
      'product_code': barcode,
      'type': 'PRODUCT',
      'price': price,
      'currency': currency,
      'proof_id': proofId,
    };
    if (locationOsmId != null) body['location_osm_id'] = locationOsmId;
    if (locationOsmType != null) body['location_osm_type'] = locationOsmType;
    if (date != null) body['date'] = date;

    try {
      final response = await _client.post(
        uri,
        headers: _authHeaders,
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final remoteId = data['id'] as int?;
        logInfo('Price submitted to Open Prices: id=$remoteId');
        return SubmitPriceResult(success: true, remoteId: remoteId);
      }
      logWarning(
        'Open Prices API submit failed: ${response.statusCode}',
      );
      return SubmitPriceResult(
        success: false,
        errorMessage: 'HTTP ${response.statusCode}',
      );
    } on Exception catch (e) {
      logWarning('Open Prices API submit error: $e');
      return SubmitPriceResult(success: false, errorMessage: e.toString());
    }
  }

  /// Disposes the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
