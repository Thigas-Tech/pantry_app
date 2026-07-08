import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/currency_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/open_prices_service.dart';
import 'package:pantry_app/services/price_repository.dart';

/// Provides a singleton [PriceRepository] instance.
final priceRepositoryProvider = Provider<PriceRepository>(
  (ref) => PriceRepository(
    ref.watch(databaseProvider),
    ref.watch(currencyServiceProvider),
    OpenPricesService(databaseHelper: ref.watch(databaseProvider)),
  ),
);
