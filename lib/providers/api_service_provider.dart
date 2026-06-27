import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/dio_provider.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';

/// Provides the configured [OpenFoodFactsApi] instance.
///
/// The API is configured with credentials for the Open Food Facts staging
/// server. **These credentials must be removed or replaced before the app
/// is distributed to end users.**
///
/// ## Security note
///
/// Hardcoding credentials in source code is acceptable only during
/// development. In a production build, credentials should be:
/// - Entered by the user in a settings screen.
/// - Stored securely (e.g., using `flutter_secure_storage`).
/// - Or removed entirely if the app does not submit products.
///
/// ## Staging vs. production
///
/// The `useStaging` flag is currently `true`, meaning all API calls go
/// to `world.openfoodfacts.net`. Set it to `false` to use the production
/// server (`world.openfoodfacts.org`).
final apiServiceProvider = Provider<OpenFoodFactsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return OpenFoodFactsApi(
    dio,
    // TODO(ThiagoAssis): Remove credentials before distribution.
    userId: 'thiagoassis',
    password: 'H%Mcfp#Y74p\$ucbBUEFP',
  );
});
