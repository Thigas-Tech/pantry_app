import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/dio_provider.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';
import 'package:pantry_app/services/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dio = ref.watch(dioProvider);
  final primaryApi = OpenFoodFactsApi(dio);
  return ProductRepository(db, primaryApi);
});
