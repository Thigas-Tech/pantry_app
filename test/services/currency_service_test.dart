import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late CurrencyService service;
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = MockHttpClient();
    service = CurrencyService(httpClient: mockClient);
  });

  group('decimalSeparatorFor', () {
    test('returns comma for BRL/ARS/CLP/COP', () {
      expect(decimalSeparatorFor('BRL'), ',');
      expect(decimalSeparatorFor('ARS'), ',');
      expect(decimalSeparatorFor('CLP'), ',');
      expect(decimalSeparatorFor('COP'), ',');
    });

    test('returns dot for USD and others', () {
      expect(decimalSeparatorFor('USD'), '.');
      expect(decimalSeparatorFor('EUR'), '.');
    });
  });

  group('currencySymbolFor', () {
    test('returns correct symbols', () {
      expect(currencySymbolFor('BRL'), r'R$');
      expect(currencySymbolFor('USD'), r'$');
      expect(currencySymbolFor('EUR'), '\u20AC');
      expect(currencySymbolFor('GBP'), '\u00A3');
    });

    test('returns ISO code for unknown currencies', () {
      expect(currencySymbolFor('XYZ'), 'XYZ');
    });
  });

  group('decimalDigitsFor', () {
    test('returns 0 for JPY and KRW', () {
      expect(decimalDigitsFor('JPY'), 0);
      expect(decimalDigitsFor('KRW'), 0);
    });

    test('returns 2 for others', () {
      expect(decimalDigitsFor('USD'), 2);
    });
  });

  group('detectLocaleCurrency', () {
    test('returns a non-empty currency code', () {
      final currency = service.detectLocaleCurrency();
      expect(currency, isNotEmpty);
      expect(currency.length, 3);
    });
  });

  group('getRates', () {
    test('returns parsed rates on successful API response', () async {
      final response = http.Response(
        jsonEncode({
          'result': 'success',
          'rates': {'BRL': 5.20, 'EUR': 0.92},
        }),
        200,
      );

      when(
        () => mockClient.get(
          Uri.parse('https://open.er-api.com/v6/latest/USD'),
        ),
      ).thenAnswer((_) async => response);

      final rates = await service.getRates('USD');
      expect(rates['BRL'], 5.20);
      expect(rates['EUR'], 0.92);
    });

    test('returns empty on non-200 response', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://open.er-api.com/v6/latest/USD'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      final rates = await service.getRates('USD');
      expect(rates, isEmpty);
    });

    test('returns empty on API error result', () async {
      final response = http.Response(
        jsonEncode({'result': 'error'}),
        200,
      );

      when(
        () => mockClient.get(
          Uri.parse('https://open.er-api.com/v6/latest/USD'),
        ),
      ).thenAnswer((_) async => response);

      final rates = await service.getRates('USD');
      expect(rates, isEmpty);
    });

    test('returns empty on network exception', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://open.er-api.com/v6/latest/USD'),
        ),
      ).thenThrow(Exception('Network error'));

      final rates = await service.getRates('USD');
      expect(rates, isEmpty);
    });

    test('uses cached rates when valid', () async {
      final cachedData = jsonEncode({
        'rates': {'BRL': 5.0},
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency_rates_USD', cachedData);

      final rates = await service.getRates('USD');
      expect(rates['BRL'], 5.0);

      verifyNever(() => mockClient.get(any()));
    });
  });

  group('convert', () {
    test('returns same amount when currencies match', () async {
      final result = await service.convert(10, 'USD', 'USD');
      expect(result, 10.0);
    });

    test('uses API when no cache available', () async {
      final response = http.Response(
        jsonEncode({
          'result': 'success',
          'rates': {'BRL': 5.0},
        }),
        200,
      );

      when(
        () => mockClient.get(
          Uri.parse('https://open.er-api.com/v6/latest/USD'),
        ),
      ).thenAnswer((_) async => response);

      final result = await service.convert(10, 'USD', 'BRL');
      expect(result, 50.0);
    });

    test('returns original amount when target currency unknown', () async {
      final response = http.Response(
        jsonEncode({
          'result': 'success',
          'rates': {'BRL': 5.0},
        }),
        200,
      );

      when(
        () => mockClient.get(
          Uri.parse('https://open.er-api.com/v6/latest/USD'),
        ),
      ).thenAnswer((_) async => response);

      final result = await service.convert(10, 'USD', 'XYZ');
      expect(result, 10.0);
    });

    test('returns original amount when rates unavailable', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://open.er-api.com/v6/latest/USD'),
        ),
      ).thenThrow(Exception('Offline'));

      final result = await service.convert(10, 'USD', 'BRL');
      expect(result, 10.0);
    });
  });

  group('cacheSizeBytes', () {
    test('returns 0 when no cached rates', () async {
      final size = await service.cacheSizeBytes();
      expect(size, 0);
    });

    test('returns non-zero when rates are cached', () async {
      final cachedData = jsonEncode({
        'rates': {'BRL': 5.0},
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency_rates_USD', cachedData);

      final size = await service.cacheSizeBytes();
      expect(size, greaterThan(0));
    });
  });
}
