/// Smoke tests for Riverpod providers.
///
/// Verifies that each provider can be instantiated without errors.
/// Detailed logic tests are in the repository and service test files.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/dio_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';

void main() {
  test('databaseProvider returns DatabaseHelper', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final db = container.read(databaseProvider);
    expect(db, isNotNull);
  });

  test('dioProvider returns Dio', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dio = container.read(dioProvider);
    expect(dio, isNotNull);
  });

  test('apiServiceProvider returns OpenFoodFactsApi', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final api = container.read(apiServiceProvider);
    expect(api, isNotNull);
  });

  test('productRepositoryProvider returns ProductRepository', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repo = container.read(productRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('inventoryWithProductProvider can be read (skipped – needs DB)', () {
    // This provider requires a live database, which is not set up in
    // unit tests. Integration tests or widget tests would cover this.
  }, skip: true);
}
