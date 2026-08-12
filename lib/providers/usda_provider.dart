import 'package:pantry_app/services/usda_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'usda_provider.g.dart';

/// Provides a [UsdaApiClient] instance for USDA FoodData Central searches.
@Riverpod(keepAlive: true)
UsdaApiClient usdaApiClient(Ref ref) {
  return UsdaApiClient();
}
