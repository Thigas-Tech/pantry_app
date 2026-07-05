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
      contactEmail: 'test@example.com',
      useStaging: false,
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
  group('submitProductV3', () {
    const testProduct = Product(barcode: '456', name: 'Test', energyKcal: 42);
    const sessionCookie = 'session=abc123';

    test('returns true on 200 OK', () async {
      /// A successful v3 PATCH returns true.
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('', 200, headers: {}),
      );

      final result = await api.submitProductV3(testProduct, sessionCookie);
      expect(result, isTrue);
    });

    test('returns false on network error', () async {
      /// Network exceptions are caught and `false` is returned.
      when(
        () => adapter.fetch(any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions()));

      final result = await api.submitProductV3(testProduct, sessionCookie);
      expect(result, isFalse);
    });
  });

  group('_parseDouble (via _parseProduct)', () {
    test('parses nutrition values that are strings', () async {
      /// Nutrition values may arrive as strings from the OFF API;
      /// _parseDouble converts them to double.
      final stringNutritionResponse = {
        'status': 'success',
        'product': {
          '_id': '789',
          'product_name': 'String Nutrition',
          'brands': null,
          'image_url': null,
          'categories': null,
          'ingredients_text': null,
          'serving_size': null,
          'nutriments': {
            'energy-kcal_100g': '200.5',
            'proteins_100g': '10.3',
            'carbohydrates_100g': '50',
            'fat_100g': 1.0,
            'fiber_100g': 0,
            'salt_100g': '0.75',
          },
        },
      };

      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(stringNutritionResponse),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );

      final product = await api.getByBarcode('789');
      expect(product.energyKcal, 200.5);
      expect(product.proteinG, 10.3);
      expect(product.carbsG, 50.0);
      expect(product.fatG, 1.0);
      expect(product.fiberG, 0.0);
      expect(product.saltG, 0.75);
    });
  });

  // -----------------------------------------------------------------
  // Group: submitProductV3 and uploadProductImage
  // -----------------------------------------------------------------

  group('submitProductV3', () {
    test('returns true on HTTP 200', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          '{"status":"ok"}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );

      final apiV3 = OpenFoodFactsApi(
        dio,
        userId: 'u',
        password: 'p',
        contactEmail: 't@t.com',
        useStaging: false,
      );
      final result = await apiV3.submitProductV3(
        const Product(barcode: '123', name: 'Test'),
        'session_cookie',
      );
      expect(result, isTrue);
    });

    test('returns false on non-200', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('{}', 500),
      );

      final apiV3 = OpenFoodFactsApi(
        dio,
        userId: 'u',
        password: 'p',
        contactEmail: 't@t.com',
        useStaging: false,
      );
      final result = await apiV3.submitProductV3(
        const Product(barcode: '123', name: 'Test'),
        'session_cookie',
      );
      expect(result, isFalse);
    });
  });

  group('uploadProductImage', () {
    test('returns true on success', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          '{"status":"status ok","imgid":42}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );

      final apiImg = OpenFoodFactsApi(
        dio,
        userId: 'u',
        password: 'p',
        contactEmail: 't@t.com',
        useStaging: false,
      );
      final result = await apiImg.uploadProductImage(
        barcode: '123',
        imageField: 'front',
        imageBytes: [1, 2, 3],
      );
      expect(result, isTrue);
    });

    test('returns false when credentials empty', () async {
      final apiNoAuth = OpenFoodFactsApi(
        dio,
        userId: '',
        password: '',
        contactEmail: 't@t.com',
      );
      final result = await apiNoAuth.uploadProductImage(
        barcode: '123',
        imageField: 'front',
        imageBytes: [1, 2, 3],
      );
      expect(result, isFalse);
    });
  });

  group('Real product fixtures', () {
    test('Nutella — grade E, 539 kcal', () async {
      final json = {
        'status': 'success',
        'product': {
          '_id': '3017620422003',
          'product_name': 'Nutella',
          'brands': 'Nutella, Ferrero',
          'nutriscore_grade': 'e',
          'image_url':
              'https://images.openfoodfacts.org/images/products/'
              '301/762/042/2003/front_en.879.400.jpg',
          'nutriments': {
            'energy-kcal_100g': 539,
            'proteins_100g': 6.3,
            'carbohydrates_100g': 57.5,
            'fat_100g': 30.9,
            'salt_100g': 0.107,
          },
        },
      };
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final p = await api.getByBarcode('3017620422003');
      expect(p.name, 'Nutella');
      expect(p.brand, 'Nutella, Ferrero');
      expect(p.nutriscoreGrade, 'e');
      expect(p.energyKcal, 539);
      expect(p.proteinG, 6.3);
      expect(p.carbsG, 57.5);
      expect(p.fatG, 30.9);
      expect(p.saltG, closeTo(0.107, 0.001));
    });

    test('Cristaline — grade A, null nutrition', () async {
      final json = {
        'status': 'success',
        'product': {
          '_id': '3274080005003',
          'product_name': 'isabelle',
          'brands': 'Cristaline',
          'nutriscore_grade': 'a',
          'nutriments': {
            'energy-kcal_100g': null,
            'proteins_100g': null,
            'carbohydrates_100g': null,
            'fat_100g': null,
            'fiber_100g': null,
            'salt_100g': 0.00275,
          },
        },
      };
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final p = await api.getByBarcode('3274080005003');
      expect(p.name, 'isabelle');
      expect(p.nutriscoreGrade, 'a');
      expect(p.energyKcal, null);
      expect(p.proteinG, null);
      expect(p.saltG, closeTo(0.00275, 0.00001));
    });

    test('Gazpacho Alvalle — grade B, serving size', () async {
      final json = {
        'status': 'success',
        'product': {
          '_id': '3168930163480',
          'product_name': "Alvalle Gazpacho l'original",
          'brands': 'Alvalle',
          'nutriscore_grade': 'b',
          'serving_size': '200 ml',
          'nutriments': {
            'energy-kcal_100g': 40,
            'proteins_100g': 0.9,
            'carbohydrates_100g': 3.5,
            'fat_100g': 2.2,
            'fiber_100g': 1.2,
            'salt_100g': 0.61,
          },
        },
      };
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final p = await api.getByBarcode('3168930163480');
      expect(p.nutriscoreGrade, 'b');
      expect(p.energyKcal, 40);
      expect(p.fiberG, 1.2);
      expect(p.servingSize, '200 ml');
    });

    test('La Boulangère bread — grade C, fibre', () async {
      final json = {
        'status': 'success',
        'product': {
          '_id': '3760049794298',
          'product_name': 'Pain de mie Bio grandes tranches',
          'brands': 'La Boulangère Bio',
          'nutriscore_grade': 'c',
          'serving_size': '35.7 g',
          'nutriments': {
            'energy-kcal_100g': 303,
            'proteins_100g': 8.6,
            'carbohydrates_100g': 46,
            'fat_100g': 8.3,
            'fiber_100g': 5.1,
            'salt_100g': 1.1,
          },
        },
      };
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final p = await api.getByBarcode('3760049794298');
      expect(p.nutriscoreGrade, 'c');
      expect(p.energyKcal, 303);
      expect(p.fiberG, 5.1);
      expect(p.servingSize, '35.7 g');
    });

    test('Goldium crémeux — grade D', () async {
      final json = {
        'status': 'success',
        'product': {
          '_id': '6111259092495',
          'product_name': 'Goldium crémeux',
          'nutriscore_grade': 'd',
          'nutriments': {
            'energy-kcal_100g': 225,
            'proteins_100g': 5,
            'carbohydrates_100g': 3,
            'fat_100g': 24,
            'fiber_100g': 0.1,
            'salt_100g': 0.32,
          },
        },
      };
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final p = await api.getByBarcode('6111259092495');
      expect(p.nutriscoreGrade, 'd');
      expect(p.fatG, 24);
    });

    test('Lindt 85% — grade E, high protein', () async {
      final json = {
        'status': 'success',
        'product': {
          '_id': '3046920022606',
          'product_name': 'Excellence 85% cacao',
          'brands': 'Lindt',
          'nutriscore_grade': 'e',
          'nutriments': {
            'energy-kcal_100g': 584,
            'proteins_100g': 12.5,
            'carbohydrates_100g': 22,
            'fat_100g': 46,
            'fiber_100g': 0,
            'salt_100g': 0.02,
          },
        },
      };
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final p = await api.getByBarcode('3046920022606');
      expect(p.nutriscoreGrade, 'e');
      expect(p.proteinG, 12.5);
      expect(p.saltG, 0.02);
    });

    test('Wine — grade not-applicable preserved', () async {
      final json = {
        'status': 'success',
        'product': {
          '_id': '5601012011500',
          'product_name': 'Mateus Rosé Original',
          'nutriscore_grade': 'not-applicable',
          'nutriments': <String, dynamic>{},
        },
      };
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final p = await api.getByBarcode('5601012011500');
      expect(p.nutriscoreGrade, 'not-applicable');
      expect(p.name, 'Mateus Rosé Original');
    });

    test('missing product keys handled gracefully', () async {
      final json = {
        'status': 'success',
        'product': {'_id': '9999999999999'},
      };
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final p = await api.getByBarcode('9999999999999');
      expect(p.name, 'Unknown');
      expect(p.brand, null);
      expect(p.nutriscoreGrade, null);
    });
  });
}
