import 'package:flutter/foundation.dart';
import 'package:pantry_app/models/produce_cache_entry.dart';
import 'package:pantry_app/models/product_cache_entry.dart';
import 'package:pantry_app/utils/logger.dart';

/// Minimal Firestore-like interface that [FirebaseCacheClient] depends on.
///
/// Declared as an abstract class so the client avoids a hard import of
/// cloud_firestore in test code. In production this is backed by a
/// FirebaseFirestore instance; in tests by mocktail mocks.
abstract class FirestoreClient {
  /// Returns a document reference for the given [collectionPath] and
  /// [documentPath].
  FirestoreDocument doc(String collectionPath, String documentPath);

  /// Whether this client is available for operations.
  bool get isAvailable;
}

/// Minimal Firestore document-like interface.
abstract class FirestoreDocument {
  /// Fetches the document snapshot from the server.
  Future<FirestoreSnapshot> get();

  /// Writes data to this document (creates or overwrites).
  Future<void> set(Map<String, dynamic> data);

  /// Deletes this document.
  Future<void> delete();
}

/// Minimal Firestore document snapshot-like interface.
abstract class FirestoreSnapshot {
  /// Whether the document exists in Firestore.
  bool get exists;

  /// The data contained in this snapshot, or null if the document does not
  /// exist.
  Map<String, dynamic>? data();
}

/// Low-level Firestore client for product and produce caches.
///
/// Wraps two Firestore collections:
///   - `produce_cache/{name}` -- USDA produce data (ProduceCacheEntry)
///   - `product_cache/{barcode}` -- OFF barcoded product data (ProductCacheEntry)
///
/// ## Graceful degradation
///
/// When [isAvailable] is false, all get* methods return null and all set*
/// methods return false. This allows the app to function without Firebase
/// (e.g. development builds, missing google-services.json).
class FirebaseCacheClient {
  /// Creates a [FirebaseCacheClient].
  ///
  /// Pass a [FirestoreClient] instance (or null). When disabled, all
  /// operations are no-ops.
  FirebaseCacheClient({
    this._firestore,
    this._enabled = false,
  });

  final FirestoreClient? _firestore;
  final bool _enabled;

  /// Firestore collection name for USDA produce cache documents.
  @visibleForTesting
  static const String produceCollection = 'produce_cache';

  /// Firestore collection name for OFF barcoded product cache documents.
  @visibleForTesting
  static const String productCollection = 'product_cache';

  /// Whether Firebase operations are available.
  bool get isAvailable => _firestore != null && _enabled;

  // =================================================================
  //  Produce cache (USDA)
  // =================================================================

  /// Fetches a produce entry from Firestore by canonical English [name].
  ///
  /// Returns null on miss, on unavailable Firebase, or on any Firestore error.
  Future<ProduceCacheEntry?> getProduce(String name) async {
    if (!isAvailable) return null;
    try {
      final doc = await _firestore!.doc(produceCollection, name).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return ProduceCacheEntry.fromJson(data);
    } on Exception catch (e) {
      logWarning('Firestore getProduce failed for "$name": $e');
      return null;
    }
  }

  /// Stores a produce entry in Firestore.
  ///
  /// Returns true on success, false on unavailable or error.
  Future<bool> setProduce(ProduceCacheEntry entry) async {
    if (!isAvailable) return false;
    try {
      await _firestore!.doc(produceCollection, entry.name).set(entry.toJson());
      return true;
    } on Exception catch (e) {
      logWarning('Firestore setProduce failed for "${entry.name}": $e');
      return false;
    }
  }

  /// Deletes a produce entry from Firestore.
  Future<void> deleteProduce(String name) async {
    if (!isAvailable) return;
    try {
      await _firestore!.doc(produceCollection, name).delete();
    } on Exception catch (e) {
      logWarning('Firestore deleteProduce failed for "$name": $e');
    }
  }

  // =================================================================
  //  Product cache (OFF barcoded)
  // =================================================================

  /// Fetches a barcoded product entry from Firestore by [barcode].
  ///
  /// Returns null on miss, on unavailable Firebase, or on any Firestore error.
  Future<ProductCacheEntry?> getProduct(String barcode) async {
    if (!isAvailable) return null;
    try {
      final doc = await _firestore!.doc(productCollection, barcode).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return ProductCacheEntry.fromJson(data);
    } on Exception catch (e) {
      logWarning('Firestore getProduct failed for "$barcode": $e');
      return null;
    }
  }

  /// Stores a barcoded product entry in Firestore.
  ///
  /// Returns true on success, false on unavailable or error.
  Future<bool> setProduct(ProductCacheEntry entry) async {
    if (!isAvailable) return false;
    try {
      await _firestore!
          .doc(productCollection, entry.barcode)
          .set(entry.toJson());
      return true;
    } on Exception catch (e) {
      logWarning(
        'Firestore setProduct failed for "${entry.barcode}": $e',
      );
      return false;
    }
  }

  /// Deletes a barcoded product entry from Firestore.
  Future<void> deleteProduct(String barcode) async {
    if (!isAvailable) return;
    try {
      await _firestore!.doc(productCollection, barcode).delete();
    } on Exception catch (e) {
      logWarning('Firestore deleteProduct failed for "$barcode": $e');
    }
  }
}
