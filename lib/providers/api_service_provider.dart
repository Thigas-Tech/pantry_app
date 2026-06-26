import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/dio_provider.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';
import 'package:pantry_app/services/product_api_service.dart';

final apiServiceProvider = Provider<ProductApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return OpenFoodFactsApi(dio);
});
