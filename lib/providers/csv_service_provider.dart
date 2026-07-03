import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/csv_service.dart';

/// Provides the [CsvService] instance backed by the current database.
final csvServiceProvider = Provider<CsvService>((ref) {
  final db = ref.watch(databaseProvider);
  return CsvService(db);
});
