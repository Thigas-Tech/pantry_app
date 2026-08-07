import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/product_submission_queue_dao.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/product_submission_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOffAdapter extends Mock implements OffAdapter {}

class FakeDatabase extends Fake implements Database {}

const testProduct = Product(
  barcode: '123456789',
  name: 'Test Product',
  source: 'manual',
);

void main() {
  late MockDatabaseHelper mockDb;
  late MockOffAdapter mockApi;
  late ProductSubmissionService service;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(FakeDatabase());
    registerFallbackValue('');
    registerFallbackValue(const Product(barcode: '', name: ''));
  });

  setUp(() async {
    mockDb = MockDatabaseHelper();
    mockApi = MockOffAdapter();
    service = ProductSubmissionService(db: mockDb, api: mockApi);

    // Create a real in-memory database for queue DAO operations.
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await const ProductSubmissionQueueDao().createTable(db);

    // Stub the database getter so _queueForRetry uses the real DB.
    when(() => mockDb.database).thenAnswer((_) async => db);

    // Stub the productSubmissionQueueDao getter.
    when(
      () => mockDb.productSubmissionQueueDao,
    ).thenReturn(const ProductSubmissionQueueDao());
  });

  tearDown(() async {
    await db.close();
  });

  void stubInsert() {
    when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
  }

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
  });

  group('submitProduct image handling', () {
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
  });
}
