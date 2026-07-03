import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';

/// A fake [RequestOptions] for Mocktail fallback registration.
class FakeRequestOptions extends Fake implements RequestOptions {}

/// A mock of [HttpClientAdapter] to control HTTP responses.
class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

/// Tests for [OpenFoodFactsApi.getByBarcode] and
/// [OpenFoodFactsApi.submitProduct]
/// using a mock HTTP adapter.
void main() {
  late Dio dio;
  late MockHttpClientAdapter adapter;
  late OpenFoodFactsApi api;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    api = OpenFoodFactsApi(
      dio,
      userId: 'test-user',
      password: 'test-pass',
      useStaging: false, // production server
    );
  });

  group('getByBarcode', () {
    final sampleResponse = {
      'status': 'success',
      'product': {
        '_id': '123',
        'product_name': 'Test Product',
        'brands': 'Test Brand',
        'image_url': 'http://example.com/img.jpg',
        'categories': 'Test Category',
        'ingredients_text': 'sugar, water',
        'serving_size': '100 g',
        'nutriments': {
          'energy-kcal_100g': 100,
          'proteins_100g': 5.5,
          'carbohydrates_100g': 20.0,
          'fat_100g': 2.0,
          'fiber_100g': 1.0,
          'salt_100g': 0.5,
        },
      },
    };

    test('returns Product on success', () async {
      /// A valid API response with status `"success"` is parsed into a
      /// fully populated [Product].
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(sampleResponse),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );

      final product = await api.getByBarcode('123');
      expect(product.name, 'Test Product');
      expect(product.brand, 'Test Brand');
      expect(product.energyKcal, 100);
      expect(product.proteinG, 5.5);
      expect(product.imageUrl, 'http://example.com/img.jpg');
      expect(product.lastSynced, isNotNull);
    });

    test('throws ProductNotFoundException on status failure', () {
      /// When the API returns status `"failure"`, a
      /// [ProductNotFoundException] is thrown.
      final failureResponse = {'status': 'failure', 'product': null};
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(failureResponse),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );

      expect(
        () => api.getByBarcode('123'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test('throws ProductNotFoundException on 404', () {
      /// An HTTP 404 response is converted to a [ProductNotFoundException].
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('Not Found', 404, headers: {}),
      );

      expect(
        () => api.getByBarcode('123'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test('rethrows DioException on network error (non-404)', () {
      /// Network errors other than 404 are re‑thrown as [DioException].
      when(
        () => adapter.fetch(any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions()));

      expect(
        () => api.getByBarcode('123'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('submitProduct', () {
    const testProduct = Product(barcode: '123', name: 'Test');

    test('returns true on 200 OK', () async {
      /// A 200 status code indicates a successful submission.
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('', 200, headers: {}),
      );

      final result = await api.submitProduct(testProduct);
      expect(result, isTrue);
    });

    test('returns true on 302 redirect', () async {
      /// A 302 redirect also counts as success for the legacy API.
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('', 302, headers: {}),
      );

      final result = await api.submitProduct(testProduct);
      expect(result, isTrue);
    });

    test('returns false on 400 Bad Request', () async {
      /// Any other status code is treated as failure.
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('Bad Request', 400, headers: {}),
      );

      final result = await api.submitProduct(testProduct);
      expect(result, isFalse);
    });

    test('returns false on network error', () async {
      /// Network exceptions are caught and `false` is returned.
      when(
        () => adapter.fetch(any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions()));

      final result = await api.submitProduct(testProduct);
      expect(result, isFalse);
    });
  });
}
