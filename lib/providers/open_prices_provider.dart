import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/open_prices_api_client.dart';
import 'package:pantry_app/services/open_prices_service.dart';

/// Provides a singleton [OpenPricesService] instance.
final openPricesServiceProvider = Provider<OpenPricesService>(
  (ref) => OpenPricesService(
    databaseHelper: ref.watch(databaseProvider),
    apiClient: OpenPricesApiClient(),
  ),
);
