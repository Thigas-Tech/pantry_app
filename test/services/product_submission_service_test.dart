import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/product_submission_queue_dao.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_submission_state.dart';
import 'package:pantry_app/services/exceptions.dart';
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
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await const ProductSubmissionQueueDao().createTable(db);

    // Stub the database getter so _queueForRetry uses the real DB.
    when(() => mockDb.database).thenAnswer((_) async => db);

    // Stub the productSubmissionQueueDao getter.
    when(
      () => mockDb.productSubmissionQueueDao,
    ).thenReturn(const ProductSubmissionQueueDao());
  });

  tearDown(() async {
    final db = await mockDb.database;
    await db.close();
  });

  group('submitProduct', () {
    test('sets status to pending before submission', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => true);

      await service.submitProduct(testProduct);

      verify(
        () => mockDb.insertProduct(
          testProduct.copyWith(submissionStatus: productSubmissionPending),
        ),
      ).called(1);
    });

    test('returns submitted when metadata succeeds (no images)', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => true);

      final result = await service.submitProduct(testProduct);
      expect(result.submissionStatus, productSubmissionSubmitted);
    });

    test('returns failed when metadata submission returns false', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => false);

      final result = await service.submitProduct(testProduct);
      expect(result.submissionStatus, productSubmissionFailed);
    });

    test('returns failed when metadata throws exception', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(
        () => mockApi.submitProduct(any()),
      ).thenThrow(Exception('Network error'));

      final result = await service.submitProduct(testProduct);
      expect(result.submissionStatus, productSubmissionFailed);
    });

    test('inserts final status to database on success', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => true);

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
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
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

    test('reports progress transitions through the callback', () async {
      final tempDir = await Directory.systemTemp.createTemp('submit_progress');
      addTearDown(() => tempDir.delete(recursive: true));
      final imageFile = File('${tempDir.path}/front.jpg')
        ..writeAsStringSync('x');
      final withImage = testProduct.copyWith(productImagePath: imageFile.path);

      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => true);
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => true);

      final steps = <ProductSubmissionState>[];
      final result = await service.submitProduct(
        withImage,
        onProgress: steps.add,
      );

      expect(result.submissionStatus, productSubmissionSubmitted);
      expect(steps.first.step, SubmissionStep.submittingMetadata);
      expect(
        steps.any(
          (s) =>
              s.step == SubmissionStep.uploadingImage &&
              s.currentImageIndex == 1 &&
              s.totalImages == 1,
        ),
        isTrue,
      );
      expect(steps.last.step, SubmissionStep.completed);
      expect(steps.last.barcode, withImage.barcode);
    });

    test('marks partially completed when one image upload fails', () async {
      final tempDir = await Directory.systemTemp.createTemp('submit_partial');
      addTearDown(() => tempDir.delete(recursive: true));
      final front = File('${tempDir.path}/front.jpg')..writeAsStringSync('a');
      final ingredients = File('${tempDir.path}/ing.jpg')
        ..writeAsStringSync('b');
      final withImages = testProduct.copyWith(
        productImagePath: front.path,
        ingredientsImagePath: ingredients.path,
      );

      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => true);
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((invocation) async {
        final field = invocation.namedArguments[#imageField] as String;
        return field != 'front';
      });

      final result = await service.submitProduct(withImages);

      expect(result.submissionStatus, productSubmissionPartiallyCompleted);
      final db = await mockDb.database;
      expect(await db.query('product_submission_queue'), isEmpty);
    });

    test('queues transient image failure for background retry', () async {
      final tempDir = await Directory.systemTemp.createTemp('submit_transient');
      addTearDown(() => tempDir.delete(recursive: true));
      final front = File('${tempDir.path}/front.jpg')..writeAsStringSync('a');
      final withImage = testProduct.copyWith(productImagePath: front.path);

      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => true);
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenThrow(Exception('Network error'));

      final result = await service.submitProduct(withImage);

      expect(result.submissionStatus, productSubmissionPartiallyCompleted);
      final db = await mockDb.database;
      final rows = await db.query('product_submission_queue');
      expect(rows.length, 1);
      expect(rows.first['barcode'], testProduct.barcode);
    });

    test('times out a hung image upload and reports it failed', () async {
      final tempDir = await Directory.systemTemp.createTemp('submit_timeout');
      addTearDown(() => tempDir.delete(recursive: true));
      final front = File('${tempDir.path}/front.jpg')..writeAsStringSync('a');
      final withImage = testProduct.copyWith(productImagePath: front.path);
      final neverCompletes = Completer<bool>();
      final timeoutService = ProductSubmissionService(
        db: mockDb,
        api: mockApi,
        imageUploadTimeout: const Duration(milliseconds: 20),
      );

      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => true);
      when(
        () => mockApi.uploadProductImage(
          barcode: any(named: 'barcode'),
          imageField: any(named: 'imageField'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) => neverCompletes.future);

      final result = await timeoutService.submitProduct(withImage);

      expect(result.submissionStatus, productSubmissionPartiallyCompleted);
      final db = await mockDb.database;
      final rows = await db.query('product_submission_queue');
      expect(rows.length, 1, reason: 'Timeout is transient and must be queued');
    });

    test('does not queue when metadata is rejected permanently', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => false);

      final result = await service.submitProduct(testProduct);

      expect(result.submissionStatus, productSubmissionFailed);
      final db = await mockDb.database;
      expect(await db.query('product_submission_queue'), isEmpty);
    });

    test('queues a transient metadata exception for retry', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(
        () => mockApi.submitProduct(any()),
      ).thenThrow(Exception('Network error'));

      final result = await service.submitProduct(testProduct);

      expect(result.submissionStatus, productSubmissionFailed);
      final db = await mockDb.database;
      final rows = await db.query('product_submission_queue');
      expect(rows.length, 1);
    });

    test('rejects a concurrent submission for the same barcode', () async {
      final gate = Completer<void>();
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async {
        await gate.future;
        return true;
      });

      final first = service.submitProduct(testProduct);
      await expectLater(
        service.submitProduct(testProduct),
        throwsA(isA<SubmissionAlreadyInProgressException>()),
      );
      gate.complete();
      await first;
    });
  });

  group('flushQueue', () {
    const queueProduct = Product(
      barcode: '999',
      name: 'Queue Product',
      source: 'manual',
    );

    test('removes queue entries for products no longer in cache', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(() => mockDb.getProduct('999')).thenAnswer((_) async => null);
      final db = await mockDb.database;
      await const ProductSubmissionQueueDao().insert(db, '999');

      final submitted = await service.flushQueue();

      expect(submitted, 0);
      expect(await db.query('product_submission_queue'), isEmpty);
    });

    test('removes queue entries for already-submitted products', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(
        () => mockDb.getProduct('999'),
      ).thenAnswer(
        (_) async => queueProduct.copyWith(
          submissionStatus: productSubmissionSubmitted,
        ),
      );
      final db = await mockDb.database;
      await const ProductSubmissionQueueDao().insert(db, '999');

      final submitted = await service.flushQueue();

      expect(submitted, 0);
      expect(await db.query('product_submission_queue'), isEmpty);
    });

    test('submits queued products and removes entries on success', () async {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
      when(
        () => mockDb.getProduct('999'),
      ).thenAnswer((_) async => queueProduct);
      when(() => mockApi.submitProduct(any())).thenAnswer((_) async => true);
      final db = await mockDb.database;
      await const ProductSubmissionQueueDao().insert(db, '999');

      final submitted = await service.flushQueue();

      expect(submitted, 1);
      expect(await db.query('product_submission_queue'), isEmpty);
    });
  });
}
