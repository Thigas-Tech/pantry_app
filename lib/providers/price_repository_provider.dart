import 'package:pantry_app/providers/currency_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/open_prices_api_client.dart';
import 'package:pantry_app/services/open_prices_service.dart';
import 'package:pantry_app/services/price_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'price_repository_provider.g.dart';

/// Provides a singleton [PriceRepository] instance.
@Riverpod(keepAlive: true)
PriceRepository priceRepository(Ref ref) {
  return PriceRepository(
    ref.watch(databaseProvider),
    ref.watch(currencyServiceProvider),
    OpenPricesService(
      databaseHelper: ref.watch(databaseProvider),
      apiClient: OpenPricesApiClient(),
    ),
  );
}
