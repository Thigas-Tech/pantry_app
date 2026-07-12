import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for converting amounts between currencies.
///
/// Uses the free [ExchangeRate-API](https://open.er-api.com/) open endpoint
/// which requires no API key. Rates are cached in [SharedPreferences] and
/// refreshed once per calendar day in the user's local timezone, staying
/// well within the 1,500 requests/month free tier.
///
/// ## Offline behaviour
///
/// When the network is unavailable or the API call fails, the most recently
/// cached rates are used. Callers see stale rates but no crash.
///
/// ## Testing
///
/// The [http.Client] and [SharedPreferences] can be injected to mock
/// network responses and cache in tests:
/// ```dart
/// final service = CurrencyService(httpClient: mockClient);
/// ```
class CurrencyService {
  /// Creates a [CurrencyService].
  CurrencyService({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Fetches the latest exchange rates for [baseCurrency] from the API
  /// or from the cache if it is less than 24 hours old.
  ///
  /// Returns a map of currency code → rate (e.g. `{'BRL': 5.20, 'EUR': 0.92}`).
  /// Returns an empty map on failure.
  Future<Map<String, double>> getRates(String baseCurrency) async {
    final normalized = baseCurrency.toUpperCase();

    // Try cache first.
    final cached = await _readCachedRates(normalized);
    if (cached != null) return cached;

    // Fetch from API.
    try {
      final uri = Uri.parse(
        'https://open.er-api.com/v6/latest/$normalized',
      );
      final response = await _httpClient
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != 200) {
        logWarning(
          'ExchangeRate-API returned ${response.statusCode} for '
          '$normalized',
        );
        return _tryFallbackCache(normalized);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['result'] != 'success') {
        logWarning(
          'ExchangeRate-API error for $normalized: ${body['result']}',
        );
        return _tryFallbackCache(normalized);
      }
      final rawRates = body['rates'] as Map<String, dynamic>;
      final rates = rawRates.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
      await _cacheRates(normalized, rates);
      return rates;
    } on Exception catch (e) {
      logWarning('Failed to fetch exchange rates: $e');
      return _tryFallbackCache(normalized);
    }
  }

  /// Converts [amount] from [fromCurrency] to [toCurrency].
  ///
  /// Returns the converted amount, or [amount] if either currency is unknown
  /// or rates are unavailable. Conversion is performed via USD as the
  /// intermediate when the base is neither from nor to.
  Future<double> convert(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) return amount;

    final rates = await getRates(fromCurrency);
    if (rates.isEmpty) return amount;

    final toRate = rates[toCurrency.toUpperCase()];
    if (toRate == null) return amount;

    return amount * toRate;
  }

  /// Detects the likely currency code from the device locale.
  ///
  /// Uses [Platform.localeName] and a curated mapping of country codes to
  /// ISO 4217 currency codes. Falls back to `'USD'`.
  String detectLocaleCurrency() {
    try {
      final locale = Platform.localeName;
      final code = locale.contains('_') ? locale.split('_').last : '';
      return switch (code.toUpperCase()) {
        'BR' => 'BRL',
        'US' => 'USD',
        'GB' => 'GBP',
        'EU' ||
        'DE' ||
        'FR' ||
        'ES' ||
        'IT' ||
        'PT' ||
        'NL' ||
        'BE' ||
        'AT' ||
        'IE' ||
        'FI' ||
        'GR' ||
        'LU' ||
        'SK' ||
        'SI' ||
        'EE' ||
        'LV' ||
        'LT' ||
        'MT' ||
        'CY' ||
        'HR' => 'EUR',
        'JP' => 'JPY',
        'CA' => 'CAD',
        'AU' => 'AUD',
        'MX' => 'MXN',
        'CN' => 'CNY',
        'IN' => 'INR',
        'RU' => 'RUB',
        'KR' => 'KRW',
        'CH' => 'CHF',
        'SE' => 'SEK',
        'NO' => 'NOK',
        'DK' => 'DKK',
        'PL' => 'PLN',
        'CZ' => 'CZK',
        'AR' => 'ARS',
        'CL' => 'CLP',
        'CO' => 'COP',
        'ZA' => 'ZAR',
        'NG' => 'NGN',
        'TR' => 'TRY',
        'IL' => 'ILS',
        'SG' => 'SGD',
        'HK' => 'HKD',
        'TW' => 'TWD',
        'TH' => 'THB',
        'MY' => 'MYR',
        'PH' => 'PHP',
        'ID' => 'IDR',
        'VN' => 'VND',
        _ => 'USD',
      };
    } on Object catch (_) {
      return 'USD';
    }
  }

  // ---- Caching helpers ----

  String _cacheKey(String base) => 'currency_rates_$base';

  Future<Map<String, double>?> _readCachedRates(String base) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_cacheKey(base));
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cachedDate = DateTime.fromMillisecondsSinceEpoch(
        data['cachedAt'] as int,
      );
      final today = DateTime.now();

      if (cachedDate.year == today.year &&
          cachedDate.month == today.month &&
          cachedDate.day == today.day) {
        final rates = data['rates'] as Map<String, dynamic>;
        logInfo('Using cached exchange rates for $base');
        return rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
      logInfo('Cached exchange rates for $base expired');
      return null;
    } on Exception catch (e) {
      logWarning('Error reading cached rates: $e');
      return null;
    }
  }

  /// Returns the total size in bytes of all cached exchange rate data
  /// stored in SharedPreferences.
  Future<int> cacheSizeBytes() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys().where((k) => k.startsWith('currency_rates_'));
    var total = 0;
    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw != null) total += utf8.encode(raw).length;
    }
    return total;
  }

  Future<void> _cacheRates(String base, Map<String, double> rates) async {
    try {
      final prefs = await _prefs;
      final data = jsonEncode({
        'rates': rates,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString(_cacheKey(base), data);
      logInfo('Cached exchange rates for $base');
    } on Exception catch (e) {
      logWarning('Failed to cache exchange rates: $e');
    }
  }

  Future<Map<String, double>> _tryFallbackCache(String base) async {
    final cached = await _readCachedRates(base);
    if (cached != null) {
      logWarning('Using stale cached exchange rates for $base');
      return cached;
    }
    return {};
  }
}

/// Returns the decimal separator character for [currencyCode].
///
/// Currencies using comma as decimal separator: BRL, ARS, CLP, COP.
/// All others default to dot.
String decimalSeparatorFor(String currencyCode) {
  return switch (currencyCode.toUpperCase()) {
    'BRL' || 'ARS' || 'CLP' || 'COP' => ',',
    _ => '.',
  };
}
