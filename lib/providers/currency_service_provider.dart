import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/currency_service.dart';

/// Provides a singleton [CurrencyService] instance.
final currencyServiceProvider = Provider<CurrencyService>(
  (ref) => CurrencyService(),
);
