import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/product_submission_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOffAdapter extends Mock implements OffAdapter {}

const testProduct = Product(
  barcode: '123456789',
  name: 'Test Product',
  source: 'manual',
);

void main() {
  late MockDatabaseHelper mockDb;
  late MockOffAdapter mockApi;
  late ProductSubmissionService service;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockOffAdapter();
    service = ProductSubmissionService(db: mockDb, api: mockApi);

    registerFallbackValue(const Product(barcode: '', name: ''));
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
