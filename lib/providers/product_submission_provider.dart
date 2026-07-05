import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/product_submission_service.dart';

/// Provider for [ProductSubmissionService].
final productSubmissionServiceProvider = Provider<ProductSubmissionService>(
  (ref) {
    final db = ref.watch(databaseProvider);
    final api = ref.watch(apiServiceProvider);
    return ProductSubmissionService(db: db, api: api);
  },
);
