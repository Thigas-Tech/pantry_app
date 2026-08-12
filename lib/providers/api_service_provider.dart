import 'package:pantry_app/config.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_service_provider.g.dart';

/// Provides the configured [OffAdapter] instance.
///
/// Uses [AppConfig.useOffStaging] to select between OFF production
/// and staging servers. No credentials are needed for read operations;
/// the adapter uses a test user (smoothie-app/strawberrybanana)
/// following the convention established by the official smooth-app.
@Riverpod(keepAlive: true)
OffAdapter apiService(Ref ref) {
  return OffAdapter(useStaging: AppConfig.useOffStaging);
}
