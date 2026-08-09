/// @file OffAdapter unit tests.
///
/// Tests for the Open Food Facts API adapter.  SDK static calls are
/// replaced with injectable function overrides so no real API calls
/// are made.  Covers the public methods: getByBarcode, searchProducts,
/// submitProduct, and uploadProductImage with success, error, retry,
/// and edge-case paths.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/utils/logger.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  group('OffAdapter', () {
    group('useStaging', () {
      test('useStaging=true uses food test URI', () {
        final adapter = OffAdapter(useStaging: true);
        expect(adapter.useStaging, isTrue);
      });

      test('useStaging=false uses production URI', () {
        final adapter = OffAdapter(useStaging: false);
        expect(adapter.useStaging, isFalse);
      });
    });

    group('readUser', () {
      test('is smoothie-app/strawberrybanana', () {
        const user = OffAdapter.readUser;
        expect(user.userId, 'smoothie-app');
        expect(user.password, 'strawberrybanana');
      });
    });

    group('writeUser', () {
      test('returns null when credentials are empty', () {
        final adapter = OffAdapter(useStaging: false);
        expect(adapter.writeUser, isNull);
      });
    });

    group('validateCredentials', () {
      off.LoginStatus loginStatus(int status, {String? userId}) {
        return off.LoginStatus(
          status: status,
          statusVerbose: status == 1 ? 'user signed-in' : 'user not signed-in',
          userId: userId,
          cookie: null,
          userDetails: const off.UserDetails(),
        );
      }

      test('returns none when the login succeeds', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );
        final adapter = OffAdapter(
          useStaging: false,
          onLogin2: (user, {uriHelper = off.uriHelperFoodProd}) async {
            return loginStatus(1, userId: 'testuser');
          },
        );

        expect(await adapter.validateCredentials(), OffWriteError.none);
      });

      test('returns wrongCredentials when the login fails', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'wrong-password',
          },
        );
        final adapter = OffAdapter(
          useStaging: false,
          onLogin2: (user, {uriHelper = off.uriHelperFoodProd}) async {
            return loginStatus(0);
          },
        );

        expect(
          await adapter.validateCredentials(),
          OffWriteError.wrongCredentials,
        );
      });

      test('returns network when login2 returns null', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );
        final adapter = OffAdapter(
          useStaging: false,
          onLogin2: (user, {uriHelper = off.uriHelperFoodProd}) async {
            return null;
          },
        );

        expect(await adapter.validateCredentials(), OffWriteError.network);
      });

      test('returns network when login2 throws', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );
        final adapter = OffAdapter(
          useStaging: false,
          onLogin2: (user, {uriHelper = off.uriHelperFoodProd}) {
            throw Exception('user details missing');
          },
        );

        expect(await adapter.validateCredentials(), OffWriteError.network);
      });

      test('returns missingCredentials without a network call', () async {
        var calls = 0;
        final adapter = OffAdapter(
          useStaging: false,
          onLogin2: (user, {uriHelper = off.uriHelperFoodProd}) async {
            calls++;
            return loginStatus(1);
          },
        );

        expect(
          await adapter.validateCredentials(),
          OffWriteError.missingCredentials,
        );
        expect(calls, 0);
      });
    });

    group('parseImageField', () {
      test('returns FRONT for "front"', () {
        expect(OffAdapter.parseImageField('front'), off.ImageField.FRONT);
      });

      test('returns INGREDIENTS for "ingredients"', () {
        expect(
          OffAdapter.parseImageField('ingredients'),
          off.ImageField.INGREDIENTS,
        );
      });

      test('returns NUTRITION for "nutrition"', () {
        expect(
          OffAdapter.parseImageField('nutrition'),
          off.ImageField.NUTRITION,
        );
      });

      test('returns FRONT for unknown field', () {
        expect(OffAdapter.parseImageField('unknown'), off.ImageField.FRONT);
      });
    });

    group('getByBarcode', () {
      /// Verifies [getByBarcode] returns a [Product] on a successful
      /// API response with a non‑null product.
      test('returns Product on successful fetch', () async {
        final adapter = OffAdapter(
          useStaging: false,
          onGetProductV3:
              (config, {user, uriHelper = off.uriHelperFoodProd}) async {
                return off.ProductResultV3.fromJson({
                  'product': {
                    'code': '001',
                    'product_name': 'Test Milk',
                  },
                  'status_verbose': 'found',
                });
              },
        );

        final product = await adapter.getByBarcode('001');
        expect(product.name, 'Test Milk');
        expect(product.barcode, '001');
      });

      /// Verifies [getByBarcode] throws [ProductNotFoundException]
      /// when the SDK returns a null product.
      test('throws ProductNotFoundException when product is null', () {
        final adapter = OffAdapter(
          useStaging: false,
          onGetProductV3:
              (config, {user, uriHelper = off.uriHelperFoodProd}) async {
                return off.ProductResultV3.fromJson({
                  'status_verbose': 'not found',
                });
              },
        );

        expect(
          () => adapter.getByBarcode('999'),
          throwsA(isA<ProductNotFoundException>()),
        );
      });

      /// Verifies [getByBarcode] throws [FetchFailedException] on
      /// generic SDK errors.
      test('throws FetchFailedException on SDK error', () {
        final adapter = OffAdapter(
          useStaging: false,
          onGetProductV3: (config, {user, uriHelper = off.uriHelperFoodProd}) =>
              Future.error(Exception('Network error')),
        );

        expect(
          () => adapter.getByBarcode('001'),
          throwsA(isA<FetchFailedException>()),
        );
      });

      /// Verifies [getByBarcode] retries on transient failure and
      /// succeeds on the second attempt.
      test('retries on transient failure and succeeds', () async {
        var attempts = 0;
        final adapter = OffAdapter(
          useStaging: false,
          onGetProductV3:
              (config, {user, uriHelper = off.uriHelperFoodProd}) async {
                attempts++;
                if (attempts == 1) {
                  throw Exception('Temporary outage');
                }
                return off.ProductResultV3.fromJson({
                  'product': {'code': '001', 'product_name': 'Test Milk'},
                  'status_verbose': 'found',
                });
              },
        );

        final product = await adapter.getByBarcode('001');
        expect(product.name, 'Test Milk');
        expect(attempts, 2);
      });

      /// Verifies [getByBarcode] throws [FetchFailedException] after
      /// all retries are exhausted.
      test('throws after exhausting all retries', () async {
        var attempts = 0;
        const maxRetries = 2;
        final adapter = OffAdapter(
          useStaging: false,
          onGetProductV3: (config, {user, uriHelper = off.uriHelperFoodProd}) {
            attempts++;
            throw Exception('Persistent failure');
          },
        );

        try {
          await adapter.getByBarcode('001');
          fail('Expected FetchFailedException');
        } on FetchFailedException {
          // Expected path.
        }
        // Total attempts = maxRetries + 1 (initial + retries)
        expect(attempts, maxRetries + 1);
      });

      /// Verifies [getByBarcode] does NOT retry on
      /// [ProductNotFoundException] — unknown barcodes should fail fast.
      test('does not retry on ProductNotFoundException', () {
        var attempts = 0;
        final adapter = OffAdapter(
          useStaging: false,
          onGetProductV3:
              (config, {user, uriHelper = off.uriHelperFoodProd}) async {
                attempts++;
                return off.ProductResultV3.fromJson({
                  'status_verbose': 'not found',
                });
              },
        );

        expect(
          () => adapter.getByBarcode('999'),
          throwsA(isA<ProductNotFoundException>()),
        );
        expect(attempts, 1);
      });
    });

    group('retryDelay', () {
      test('returns base delay for attempt 0 with seed 42', () {
        final random = Random(42);
        final delay = OffAdapter.retryDelay(0, random: random);
        // Base is 1000ms, jitter is ±25% of 1000 = ±250
        expect(delay.inMilliseconds, inInclusiveRange(750, 1250));
      });

      test('returns base delay for attempt 1 with seed 42', () {
        final random = Random(42);
        final delay = OffAdapter.retryDelay(1, random: random);
        // Base is 2000ms, jitter is ±25% of 2000 = ±500
        expect(delay.inMilliseconds, inInclusiveRange(1500, 2500));
      });

      test('returns base delay for attempt 2 with seed 42', () {
        final random = Random(42);
        final delay = OffAdapter.retryDelay(2, random: random);
        // Base is 3000ms, jitter is ±25% of 3000 = ±750
        expect(delay.inMilliseconds, inInclusiveRange(2250, 3750));
      });

      test('same seed produces same delay', () {
        final a = OffAdapter.retryDelay(0, random: Random(123));
        final b = OffAdapter.retryDelay(0, random: Random(123));
        expect(a, b);
      });

      test('different seeds produce different delays', () {
        final a = OffAdapter.retryDelay(0, random: Random(1));
        final b = OffAdapter.retryDelay(0, random: Random(999));
        expect(a, isNot(b));
      });

      test('rate limit multiplies delay by 5', () {
        final random = Random(42);
        final normal = OffAdapter.retryDelay(0, random: random);
        final random2 = Random(42);
        final rateLimited = OffAdapter.retryDelay(
          0,
          random: random2,
          isRateLimit: true,
        );
        expect(
          rateLimited.inMilliseconds,
          greaterThan(normal.inMilliseconds * 4),
        );
      });
    });

    group('isRateLimitError', () {
      test('detects 429 Too Many Requests', () {
        expect(
          OffAdapter.isRateLimitError(
            Exception(
              'JSON expected, html found: '
              '<head><title>429 Too Many Requests</title></head>',
            ),
          ),
          isTrue,
        );
      });

      test('returns false for generic error', () {
        expect(
          OffAdapter.isRateLimitError(Exception('Network error')),
          isFalse,
        );
      });

      test('returns false for 404 error', () {
        expect(
          OffAdapter.isRateLimitError(Exception('404 Not Found')),
          isFalse,
        );
      });

      test('returns false for server error', () {
        expect(
          OffAdapter.isRateLimitError(
            Exception(
              'JSON expected, server error found: '
              'Page temporarily unavailable',
            ),
          ),
          isFalse,
        );
      });
    });

    group('isStatusOk', () {
      test('returns true for status 1', () {
        expect(
          OffAdapter.isStatusOk(off.Status.fromJson({'status': 1})),
          isTrue,
        );
      });

      test('returns true for status "status ok"', () {
        expect(
          OffAdapter.isStatusOk(
            off.Status.fromJson({'status': 'status ok'}),
          ),
          isTrue,
        );
      });

      test('returns false for status 0', () {
        expect(
          OffAdapter.isStatusOk(off.Status.fromJson({'status': 0})),
          isFalse,
        );
      });

      test('returns false for status "status not ok"', () {
        expect(
          OffAdapter.isStatusOk(
            off.Status.fromJson({'status': 'status not ok'}),
          ),
          isFalse,
        );
      });

      test('returns false for status 400', () {
        expect(
          OffAdapter.isStatusOk(off.Status.fromJson({'status': 400})),
          isFalse,
        );
      });
    });

    group('isRateLimitStatus', () {
      test('returns true for status 429', () {
        expect(
          OffAdapter.isRateLimitStatus(off.Status.fromJson({'status': 429})),
          isTrue,
        );
      });

      test('returns true when body contains 429 Too Many Requests', () {
        final status = off.Status(
          status: 400,
          body: '<html><title>429 Too Many Requests</title></html>',
        );
        expect(OffAdapter.isRateLimitStatus(status), isTrue);
      });

      test('returns false for a plain error status', () {
        final status = off.Status(status: 400, body: 'Something went wrong');
        expect(OffAdapter.isRateLimitStatus(status), isFalse);
      });
    });

    group('isWrongCredentials', () {
      test('detects the message in statusVerbose', () {
        final status = off.Status(
          status: 400,
          statusVerbose: 'Incorrect user name or password',
        );
        expect(OffAdapter.isWrongCredentials(status), isTrue);
      });

      test('detects the message in body', () {
        final status = off.Status(
          status: 400,
          body: '<html><title>Incorrect user name or password</title></html>',
        );
        expect(OffAdapter.isWrongCredentials(status), isTrue);
      });

      test('detects the message in error', () {
        final status = off.Status(
          status: 400,
          error: 'Incorrect user name or password',
        );
        expect(OffAdapter.isWrongCredentials(status), isTrue);
      });

      test('returns false for an unrelated message', () {
        final status = off.Status(
          status: 400,
          statusVerbose: 'Missing required field: product_name',
        );
        expect(OffAdapter.isWrongCredentials(status), isFalse);
      });
    });

    group('categorizeSaveStatus', () {
      test('returns wrongCredentials for a wrong-credentials status', () {
        final status = off.Status(
          status: 400,
          statusVerbose: 'Incorrect user name or password',
        );
        expect(
          OffAdapter.categorizeSaveStatus(status),
          OffWriteError.wrongCredentials,
        );
      });

      test('returns wrongCredentials when body carries the message', () {
        final status = off.Status(
          status: 400,
          body: '<html><title>Incorrect user name or password</title></html>',
        );
        expect(
          OffAdapter.categorizeSaveStatus(status),
          OffWriteError.wrongCredentials,
        );
      });

      test('returns validation for a generic 400 status', () {
        final status = off.Status(status: 400, error: 'Bad request');
        expect(
          OffAdapter.categorizeSaveStatus(status),
          OffWriteError.validation,
        );
      });

      test('returns validation when a verbose message is present', () {
        final status = off.Status(
          status: 0,
          statusVerbose: 'Missing required field: product_name',
        );
        expect(
          OffAdapter.categorizeSaveStatus(status),
          OffWriteError.validation,
        );
      });

      test('returns serverRejected for a bare non-ok status', () {
        final status = off.Status(status: 0);
        expect(
          OffAdapter.categorizeSaveStatus(status),
          OffWriteError.serverRejected,
        );
      });
    });

    group('searchProducts', () {
      /// Verifies [searchProducts] returns a list of [Product]s from
      /// the SDK search results.
      test('returns products from search results', () async {
        final adapter = OffAdapter(
          useStaging: false,
          onSearchProducts:
              (user, config, {uriHelper = off.uriHelperFoodProd}) async {
                return off.SearchResult.fromJson({
                  'products': [
                    {'code': '001', 'product_name': 'Milk'},
                    {'code': '002', 'product_name': 'Bread'},
                  ],
                });
              },
        );

        final results = await adapter.searchProducts('milk');
        expect(results.length, 2);
        expect(results[0].barcode, '001');
        expect(results[1].barcode, '002');
      });

      /// Verifies [searchProducts] returns an empty list when the
      /// SDK returns null products.
      test('returns empty list when products is null', () async {
        final adapter = OffAdapter(
          useStaging: false,
          onSearchProducts:
              (user, config, {uriHelper = off.uriHelperFoodProd}) async {
                return off.SearchResult.fromJson({});
              },
        );

        final results = await adapter.searchProducts('empty');
        expect(results, isEmpty);
      });

      /// Verifies [searchProducts] returns an empty list after all
      /// retries are exhausted.
      test('returns empty list after retries exhausted', () async {
        final adapter = OffAdapter(
          useStaging: false,
          onSearchProducts:
              (user, config, {uriHelper = off.uriHelperFoodProd}) =>
                  Future.error(Exception('Timeout')),
        );

        final results = await adapter.searchProducts('fail');
        expect(results, isEmpty);
      });

      /// Verifies [searchProducts] deduplicates results by barcode.
      test('deduplicates by barcode', () async {
        final adapter = OffAdapter(
          useStaging: false,
          onSearchProducts:
              (user, config, {uriHelper = off.uriHelperFoodProd}) async {
                return off.SearchResult.fromJson({
                  'products': [
                    {'code': '001', 'product_name': 'Milk'},
                    {'code': '001', 'product_name': 'Milk duplicate'},
                  ],
                });
              },
        );

        final results = await adapter.searchProducts('milk');
        expect(results.length, 1);
      });

      /// Verifies [searchProducts] filters out products with empty
      /// barcodes.
      test('filters empty barcodes', () async {
        final adapter = OffAdapter(
          useStaging: false,
          onSearchProducts:
              (user, config, {uriHelper = off.uriHelperFoodProd}) async {
                return off.SearchResult.fromJson({
                  'products': [
                    {'code': '001', 'product_name': 'Valid'},
                    {'code': '', 'product_name': 'No Barcode'},
                  ],
                });
              },
        );

        final results = await adapter.searchProducts('test');
        expect(results.length, 1);
      });
    });

    group('OffWriteResult', () {
      test('success has error none', () {
        const result = OffWriteResult.success();
        expect(result.success, isTrue);
        expect(result.error, OffWriteError.none);
      });

      test('failure carries the given error', () {
        const result = OffWriteResult.failure(OffWriteError.network);
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.network);
      });
    });

    group('submitProduct', () {
      /// Verifies [submitProduct] reports [OffWriteError.missingCredentials]
      /// when no OFF credentials are configured.
      test('reports missingCredentials when no credentials', () async {
        final adapter = OffAdapter(useStaging: false);

        const product = Product(barcode: '001', name: 'Test');
        final result = await adapter.submitProduct(product);
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.missingCredentials);
      });

      /// Verifies [submitProduct] succeeds on a successful save
      /// (status code 1).
      test('returns success on successful save', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct:
              (user, product, {uriHelper = off.uriHelperFoodProd}) async {
                return off.Status.fromJson({'status': 1});
              },
        );

        const product = Product(barcode: '001', name: 'Test');
        final result = await adapter.submitProduct(product);
        expect(result.success, isTrue);
        expect(result.error, OffWriteError.none);
      });

      /// Verifies [submitProduct] reports [OffWriteError.network] when the
      /// SDK throws after all retries are exhausted.
      test('reports network on SDK error', () {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct: (user, product, {uriHelper = off.uriHelperFoodProd}) =>
              Future.error(Exception('Save failed')),
        );

        fakeAsync((async) {
          const product = Product(barcode: '001', name: 'Test');
          OffWriteResult? result;
          unawaited(
            adapter.submitProduct(product).then((value) => result = value),
          );
          async.elapse(const Duration(seconds: 30));
          expect(result, isNotNull);
          expect(result!.success, isFalse);
          expect(result!.error, OffWriteError.network);
        });
      });

      /// Verifies that credentials embedded in an SDK exception never reach
      /// the logs, even after all retries are exhausted.
      test(
        'keeps credentials out of logs when an SDK exception leaks them',
        () {
          const leakedPassword = 'REDACTME_PASSWORD_XYZ';
          dotenv.loadFromString(
            isOptional: true,
            mergeWith: {
              'OFF_USER_ID': 'testuser',
              'OFF_PASSWORD': leakedPassword,
            },
          );

          final adapter = OffAdapter(
            useStaging: false,
            onSaveProduct:
                (user, product, {uriHelper = off.uriHelperFoodProd}) =>
                    Future.error(
                      Exception('Bad gateway, form echoed: $leakedPassword'),
                    ),
          );

          fakeAsync((async) {
            const product = Product(barcode: '001', name: 'Test');
            unawaited(adapter.submitProduct(product));
            async.elapse(const Duration(seconds: 30));
            expect(recentLogs, isNot(contains(leakedPassword)));
          });
        },
      );

      /// Verifies [submitProduct] reports [OffWriteError.validation] when
      /// the server returns an HTTP 400 status.
      test('reports validation on HTTP 400 status', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct:
              (user, product, {uriHelper = off.uriHelperFoodProd}) async {
                return off.Status.fromJson({
                  'status': 400,
                  'error': 'Bad request',
                });
              },
        );

        const product = Product(barcode: '001', name: 'Test');
        final result = await adapter.submitProduct(product);
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.validation);
      });

      /// Verifies [submitProduct] reports
      /// [OffWriteError.wrongCredentials] when the server rejects the
      /// credentials, and does NOT retry.
      test('reports wrongCredentials and does not retry', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        var attempts = 0;
        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct:
              (user, product, {uriHelper = off.uriHelperFoodProd}) async {
                attempts++;
                return off.Status(
                  status: 400,
                  statusVerbose: 'Incorrect user name or password',
                );
              },
        );

        const product = Product(barcode: '001', name: 'Test');
        final result = await adapter.submitProduct(product);
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.wrongCredentials);
        expect(attempts, 1);
      });

      /// Verifies [submitProduct] reports
      /// [OffWriteError.wrongCredentials] when the SDK exception carries the
      /// wrong-credentials marker after all retries are exhausted.
      test(
        'reports wrongCredentials when the SDK exception carries the marker',
        () {
          dotenv.loadFromString(
            isOptional: true,
            mergeWith: {
              'OFF_USER_ID': 'testuser',
              'OFF_PASSWORD': 'secret',
            },
          );

          final adapter = OffAdapter(
            useStaging: false,
            onSaveProduct:
                (user, product, {uriHelper = off.uriHelperFoodProd}) =>
                    Future.error(
                      Exception('invalid_user_id_and_password'),
                    ),
          );

          fakeAsync((async) {
            const product = Product(barcode: '001', name: 'Test');
            OffWriteResult? result;
            unawaited(
              adapter.submitProduct(product).then((value) => result = value),
            );
            async.elapse(const Duration(seconds: 30));
            expect(result, isNotNull);
            expect(result!.success, isFalse);
            expect(result!.error, OffWriteError.wrongCredentials);
          });
        },
      );

      /// Verifies [submitProduct] reports [OffWriteError.validation] when
      /// the server responds with a non-zero status carrying a verbose
      /// error message.
      test('reports validation when status has a verbose message', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct:
              (user, product, {uriHelper = off.uriHelperFoodProd}) async {
                return off.Status(
                  status: 0,
                  statusVerbose: 'Missing required field: product_name',
                );
              },
        );

        const product = Product(barcode: '001', name: 'Test');
        final result = await adapter.submitProduct(product);
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.validation);
      });

      /// Verifies [submitProduct] reports [OffWriteError.serverRejected]
      /// when the server returns a non‑success status.
      test('reports serverRejected on non-ok status', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct:
              (user, product, {uriHelper = off.uriHelperFoodProd}) async {
                return off.Status.fromJson({'status': 0});
              },
        );

        const product = Product(barcode: '001', name: 'Test');
        final result = await adapter.submitProduct(product);
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.serverRejected);
      });

      /// Verifies [submitProduct] treats the string form "status ok"
      /// (returned by the image upload endpoint contract) as success.
      test('returns success when status is "status ok"', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct:
              (user, product, {uriHelper = off.uriHelperFoodProd}) async {
                return off.Status.fromJson({'status': 'status ok'});
              },
        );

        const product = Product(barcode: '001', name: 'Test');
        final result = await adapter.submitProduct(product);
        expect(result.success, isTrue);
        expect(result.error, OffWriteError.none);
      });

      /// Verifies [submitProduct] retries when the server responds with a
      /// 429 rate-limit [off.Status] instead of throwing.
      test('retries on rate limit status and succeeds', () {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        var attempts = 0;
        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct: (user, product, {uriHelper = off.uriHelperFoodProd}) {
            attempts++;
            if (attempts == 1) {
              return Future.value(
                off.Status(
                  status: 429,
                  statusVerbose: '429 Too Many Requests',
                ),
              );
            }
            return Future.value(off.Status.fromJson({'status': 1}));
          },
        );

        fakeAsync((async) {
          const product = Product(barcode: '001', name: 'Test');
          OffWriteResult? result;
          unawaited(
            adapter.submitProduct(product).then((value) => result = value),
          );
          async.elapse(const Duration(seconds: 30));
          expect(result, isNotNull);
          expect(result!.success, isTrue);
          expect(attempts, 2);
        });
      });

      /// Verifies [submitProduct] reports [OffWriteError.rateLimited] when
      /// a rate limit never clears.
      test('reports rateLimited when rate limit never clears', () {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        var attempts = 0;
        final adapter = OffAdapter(
          useStaging: false,
          onSaveProduct: (user, product, {uriHelper = off.uriHelperFoodProd}) {
            attempts++;
            return Future.value(
              off.Status(
                status: 429,
                statusVerbose: '429 Too Many Requests',
              ),
            );
          },
        );

        fakeAsync((async) {
          const product = Product(barcode: '001', name: 'Test');
          OffWriteResult? result;
          unawaited(
            adapter.submitProduct(product).then((value) => result = value),
          );
          async.elapse(const Duration(seconds: 60));
          expect(result, isNotNull);
          expect(result!.success, isFalse);
          expect(result!.error, OffWriteError.rateLimited);
          expect(attempts, 3);
        });
      });
    });

    group('uploadProductImage', () {
      /// Verifies [uploadProductImage] reports
      /// [OffWriteError.missingCredentials] when no OFF credentials are
      /// configured.
      test('reports missingCredentials when no credentials', () async {
        final adapter = OffAdapter(useStaging: false);

        final result = await adapter.uploadProductImage(
          barcode: '001',
          imageField: 'front',
          imagePath: '/tmp/test.png',
        );
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.missingCredentials);
      });

      /// Verifies [uploadProductImage] reports [OffWriteError.unknown] when
      /// the local image file does not exist.
      test('reports unknown when file not found', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final adapter = OffAdapter(useStaging: false);
        final result = await adapter.uploadProductImage(
          barcode: '001',
          imageField: 'front',
          imagePath: '/nonexistent/missing.png',
        );
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.unknown);
      });

      /// Verifies [uploadProductImage] treats the image endpoint's string
      /// form "status ok" as success for an existing local image file.
      test('returns success when status is "status ok"', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final tempDir = Directory.systemTemp.createTempSync('pantry_off_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final imagePath = '${tempDir.path}/front.png';
        File(imagePath).writeAsBytesSync([1, 2, 3]);

        final adapter = OffAdapter(
          useStaging: false,
          onAddProductImage:
              (user, image, {uriHelper = off.uriHelperFoodProd}) async {
                return off.Status.fromJson({
                  'status': 'status ok',
                  'imgid': 42,
                });
              },
        );

        final result = await adapter.uploadProductImage(
          barcode: '001',
          imageField: 'front',
          imagePath: imagePath,
        );
        expect(result.success, isTrue);
        expect(result.error, OffWriteError.none);
      });

      /// Verifies [uploadProductImage] treats a "status not ok" response
      /// that carries an image id as success: the server already holds the
      /// identical image, so re-uploading it is a no-op rather than a
      /// failure.
      test(
        'treats "status not ok" with imgid as already-uploaded success',
        () async {
          dotenv.loadFromString(
            isOptional: true,
            mergeWith: {
              'OFF_USER_ID': 'testuser',
              'OFF_PASSWORD': 'secret',
            },
          );

          final tempDir = Directory.systemTemp.createTempSync('pantry_off_');
          addTearDown(() => tempDir.deleteSync(recursive: true));
          final imagePath = '${tempDir.path}/front.png';
          File(imagePath).writeAsBytesSync([1, 2, 3]);

          final adapter = OffAdapter(
            useStaging: false,
            onAddProductImage:
                (user, image, {uriHelper = off.uriHelperFoodProd}) async {
                  return off.Status.fromJson({
                    'status': 'status not ok',
                    'imgid': 99,
                    'status_verbose': 'The image was already uploaded',
                  });
                },
          );

          final result = await adapter.uploadProductImage(
            barcode: '001',
            imageField: 'front',
            imagePath: imagePath,
          );
          expect(result.success, isTrue);
          expect(result.error, OffWriteError.none);
        },
      );

      /// Verifies [uploadProductImage] reports [OffWriteError.serverRejected]
      /// when the server returns a non‑success status.
      test('reports serverRejected on non-ok status', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final tempDir = Directory.systemTemp.createTempSync('pantry_off_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final imagePath = '${tempDir.path}/front.png';
        File(imagePath).writeAsBytesSync([1, 2, 3]);

        final adapter = OffAdapter(
          useStaging: false,
          onAddProductImage:
              (user, image, {uriHelper = off.uriHelperFoodProd}) async {
                return off.Status.fromJson({'status': 'status not ok'});
              },
        );

        final result = await adapter.uploadProductImage(
          barcode: '001',
          imageField: 'front',
          imagePath: imagePath,
        );
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.serverRejected);
      });

      /// Verifies [uploadProductImage] reports
      /// [OffWriteError.wrongCredentials] when the server rejects the
      /// credentials (it shares the same configured user).
      test('reports wrongCredentials on wrong-credentials status', () async {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final tempDir = Directory.systemTemp.createTempSync('pantry_off_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final imagePath = '${tempDir.path}/front.png';
        File(imagePath).writeAsBytesSync([1, 2, 3]);

        final adapter = OffAdapter(
          useStaging: false,
          onAddProductImage:
              (user, image, {uriHelper = off.uriHelperFoodProd}) async {
                return off.Status(
                  status: 400,
                  statusVerbose: 'Incorrect user name or password',
                );
              },
        );

        final result = await adapter.uploadProductImage(
          barcode: '001',
          imageField: 'front',
          imagePath: imagePath,
        );
        expect(result.success, isFalse);
        expect(result.error, OffWriteError.wrongCredentials);
      });

      /// Verifies [uploadProductImage] reports [OffWriteError.network] when
      /// the SDK throws after all retries are exhausted.
      test('reports network on exception after retries', () {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final tempDir = Directory.systemTemp.createTempSync('pantry_off_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final imagePath = '${tempDir.path}/front.png';
        File(imagePath).writeAsBytesSync([1, 2, 3]);

        final adapter = OffAdapter(
          useStaging: false,
          onAddProductImage:
              (user, image, {uriHelper = off.uriHelperFoodProd}) =>
                  Future.error(Exception('Upload failed')),
        );

        fakeAsync((async) {
          OffWriteResult? result;
          unawaited(
            adapter
                .uploadProductImage(
                  barcode: '001',
                  imageField: 'front',
                  imagePath: imagePath,
                )
                .then((value) => result = value),
          );
          async.elapse(const Duration(seconds: 30));
          expect(result, isNotNull);
          expect(result!.success, isFalse);
          expect(result!.error, OffWriteError.network);
        });
      });

      /// Verifies [uploadProductImage] reports [OffWriteError.rateLimited]
      /// when a rate limit never clears.
      test('reports rateLimited when rate limit never clears', () {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final tempDir = Directory.systemTemp.createTempSync('pantry_off_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final imagePath = '${tempDir.path}/front.png';
        File(imagePath).writeAsBytesSync([1, 2, 3]);

        var attempts = 0;
        final adapter = OffAdapter(
          useStaging: false,
          onAddProductImage:
              (user, image, {uriHelper = off.uriHelperFoodProd}) {
                attempts++;
                return Future.value(
                  off.Status(
                    status: 429,
                    statusVerbose: '429 Too Many Requests',
                  ),
                );
              },
        );

        fakeAsync((async) {
          OffWriteResult? result;
          unawaited(
            adapter
                .uploadProductImage(
                  barcode: '001',
                  imageField: 'front',
                  imagePath: imagePath,
                )
                .then((value) => result = value),
          );
          async.elapse(const Duration(seconds: 60));
          expect(result, isNotNull);
          expect(result!.success, isFalse);
          expect(result!.error, OffWriteError.rateLimited);
          expect(attempts, 3);
        });
      });

      /// Verifies [uploadProductImage] reports [OffWriteError.network] when
      /// a single upload hangs longer than the per-upload timeout, without
      /// blocking forever.
      test('times out a hung upload after the per-upload timeout', () {
        dotenv.loadFromString(
          isOptional: true,
          mergeWith: {
            'OFF_USER_ID': 'testuser',
            'OFF_PASSWORD': 'secret',
          },
        );

        final tempDir = Directory.systemTemp.createTempSync('pantry_off_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final imagePath = '${tempDir.path}/front.png';
        File(imagePath).writeAsBytesSync([1, 2, 3]);

        var attempts = 0;
        final adapter = OffAdapter(
          useStaging: false,
          onAddProductImage:
              (user, image, {uriHelper = off.uriHelperFoodProd}) {
                attempts++;
                return Completer<off.Status>().future;
              },
        );

        fakeAsync((async) {
          OffWriteResult? result;
          unawaited(
            adapter
                .uploadProductImage(
                  barcode: '001',
                  imageField: 'front',
                  imagePath: imagePath,
                )
                .then((value) => result = value),
          );
          async.elapse(const Duration(seconds: 300));
          expect(result, isNotNull);
          expect(result!.success, isFalse);
          expect(result!.error, OffWriteError.network);
          expect(attempts, 3);
        });
      });
    });
  });
}
