import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/product_submission_queue_dao.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/product_image_compressor.dart';
import 'package:pantry_app/services/product_submission_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOffAdapter extends Mock implements OffAdapter {}

class MockProductImageCompressor extends Mock
    implements ProductImageCompressor {}

class FakeDatabase extends Fake implements Database {}

const testProduct = Product(
  barcode: '123456789',
  name: 'Test Product',
  source: 'manual',
);

void main() {
  late MockDatabaseHelper mockDb;
  late MockOffAdapter mockApi;
  late MockProductImageCompressor mockCompressor;
  late ProductSubmissionService service;
  late Database db;

  /// Stubs the duplicate pre-check so the barcode is unknown to OFF.
  void stubNoDuplicate() {
    when(
      () => mockApi.getByBarcode(
        any(),
        languageCode: any(named: 'languageCode'),
        maxRetries: any(named: 'maxRetries'),
      ),
    ).thenThrow(ProductNotFoundException('not found'));
  }

  void stubInsert() {
    when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
  }

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dotenv.loadFromString(isOptional: true, mergeWith: {});
    registerFallbackValue(FakeDatabase());
    registerFallbackValue('');
    registerFallbackValue(const Product(barcode: '', name: ''));
  });

  setUp(() async {
    mockDb = MockDatabaseHelper();
    mockApi = MockOffAdapter();
    mockCompressor = MockProductImageCompressor();
    service = ProductSubmissionService(
      db: mockDb,
      api: mockApi,
      imageCompressor: mockCompressor,
    );

    // Create a real in-memory database for queue DAO operations.
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await ProductSubmissionQueueDao().createTable(db);

    // Stub the database getter so _queueForRetry uses the real DB.
    when(() => mockDb.database).thenAnswer((_) async => db);

    // Stub the productSubmissionQueueDao getter.
    when(
      () => mockDb.productSubmissionQueueDao,
    ).thenReturn(ProductSubmissionQueueDao());

    // A fresh product defaults to "not a duplicate" unless a test overrides
    // the getByBarcode stub.
    stubNoDuplicate();

    // Credential validation defaults to "passes" unless a test overrides it.
    when(
      () => mockApi.validateCredentials(),
    ).thenAnswer((_) async => OffWriteError.none);

    // Compression defaults to "no compression needed" (original path used)
    // unless a test stubs specific source paths.
    when(
      () => mockCompressor.compress(sourcePath: any(named: 'sourcePath')),
    ).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await db.close();
  });

  /// Creates a product with three local image files on disk.
  Product productWithAllImages() {
    final tempDir = Directory.systemTemp.createTempSync('pantry_sub_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final front = '${tempDir.path}/front.jpg';
    final ingredients = '${tempDir.path}/ingredients.jpg';
    final nutrition = '${tempDir.path}/nutrition.jpg';
    File(front).writeAsBytesSync([1]);
    File(ingredients).writeAsBytesSync([2]);
    File(nutrition).writeAsBytesSync([3]);
    return testProduct.copyWith(
      productImagePath: front,
      ingredientsImagePath: ingredients,
      nutritionImagePath: nutrition,
    );
  }

  group('submitProduct', () {
    test('sets status to pending before submission', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      await service.submitProduct(testProduct);

      verify(
        () => mockDb.insertProduct(
          testProduct.copyWith(submissionStatus: productSubmissionPending),
        ),
      ).called(1);
    });

    test('returns submitted when metadata succeeds (no images)', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      final result = await service.submitProduct(testProduct);
      expect(result.submissionStatus, productSubmissionSubmitted);
    });

    test('returns failed when metadata submission is rejected', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer(
        (_) async => const OffWriteResult.failure(
          OffWriteError.serverRejected,
        ),
      );

      final result = await service.submitProduct(testProduct);
      expect(result.submissionStatus, productSubmissionFailed);
    });

    test('returns failed when metadata throws exception', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenThrow(Exception('Network error'));

      final result = await service.submitProduct(testProduct);
      expect(result.submissionStatus, productSubmissionFailed);
    });

    test('inserts final status to database on success', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      await service.submitProduct(testProduct);

      verify(
        () => mockDb.insertProduct(
          any(
            that: predicate<Product>(
              (p) => p.submissionStatus == productSubmissionSubmitted,
            ),
          ),
        ),
      ).called(1);
    });

    test('inserts final status to database on failure', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenThrow(Exception('Network error'));

      await service.submitProduct(testProduct);

      verify(
        () => mockDb.insertProduct(
          any(
            that: predicate<Product>(
              (p) => p.submissionStatus == productSubmissionFailed,
            ),
          ),
        ),
      ).called(1);
    });

    test('emits checking progress before any network call', () async {
      final events = <SubmissionProgress>[];
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      await service.submitProduct(testProduct, onProgress: events.add);

      expect(events.first.step, SubmissionStep.checking);
      expect(events.first.barcode, testProduct.barcode);
      expect(events.first.totalImageCount, 0);
    });

    test('emits submittingMetadata before the metadata call', () async {
      final events = <SubmissionProgress>[];
      SubmissionStep? stepWhenMetadataCalled;
      stubInsert();
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async {
        stepWhenMetadataCalled = events.last.step;
        return const OffWriteResult.success();
      });

      await service.submitProduct(testProduct, onProgress: events.add);

      expect(stepWhenMetadataCalled, SubmissionStep.submittingMetadata);
    });

    test('emits uploading steps in order with image counts', () async {
      final product = productWithAllImages();
      final events = <SubmissionProgress>[];
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => const OffWriteResult.success());

      await service.submitProduct(product, onProgress: events.add);

      final uploadSteps = events
          .where((e) => !e.isTerminal)
          .where(
            (e) => switch (e.step) {
              SubmissionStep.checking ||
              SubmissionStep.submittingMetadata => false,
              _ => true,
            },
          )
          .toList();
      expect(
        uploadSteps.map((e) => e.step),
        [
          SubmissionStep.uploadingFront,
          SubmissionStep.uploadingIngredients,
          SubmissionStep.uploadingNutrition,
        ],
      );
      expect(uploadSteps[0].completedImageCount, 0);
      expect(uploadSteps[0].totalImageCount, 3);
      expect(uploadSteps[1].completedImageCount, 1);
      expect(uploadSteps[2].completedImageCount, 2);
      expect(events.last.step, SubmissionStep.completed);
      expect(events.last.completedImageCount, 3);
    });

    test('skips upload steps when no images are present', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      final events = <SubmissionProgress>[];
      await service.submitProduct(testProduct, onProgress: events.add);

      expect(
        events.where((e) => e.step.toString().contains('uploading')),
        isEmpty,
      );
      expect(events.last.step, SubmissionStep.completed);
    });

    test(
      'reports failed with serverRejected and no retry for rejection',
      () async {
        stubInsert();
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer(
          (_) async => const OffWriteResult.failure(
            OffWriteError.serverRejected,
          ),
        );

        final events = <SubmissionProgress>[];
        await service.submitProduct(testProduct, onProgress: events.add);

        final terminal = events.last;
        expect(terminal.step, SubmissionStep.failed);
        expect(
          terminal.errorCategory,
          SubmissionErrorCategory.serverRejected,
        );
        expect(terminal.retryAvailable, isFalse);
        verifyNever(
          () => mockDb.productSubmissionQueueDao.insert(any(), any()),
        );
      },
    );

    test('reports failed with network and retry on exception', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenThrow(Exception('Network error'));

      final events = <SubmissionProgress>[];
      await service.submitProduct(testProduct, onProgress: events.add);

      final terminal = events.last;
      expect(terminal.step, SubmissionStep.failed);
      expect(terminal.errorCategory, SubmissionErrorCategory.network);
      expect(terminal.retryAvailable, isTrue);
    });

    test('reports failed with missingCredentials and no retry', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer(
        (_) async => const OffWriteResult.failure(
          OffWriteError.missingCredentials,
        ),
      );

      final events = <SubmissionProgress>[];
      await service.submitProduct(testProduct, onProgress: events.add);

      expect(events.last.step, SubmissionStep.failed);
      expect(
        events.last.errorCategory,
        SubmissionErrorCategory.missingCredentials,
      );
      expect(events.last.retryAvailable, isFalse);
    });

    test('maps validation failure to validation with no retry', () async {
      stubInsert();
      when(
        () => mockApi.getByBarcode(
          any(),
          languageCode: any(named: 'languageCode'),
          maxRetries: any(named: 'maxRetries'),
        ),
      ).thenThrow(ProductNotFoundException(testProduct.barcode));
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer(
        (_) async => const OffWriteResult.failure(OffWriteError.validation),
      );

      final events = <SubmissionProgress>[];
      final result = await service.submitProduct(
        testProduct,
        onProgress: events.add,
      );

      expect(result.submissionStatus, productSubmissionFailed);
      expect(events.last.errorCategory, SubmissionErrorCategory.validation);
      expect(events.last.retryAvailable, isFalse);
      verifyNever(
        () => mockDb.productSubmissionQueueDao.insert(any(), any()),
      );
    });

    test('maps wrongCredentials failure with no retry and no queue', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer(
        (_) async => const OffWriteResult.failure(
          OffWriteError.wrongCredentials,
        ),
      );

      final events = <SubmissionProgress>[];
      final result = await service.submitProduct(
        testProduct,
        onProgress: events.add,
      );

      expect(result.submissionStatus, productSubmissionFailed);
      expect(events.last.step, SubmissionStep.failed);
      expect(
        events.last.errorCategory,
        SubmissionErrorCategory.wrongCredentials,
      );
      expect(events.last.retryAvailable, isFalse);
      verifyNever(
        () => mockDb.productSubmissionQueueDao.insert(any(), any()),
      );
    });
  });

  group('credential pre-flight', () {
    test('fails fast with wrongCredentials before submitting', () async {
      stubInsert();
      when(
        () => mockApi.validateCredentials(),
      ).thenAnswer((_) async => OffWriteError.wrongCredentials);

      final events = <SubmissionProgress>[];
      final result = await service.submitProduct(
        testProduct,
        onProgress: events.add,
      );

      expect(result.submissionStatus, productSubmissionFailed);
      expect(events.last.step, SubmissionStep.failed);
      expect(
        events.last.errorCategory,
        SubmissionErrorCategory.wrongCredentials,
      );
      expect(events.last.retryAvailable, isFalse);
      verifyNever(() => mockApi.submitProduct(any()));
      verifyNever(
        () => mockDb.productSubmissionQueueDao.insert(any(), any()),
      );
    });

    test(
      'proceeds when credential validation is inconclusive (network)',
      () async {
        stubInsert();
        when(
          () => mockApi.validateCredentials(),
        ).thenAnswer((_) async => OffWriteError.network);
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer((_) async => const OffWriteResult.success());

        final result = await service.submitProduct(testProduct);
        expect(result.submissionStatus, productSubmissionSubmitted);
        verify(() => mockApi.submitProduct(any())).called(1);
      },
    );

    test('proceeds when credential validation passes', () async {
      stubInsert();
      when(
        () => mockApi.validateCredentials(),
      ).thenAnswer((_) async => OffWriteError.none);
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      final result = await service.submitProduct(testProduct);
      expect(result.submissionStatus, productSubmissionSubmitted);
      verify(() => mockApi.submitProduct(any())).called(1);
    });
  });

  group('duplicate pre-check', () {
    test(
      'fails with duplicate when the barcode already exists on OFF',
      () async {
        stubInsert();
        when(
          () => mockApi.getByBarcode(
            testProduct.barcode,
            languageCode: any(named: 'languageCode'),
            maxRetries: 0,
          ),
        ).thenAnswer((_) async => testProduct);

        final events = <SubmissionProgress>[];
        final result = await service.submitProduct(
          testProduct,
          onProgress: events.add,
        );

        expect(result.submissionStatus, productSubmissionFailed);
        expect(events.last.step, SubmissionStep.failed);
        expect(events.last.errorCategory, SubmissionErrorCategory.duplicate);
        expect(events.last.retryAvailable, isFalse);
        verifyNever(() => mockApi.submitProduct(any()));
        verifyNever(
          () => mockDb.productSubmissionQueueDao.insert(any(), any()),
        );
      },
    );

    test('proceeds when the barcode is unknown to OFF', () async {
      stubInsert();
      when(
        () => mockApi.getByBarcode(
          testProduct.barcode,
          languageCode: any(named: 'languageCode'),
          maxRetries: 0,
        ),
      ).thenThrow(ProductNotFoundException(testProduct.barcode));
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      final result = await service.submitProduct(testProduct);
      expect(result.submissionStatus, productSubmissionSubmitted);
    });

    test(
      'proceeds when the duplicate check cannot run (network error)',
      () async {
        stubInsert();
        when(
          () => mockApi.getByBarcode(
            testProduct.barcode,
            languageCode: any(named: 'languageCode'),
            maxRetries: 0,
          ),
        ).thenThrow(FetchFailedException('offline'));
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer((_) async => const OffWriteResult.success());

        final result = await service.submitProduct(testProduct);
        expect(result.submissionStatus, productSubmissionSubmitted);
      },
    );

    test('skips the duplicate check when retrying a failed product', () async {
      final retryProduct = testProduct.copyWith(
        submissionStatus: productSubmissionFailed,
      );
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      final result = await service.submitProduct(retryProduct);
      expect(result.submissionStatus, productSubmissionSubmitted);
      // Metadata submission was reached: the duplicate gate did not block
      // the retry even though the server state is fetched for images.
      verify(() => mockApi.submitProduct(any())).called(1);
    });
  });

  group('submitProduct image handling', () {
    test('forwards the product languageCode to image uploads', () async {
      final product = productWithAllImages().copyWith(languageCode: 'pt');
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => const OffWriteResult.success());

      await service.submitProduct(product);

      verify(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
          languageCode: 'pt',
        ),
      ).called(3);
    });

    test('partial success persists partially_completed status', () async {
      final product = productWithAllImages();
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (invocation) async {
          final field = invocation.namedArguments[#imageField] as String;
          if (field == 'nutrition') {
            return const OffWriteResult.failure(OffWriteError.network);
          }
          return const OffWriteResult.success();
        },
      );

      final events = <SubmissionProgress>[];
      final result = await service.submitProduct(
        product,
        onProgress: events.add,
      );

      expect(result.submissionStatus, productSubmissionPartiallyCompleted);
      final terminal = events.last;
      expect(terminal.step, SubmissionStep.partiallyCompleted);
      expect(terminal.completedImageCount, 2);
      expect(terminal.totalImageCount, 3);
      expect(terminal.retryAvailable, isTrue);
      verify(
        () => mockDb.insertProduct(
          any(
            that: predicate<Product>(
              (p) => p.submissionStatus == productSubmissionPartiallyCompleted,
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'all images failing reports failed with retry for transient',
      () async {
        final product = productWithAllImages();
        stubInsert();
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer((_) async => const OffWriteResult.success());
        when(
          () => mockApi.uploadProductImage(
            barcode: any(named: 'barcode'),
            imageField: any(named: 'imageField'),
            imagePath: any(named: 'imagePath'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer(
          (_) async => const OffWriteResult.failure(OffWriteError.rateLimited),
        );

        final events = <SubmissionProgress>[];
        final result = await service.submitProduct(
          product,
          onProgress: events.add,
        );

        expect(result.submissionStatus, productSubmissionFailed);
        expect(events.last.step, SubmissionStep.failed);
        expect(
          events.last.errorCategory,
          SubmissionErrorCategory.rateLimited,
        );
        expect(events.last.retryAvailable, isTrue);
      },
    );

    test('metadata-only submission completes without upload calls', () async {
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      final events = <SubmissionProgress>[];
      final result = await service.submitProduct(
        testProduct,
        onProgress: events.add,
      );

      expect(result.submissionStatus, productSubmissionSubmitted);
      expect(events.last.step, SubmissionStep.completed);
      verifyNever(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
        ),
      );
    });

    test('continues uploading remaining images when the first fails', () async {
      final product = productWithAllImages();
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (invocation) async {
          final field = invocation.namedArguments[#imageField] as String;
          if (field == 'front') {
            return const OffWriteResult.failure(OffWriteError.network);
          }
          return const OffWriteResult.success();
        },
      );

      final events = <SubmissionProgress>[];
      final result = await service.submitProduct(
        product,
        onProgress: events.add,
      );

      expect(result.submissionStatus, productSubmissionPartiallyCompleted);
      expect(events.last.completedImageCount, 2);
      verify(
        () => mockApi.uploadProductImage(
          barcode: product.barcode,
          imageField: 'front',
          imagePath: product.productImagePath!,
          languageCode: 'en',
        ),
      ).called(1);
      verify(
        () => mockApi.uploadProductImage(
          barcode: product.barcode,
          imageField: 'ingredients',
          imagePath: product.ingredientsImagePath!,
          languageCode: 'en',
        ),
      ).called(1);
      verify(
        () => mockApi.uploadProductImage(
          barcode: product.barcode,
          imageField: 'nutrition',
          imagePath: product.nutritionImagePath!,
          languageCode: 'en',
        ),
      ).called(1);
    });

    test(
      'continues uploading remaining images when a middle one fails',
      () async {
        final product = productWithAllImages();
        stubInsert();
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer((_) async => const OffWriteResult.success());
        when(
          () => mockApi.uploadProductImage(
            barcode: any(named: 'barcode'),
            imageField: any(named: 'imageField'),
            imagePath: any(named: 'imagePath'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer(
          (invocation) async {
            final field = invocation.namedArguments[#imageField] as String;
            if (field == 'ingredients') {
              return const OffWriteResult.failure(OffWriteError.network);
            }
            return const OffWriteResult.success();
          },
        );

        final events = <SubmissionProgress>[];
        final result = await service.submitProduct(
          product,
          onProgress: events.add,
        );

        expect(result.submissionStatus, productSubmissionPartiallyCompleted);
        expect(events.last.completedImageCount, 2);
        verify(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'nutrition',
            imagePath: product.nutritionImagePath!,
            languageCode: 'en',
          ),
        ).called(1);
      },
    );

    test(
      'retry skips images the server already has and uploads only missing ones',
      () async {
        final product = productWithAllImages().copyWith(
          submissionStatus: productSubmissionPartiallyCompleted,
        );
        stubInsert();
        when(
          () => mockApi.getByBarcode(
            product.barcode,
            languageCode: any(named: 'languageCode'),
            maxRetries: 0,
          ),
        ).thenAnswer(
          (_) async => testProduct.copyWith(
            offProductImageUrl: 'https://images.openfoodfacts.org/front.jpg',
            offNutritionImageUrl:
                'https://images.openfoodfacts.org/nutrition.jpg',
          ),
        );
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer((_) async => const OffWriteResult.success());
        when(
          () => mockApi.uploadProductImage(
            barcode: any(named: 'barcode'),
            imageField: any(named: 'imageField'),
            imagePath: any(named: 'imagePath'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async => const OffWriteResult.success());

        final events = <SubmissionProgress>[];
        final result = await service.submitProduct(
          product,
          onProgress: events.add,
        );

        expect(result.submissionStatus, productSubmissionSubmitted);
        expect(events.last.completedImageCount, 3);
        verify(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'ingredients',
            imagePath: product.ingredientsImagePath!,
            languageCode: 'en',
          ),
        ).called(1);
        verifyNever(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'front',
            imagePath: product.productImagePath!,
            languageCode: 'en',
          ),
        );
        verifyNever(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'nutrition',
            imagePath: product.nutritionImagePath!,
            languageCode: 'en',
          ),
        );
      },
    );

    test(
      'retry uploads all images when the server state cannot be fetched',
      () async {
        final product = productWithAllImages().copyWith(
          submissionStatus: productSubmissionPartiallyCompleted,
        );
        stubInsert();
        when(
          () => mockApi.getByBarcode(
            product.barcode,
            languageCode: any(named: 'languageCode'),
            maxRetries: 0,
          ),
        ).thenThrow(FetchFailedException('offline'));
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer((_) async => const OffWriteResult.success());
        when(
          () => mockApi.uploadProductImage(
            barcode: any(named: 'barcode'),
            imageField: any(named: 'imageField'),
            imagePath: any(named: 'imagePath'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async => const OffWriteResult.success());

        final result = await service.submitProduct(product);

        expect(result.submissionStatus, productSubmissionSubmitted);
        verify(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'front',
            imagePath: product.productImagePath!,
            languageCode: 'en',
          ),
        ).called(1);
        verify(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'ingredients',
            imagePath: product.ingredientsImagePath!,
            languageCode: 'en',
          ),
        ).called(1);
        verify(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'nutrition',
            imagePath: product.nutritionImagePath!,
            languageCode: 'en',
          ),
        ).called(1);
      },
    );

    test(
      'compresses the image before upload and deletes the temp file',
      () async {
        final product = productWithAllImages();
        final tempDir = Directory.systemTemp.createTempSync('pantry_comp_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final compressedPath = '${tempDir.path}/front_compressed.jpg';
        File(compressedPath).writeAsBytesSync([9, 9, 9]);
        stubInsert();
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer((_) async => const OffWriteResult.success());
        when(
          () => mockApi.uploadProductImage(
            barcode: any(named: 'barcode'),
            imageField: any(named: 'imageField'),
            imagePath: any(named: 'imagePath'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async => const OffWriteResult.success());
        when(
          () => mockCompressor.compress(sourcePath: product.productImagePath!),
        ).thenAnswer((_) async => compressedPath);
        when(
          () => mockCompressor.compress(
            sourcePath: product.ingredientsImagePath!,
          ),
        ).thenAnswer((_) async => null);
        when(
          () =>
              mockCompressor.compress(sourcePath: product.nutritionImagePath!),
        ).thenAnswer((_) async => null);

        final result = await service.submitProduct(product);

        expect(result.submissionStatus, productSubmissionSubmitted);
        verify(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'front',
            imagePath: compressedPath,
            languageCode: 'en',
          ),
        ).called(1);
        verify(
          () => mockApi.uploadProductImage(
            barcode: product.barcode,
            imageField: 'ingredients',
            imagePath: product.ingredientsImagePath!,
            languageCode: 'en',
          ),
        ).called(1);
        // The temp file produced by compression is removed after the upload.
        expect(File(compressedPath).existsSync(), isFalse);
      },
    );

    test('uploads the original path when compression returns null', () async {
      final product = productWithAllImages();
      stubInsert();
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => const OffWriteResult.success());

      final result = await service.submitProduct(product);

      expect(result.submissionStatus, productSubmissionSubmitted);
      verify(
        () => mockApi.uploadProductImage(
          barcode: product.barcode,
          imageField: 'front',
          imagePath: product.productImagePath!,
          languageCode: 'en',
        ),
      ).called(1);
      verify(
        () => mockApi.uploadProductImage(
          barcode: product.barcode,
          imageField: 'ingredients',
          imagePath: product.ingredientsImagePath!,
          languageCode: 'en',
        ),
      ).called(1);
      verify(
        () => mockApi.uploadProductImage(
          barcode: product.barcode,
          imageField: 'nutrition',
          imagePath: product.nutritionImagePath!,
          languageCode: 'en',
        ),
      ).called(1);
    });

    test(
      'does not log the local image path when an image is missing',
      () async {
        const missingPath = '/nonexistent/pantry/front.jpg';
        final product = testProduct.copyWith(productImagePath: missingPath);
        stubInsert();
        when(
          () => mockApi.submitProduct(any()),
        ).thenAnswer((_) async => const OffWriteResult.success());

        await service.submitProduct(product);

        expect(recentLogs, isNot(contains(missingPath)));
      },
    );
  });

  group('flushQueue', () {
    test('removes the entry and returns 1 when the product submits', () async {
      final cached = testProduct.copyWith(
        submissionStatus: productSubmissionFailed,
      );
      final queueDao = ProductSubmissionQueueDao();
      final database = await mockDb.database;
      await queueDao.insert(database, testProduct.barcode);
      stubInsert();
      when(
        () => mockDb.getProduct(testProduct.barcode),
      ).thenAnswer((_) async => cached);
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer((_) async => const OffWriteResult.success());

      final submitted = await service.flushQueue();

      expect(submitted, 1);
      expect(await queueDao.isQueued(database, testProduct.barcode), isFalse);
    });

    test('increments the retry count when the submission fails', () async {
      final cached = testProduct.copyWith(
        submissionStatus: productSubmissionFailed,
      );
      final queueDao = ProductSubmissionQueueDao();
      final database = await mockDb.database;
      await queueDao.insert(database, testProduct.barcode);
      stubInsert();
      when(
        () => mockDb.getProduct(testProduct.barcode),
      ).thenAnswer((_) async => cached);
      when(
        () => mockApi.submitProduct(any()),
      ).thenAnswer(
        (_) async => const OffWriteResult.failure(OffWriteError.network),
      );

      final submitted = await service.flushQueue();

      expect(submitted, 0);
      final row = (await database.query('product_submission_queue')).single;
      expect(row['barcode'], testProduct.barcode);
      expect(row['retry_count'], 1);
    });

    test(
      'removes the entry when the cached product is already submitted',
      () async {
        final cached = testProduct.copyWith(
          submissionStatus: productSubmissionSubmitted,
        );
        final queueDao = ProductSubmissionQueueDao();
        final database = await mockDb.database;
        await queueDao.insert(database, testProduct.barcode);
        when(
          () => mockDb.getProduct(testProduct.barcode),
        ).thenAnswer((_) async => cached);

        final submitted = await service.flushQueue();

        expect(submitted, 0);
        expect(await queueDao.isQueued(database, testProduct.barcode), isFalse);
      },
    );

    test(
      'removes the entry when the cached product no longer exists',
      () async {
        final queueDao = ProductSubmissionQueueDao();
        final database = await mockDb.database;
        await queueDao.insert(database, testProduct.barcode);
        when(
          () => mockDb.getProduct(testProduct.barcode),
        ).thenAnswer((_) async => null);

        final submitted = await service.flushQueue();

        expect(submitted, 0);
        expect(await queueDao.isQueued(database, testProduct.barcode), isFalse);
      },
    );

    test('is a no-op when the queue is empty', () async {
      final submitted = await service.flushQueue();
      expect(submitted, 0);
    });
  });
}
