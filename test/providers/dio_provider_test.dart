import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/dio_provider.dart';

/// Tests for [dioProvider].
void main() {
  test('provides a Dio instance with correct configuration', () {
    /// The provider returns a Dio with timeouts and a User-Agent header.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);
    expect(dio, isA<Dio>());
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 10));
    expect(
      dio.options.headers['User-Agent'],
      'PantryApp/1.0 (thiago.assisfernandes@gmail.com)',
    );
  });
}
