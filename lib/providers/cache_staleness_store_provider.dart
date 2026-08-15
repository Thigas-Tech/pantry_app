import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/cache_staleness_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the singleton [CacheStalenessStore] instance.
///
/// The store persists the last inventory-refresh timestamp in
/// SharedPreferences so the background refresh decision survives restarts.
/// The store is constructed synchronously around the cached
/// [SharedPreferences.getInstance] future, matching the device-only cache
/// policy where no database table is needed for staleness tracking.
final cacheStalenessStoreProvider = Provider<CacheStalenessStore>((ref) {
  return CacheStalenessStore(SharedPreferences.getInstance());
});
