import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiServiceProvider);
  return ProductRepository(db, api);
});
