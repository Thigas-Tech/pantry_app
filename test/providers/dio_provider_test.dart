import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/providers/dio_provider.dart';

void main() {
  setUp(() {
    dotenv.testLoad(mergeWith: {});
  });

  test('provides a Dio instance with correct configuration', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);
    expect(dio, isA<Dio>());
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 10));
    expect(
      dio.options.headers['User-Agent'],
      'PantryApp/1.0 (${AppConfig.contactEmail})',
    );
  });
}
