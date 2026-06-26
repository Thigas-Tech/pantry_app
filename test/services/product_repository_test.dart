import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_api_service.dart';
import 'package:pantry_app/services/product_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockProductApiService extends Mock implements ProductApiService {}

void main() {
  late ProductRepository repository;
  late MockDatabaseHelper mockDb;
  late MockProductApiService mockApi;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockProductApiService();
    repository = ProductRepository(mockDb, mockApi);
  });

  const testBarcode = '123456789';
  final testProduct = Product(
    barcode: testBarcode,
    name: 'Test Product',
    energyKcal: 100,
    lastSynced: DateTime.now().millisecondsSinceEpoch,
  );

  test('returns cached product when available', () async {
    when(
      () => mockDb.getProduct(testBarcode),
    ).thenAnswer((_) async => testProduct);

    final product = await repository.getProduct(testBarcode);

    expect(product, testProduct);
    verify(() => mockDb.getProduct(testBarcode)).called(1);
    verifyNever(() => mockApi.getByBarcode(any()));
  });

  test('fetches from API and caches when not in DB', () async {
    when(() => mockDb.getProduct(testBarcode)).thenAnswer((_) async => null);
    when(
      () => mockApi.getByBarcode(testBarcode),
    ).thenAnswer((_) async => testProduct);
    when(
      () => mockDb.insertProduct(testProduct),
    ).thenAnswer((_) async => Future.value());

    final product = await repository.getProduct(testBarcode);

    expect(product, testProduct);
    verify(() => mockDb.insertProduct(testProduct)).called(1);
  });

  test('throws ProductNotFoundException when API returns not found', () async {
    when(() => mockDb.getProduct(testBarcode)).thenAnswer((_) async => null);
    when(
      () => mockApi.getByBarcode(testBarcode),
    ).thenThrow(ProductNotFoundException('Not found'));

    expect(
      () => repository.getProduct(testBarcode),
      throwsA(isA<ProductNotFoundException>()),
    );
  });

  test('throws FetchFailedException on generic API error', () async {
    when(() => mockDb.getProduct(testBarcode)).thenAnswer((_) async => null);
    when(
      () => mockApi.getByBarcode(testBarcode),
    ).thenThrow(Exception('Network error'));

    expect(
      () => repository.getProduct(testBarcode),
      throwsA(isA<FetchFailedException>()),
    );
  });
}
