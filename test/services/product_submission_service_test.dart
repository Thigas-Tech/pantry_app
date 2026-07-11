import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/product_submission_queue_dao.dart';
import 'package:pantry_app/models/product.dart';
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
  });
}
