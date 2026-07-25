import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pantry_app/services/firebase_cache_client.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';

/// Concrete [FirestoreClient] backed by a [FirebaseFirestore] instance.
///
/// This adapter bridges the abstract [FirestoreClient] interface used by
/// [FirebaseCacheClient] with the real Firebase Firestore SDK. It is created
/// inside [FirebaseCacheService]'s provider and passed to the client.
///
/// ## Thread safety
///
/// All methods delegate directly to [FirebaseFirestore] which is itself
/// thread-safe. No additional synchronisation is needed.
class FirebaseFirestoreClientAdapter implements FirestoreClient {
  /// Creates an adapter wrapping the given [FirebaseFirestore] instance.
  const FirebaseFirestoreClientAdapter(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  bool get isAvailable => true;

  @override
  FirestoreDocument doc(String collectionPath, String documentPath) {
    return _FirebaseFirestoreDocumentAdapter(
      _firestore.collection(collectionPath).doc(documentPath),
    );
  }

  @override
  FirestoreCollection collection(String collectionPath) {
    return _FirebaseFirestoreCollectionAdapter(
      _firestore.collection(collectionPath),
    );
  }
}

/// Concrete [FirestoreDocument] backed by a [DocumentReference].
class _FirebaseFirestoreDocumentAdapter implements FirestoreDocument {
  const _FirebaseFirestoreDocumentAdapter(this._doc);

  final DocumentReference _doc;

  @override
  Future<FirestoreSnapshot> get() async {
    final snapshot = await _doc.get();
    return _FirebaseFirestoreSnapshotAdapter(snapshot);
  }

  @override
  Future<void> set(Map<String, dynamic> data) => _doc.set(data);

  @override
  Future<void> delete() => _doc.delete();
}

/// Concrete [FirestoreSnapshot] backed by a [DocumentSnapshot].
class _FirebaseFirestoreSnapshotAdapter implements FirestoreSnapshot {
  const _FirebaseFirestoreSnapshotAdapter(this._snapshot);

  final DocumentSnapshot _snapshot;

  @override
  bool get exists => _snapshot.exists;

  @override
  Map<String, dynamic>? data() => _snapshot.data() as Map<String, dynamic>?;
}

/// Concrete [FirestoreCollection] backed by a [Query] (from
/// [CollectionReference]).
class _FirebaseFirestoreCollectionAdapter implements FirestoreCollection {
  _FirebaseFirestoreCollectionAdapter(this._query);

  Query _query;

  @override
  FirestoreCollection orderBy(String field, {bool descending = false}) {
    _query = _query.orderBy(field, descending: descending);
    return this;
  }

  @override
  FirestoreCollection limit(int count) {
    _query = _query.limit(count);
    return this;
  }

  @override
  FirestoreCollection startAfter(String documentId) {
    _query = _query.startAfter([documentId]);
    return this;
  }

  @override
  Future<List<FirestoreSnapshot>> get() async {
    final snapshot = await _query.get();
    return snapshot.docs
        .map(
          (doc) => _FirebaseFirestoreSnapshotAdapter(doc) as FirestoreSnapshot,
        )
        .toList();
  }
}
