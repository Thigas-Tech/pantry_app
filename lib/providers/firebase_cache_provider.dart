import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/firebase_cache_client.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/firebase_firestore_client_adapter.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:pantry_app/utils/logger.dart';

/// Provides the singleton [FirebaseCacheService] instance.
///
/// When [AppConfig.firebaseEnabled] is true, the provider attempts to
/// initialise a [FirebaseFirestoreClientAdapter] wrapping
/// [FirebaseFirestore.instance]. If that call fails (e.g. missing
/// google-services.json), the cache service is created with
/// [FirebaseCacheService.isAvailable] is false and all operations are no-ops.
///
/// When [AppConfig.firebaseEnabled] is false (default), the cache service
/// is created in disabled mode without any Firebase interaction.
///
/// ## Dependencies
///
/// - The database provider for cache metadata.
/// - The API service provider (OFF SDK wrapper).
/// - [UsdaApiClient] — created inline for USDA fallback lookups.
///
/// ## Lifetime
///
/// This is a plain [Provider] (not auto-dispose) so the service lives for
/// the entire app session. The service is stateless between lookups; it
/// holds no mutable state.
/// - [UsdaApiClient] — created inline for USDA fallback lookups.
///
/// ## Lifetime
///
/// This is a plain [Provider] (not auto-dispose) so the service lives for
/// the entire app session. The service is stateless between lookups; it
/// holds no mutable state.
final firebaseCacheProvider = Provider<FirebaseCacheService>((ref) {
  final db = ref.read(databaseProvider);
  final api = ref.read(apiServiceProvider);

  FirebaseCacheClient client;
  if (AppConfig.firebaseEnabled) {
    try {
      final firestore = FirebaseFirestore.instance;
      final adapter = FirebaseFirestoreClientAdapter(firestore);
      client = FirebaseCacheClient(firestore: adapter, enabled: true);
    } on Exception catch (e) {
      logWarning('FirebaseFirestore.instance failed, caching disabled: $e');
      client = FirebaseCacheClient();
    }
  } else {
    client = FirebaseCacheClient();
  }

  return FirebaseCacheService(
    db: db,
    firebaseClient: client,
    usdaClient: UsdaApiClient(),
    offAdapter: api,
  );
});
