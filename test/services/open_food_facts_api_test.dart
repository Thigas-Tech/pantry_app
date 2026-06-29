/// Tests for [OpenFoodFactsApi.getByBarcode] using a mock HTTP adapter.
///
/// Covers successful parsing, product‑not‑found responses, 404 handling,
/// and network error propagation.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late Dio dio;
  late MockHttpClientAdapter adapter;
  late OpenFoodFactsApi api;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    dio = Dio();
    dio.httpClientAdapter = adapter;
    api = OpenFoodFactsApi(
      dio,
      userId: 'test',
      password: 'test',
      useStaging: false,
    );
  });

  group('getByBarcode', () {
    final sampleResponse = {
      'status': 'success',
      'product': {
        '_id': '123',
        'product_name': 'Test',
        'brands': 'Brand',
        'image_url': 'img',
        'categories': 'Cat',
        'ingredients_text': 'sugar',
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
      /// A valid response with status 'success' yields a fully populated
      /// [Product].
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
      expect(product.name, 'Test');
      expect(product.energyKcal, 100);
      expect(product.proteinG, 5.5);
      expect(product.imageUrl, 'img');
      expect(product.lastSynced, isNotNull);
    });

    test('throws ProductNotFoundException on status failure', () async {
      /// When the API returns status 'failure', a
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

    test('throws ProductNotFoundException on 404', () async {
      /// An HTTP 404 response is converted to a
      /// [ProductNotFoundException].
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('Not Found', 404, headers: {}),
      );

      expect(
        () => api.getByBarcode('123'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test('rethrows DioException on network error (non-404)', () async {
      /// Network errors (other than 404) are re‑thrown as
      /// [DioException] so the repository can wrap them in
      /// [FetchFailedException].
      when(
        () => adapter.fetch(any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions()));

      expect(() => api.getByBarcode('123'), throwsA(isA<DioException>()));
    });
  });
}
