import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/services/cache_refresh_coordinator.dart';

/// Provides the singleton [CacheRefreshCoordinator] instance.
///
/// The connectivity probe reads [hasConnectionProvider] so the one-shot
/// check is shared with the rest of the app.
final cacheRefreshCoordinatorProvider = Provider<CacheRefreshCoordinator>((
  ref,
) {
  return CacheRefreshCoordinator(
    repo: ref.read(productRepositoryProvider),
    db: ref.read(databaseProvider),
    hasConnection: () => ref.read(hasConnectionProvider.future),
  );
});
