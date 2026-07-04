import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/providers/dio_provider.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';

/// Provides the configured [OpenFoodFactsApi] instance.
///
/// Credentials are read from [AppConfig]. Set [AppConfig.offUserId] and
/// [AppConfig.offPassword] to enable product submissions; leave them
/// empty to disable submission features.
final apiServiceProvider = Provider<OpenFoodFactsApi>((ref) {
  final dio = ref.read(dioProvider);
  return OpenFoodFactsApi(
    dio,
    userId: AppConfig.offUserId,
    password: AppConfig.offPassword,
    contactEmail: AppConfig.contactEmail,
    useStaging: AppConfig.useOffStaging,
  );
});
