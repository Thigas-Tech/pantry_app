import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/usda_api_client.dart';

/// Provides a [UsdaApiClient] instance for USDA FoodData Central searches.
final usdaApiClientProvider = Provider<UsdaApiClient>((ref) {
  return UsdaApiClient();
});
