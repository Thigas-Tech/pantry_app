import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/plu_service.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:pantry_app/utils/logger.dart';

/// Unified search service for both barcoded and produce products.
///
/// Coordinates between the Open Food Facts API, the local PLU database,
/// and the USDA FoodData Central API to find products regardless of
/// whether they have a barcode.
///
/// ## Fallback chain
///
/// 1. OFF API by name — primary source, rich data, cached locally.
/// 2. USDA API — fallback for produce when OFF has no data.
/// 3. Results enriched with PLU codes from [PluService] where the name
///    matches a known PLU entry.
///
/// All results are returned as [Product] objects with [ProductType.produce]
/// set when a PLU match is found.
class ProduceSearchService {
  /// Creates a [ProduceSearchService].
  ///
  /// All dependencies are injectable for testing. In production they
  /// default to real instances via Riverpod providers.
  const ProduceSearchService({
    required this.offAdapter,
    required this.pluService,
    this.usdaClient,
  });

  /// The Open Food Facts API adapter.
  final OffAdapter offAdapter;

  /// The local PLU code→name mapping service.
  final PluService pluService;

  /// The USDA FoodData Central API client (optional fallback).
  final UsdaApiClient? usdaClient;

  /// Searches for products matching [query] across all available sources.
  ///
  /// [languageCode] requests product data in the user's preferred language
  /// from OFF. Results from the USDA API are always in English.
  Future<List<Product>> search(
    String query, {
    String languageCode = 'en',
  }) async {
    logInfo('Produce search for "$query"');

    // 1. OFF API
    final offResults = await offAdapter.searchProducts(
      query,
      languageCode: languageCode,
    );

    // 2. USDA fallback (only if OFF returned nothing)
    var usdaResults = <Product>[];
    if (offResults.isEmpty && usdaClient != null) {
      usdaResults = await usdaClient!.searchFood(query);
    }

    // 3. PLU enrichment
    final pluEntries = pluService.search(query);
    final pluBarcodeMap = <String, String>{
      for (final e in pluEntries) e.name.toLowerCase(): e.code,
    };

    // Merge and deduplicate
    final seen = <String>{};
    final results = <Product>[];

    for (final p in [...offResults, ...usdaResults]) {
      if (!seen.add(p.barcode)) continue;

      var productType = p.productType;
      var pluCode = p.pluCode;
      final pluMatch = pluBarcodeMap[p.name.toLowerCase()];
      if (pluMatch != null) {
        productType = ProductType.produce;
        pluCode = pluMatch;
      }

      results.add(
        p.copyWith(
          productType: productType,
          pluCode: pluCode ?? p.pluCode,
        ),
      );
    }

    logInfo('Produce search: ${results.length} results for "$query"');
    return results;
  }
}
