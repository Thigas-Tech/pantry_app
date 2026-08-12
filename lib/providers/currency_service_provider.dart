import 'package:pantry_app/services/currency_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'currency_service_provider.g.dart';

/// Provides a singleton [CurrencyService] instance.
@Riverpod(keepAlive: true)
CurrencyService currencyService(Ref ref) {
  return CurrencyService();
}
