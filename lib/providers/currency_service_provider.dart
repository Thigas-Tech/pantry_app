import 'package:pantry_app/services/currency_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'currency_service_provider.g.dart';

/// Provides a singleton [CurrencyService] instance.
@Riverpod(keepAlive: true)
CurrencyService currencyService(Ref ref) {
  return CurrencyService();
}

/// Provides the size in bytes of the on-disk currency rate cache.
///
/// autoDispose: only needed while the settings screen is visible.
@riverpod
Future<int> currencyCacheSize(Ref ref) {
  return ref.read(currencyServiceProvider).cacheSizeBytes();
}
