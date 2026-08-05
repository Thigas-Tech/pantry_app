import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The managed photo paths of a saved product, one entry per slot.
///
/// A null entry means that slot had no photo (or its photo could not be
/// persisted). The non-null values are absolute paths inside the
/// application-documents product image directory.
typedef SavedProductPhotoPaths = ({
  String? nutrition,
  String? ingredients,
  String? product,
});

/// Owns persistence and cleanup of product photos for the manual-entry form.
///
/// Photos are copied into a stable managed file per slot and barcode inside
/// the application-documents `product_images` directory, following the
/// `<barcode>_<suffix>.jpg` convention used by the product model. The service
/// is the single testable boundary between picked files and the durable store.
///
/// ## Lifecycle
///
/// - [assign] copies a picked file into its managed path immediately, so the
///   photo survives OS cache purges of picker temp files and is preserved
///   when form validation fails.
/// - [remove] only clears the slot. Physical deletion is deferred to [save]
///   or [cleanupUncommitted] so an undo action can restore a live file while
///   the form is still open.
/// - [save] persists every non-empty slot and deletes the managed file of any
///   empty slot that still has one on disk, without touching files still
///   referenced by another slot.
/// - [cleanupUncommitted] deletes managed files for a barcode that were never
///   committed to a saved product. Call it from dispose so backing out of the
///   form leaves no orphaned files, while images committed to a saved product
///   are preserved.
///
/// Managed paths are deterministic (`<barcode>_<suffix>.jpg`), so replacing a
/// photo overwrites the same file and no stale copies accumulate.
class ProductImageService {
  /// Creates a [ProductImageService].
  ///
  /// [imageDirectory] is injected for tests; when omitted the service resolves
  /// `getApplicationDocumentsDirectory()/product_images` at runtime.
  ProductImageService({this.imageDirectory});

  /// The directory that holds managed product photos, or null to resolve the
  /// application-documents `product_images` directory at runtime.
  final Directory? imageDirectory;

  /// Copies [picked] into the managed file for [field] of [barcode] and
  /// returns [slots] updated with the managed file.
  ///
  /// Reassigning a slot overwrites the same managed path so no stale file is
  /// left behind. When [picked] does not exist on disk the slots are returned
  /// unchanged and a warning is logged, so a missing picker temp file never
  /// breaks the form.
  Future<ProductPhotoSlots> assign(
    ProductPhotoSlots slots,
    ImageField field,
    File picked, {
    required String barcode,
  }) async {
    if (!await picked.exists()) {
      logWarning(
        'Cannot assign missing picked file to $field: ${picked.path}',
      );
      return slots;
    }
    final dir = await _ensureDirectory();
    final path = p.join(dir.path, _fileName(barcode, field));
    if (picked.path != path) {
      await picked.copy(path);
      _evictCachedImage(path);
    }
    return slots.withField(field, File(path));
  }

  /// Returns [slots] with [field] cleared.
  ///
  /// Does not delete the managed file on disk; deletion is deferred to [save]
  /// or [cleanupUncommitted] so the photo can still be restored by undo.
  ProductPhotoSlots remove(ProductPhotoSlots slots, ImageField field) {
    return slots.withField(field, null);
  }

  /// Persists every non-empty slot in [slots] for [barcode] and deletes the
  /// managed file of every empty slot that still has one on disk.
  ///
  /// A slot whose file is already at its managed path is kept as-is. A slot
  /// pointing at another file is copied into the managed path. A file is only
  /// deleted for an empty slot when no other slot still references it, keeping
  /// ownership safe when paths are shared.
  ///
  /// Returns the three managed paths, with null for slots that ended up
  /// without a persisted file.
  Future<SavedProductPhotoPaths> save(
    ProductPhotoSlots slots, {
    required String barcode,
  }) async {
    final dir = await _ensureDirectory();
    return (
      nutrition: await _persistField(slots, ImageField.nutrition, barcode, dir),
      ingredients: await _persistField(
        slots,
        ImageField.ingredients,
        barcode,
        dir,
      ),
      product: await _persistField(slots, ImageField.product, barcode, dir),
    );
  }

  /// Deletes managed files for [barcode] that are not in [committedPaths] and
  /// not referenced by another slot in [slots].
  ///
  /// Safe to call from dispose: images committed to a saved product (listed in
  /// [committedPaths]) are preserved, while files the form never committed are
  /// removed.
  Future<void> cleanupUncommitted(
    ProductPhotoSlots slots, {
    required String barcode,
    required Set<String> committedPaths,
  }) async {
    final dir = await _resolveDirectory();
    if (!await dir.exists()) return;
    for (final field in ImageField.values) {
      final path = p.join(dir.path, _fileName(barcode, field));
      final file = File(path);
      final keep =
          committedPaths.contains(path) ||
          _anyOtherSlotReferences(slots, field, path);
      if (!keep && await file.exists()) {
        await file.delete();
        logInfo('Cleaned up uncommitted product photo: $path');
      }
    }
  }

  /// Resolves and creates the product image directory.
  Future<Directory> _ensureDirectory() async {
    final dir = await _resolveDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Resolves the product image directory without creating it.
  Future<Directory> _resolveDirectory() async {
    final dir = imageDirectory;
    if (dir != null) return dir;
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, 'product_images'));
  }

  /// Persists a single [field], deleting a stale managed file when the slot is
  /// empty. Returns the managed path, or null when the slot has no file.
  Future<String?> _persistField(
    ProductPhotoSlots slots,
    ImageField field,
    String barcode,
    Directory dir,
  ) async {
    final path = p.join(dir.path, _fileName(barcode, field));
    final file = slots.forField(field);
    if (file == null) {
      final managed = File(path);
      final keep = _anyOtherSlotReferences(slots, field, path);
      if (!keep && await managed.exists()) {
        await managed.delete();
        logInfo('Deleted stale product photo: $path');
      }
      return null;
    }
    if (file.path == path) return path;
    if (!await file.exists()) {
      logWarning('Skipping missing product photo source: ${file.path}');
      return null;
    }
    await file.copy(path);
    _evictCachedImage(path);
    return path;
  }

  /// Returns true when any slot other than [field] references [path].
  bool _anyOtherSlotReferences(
    ProductPhotoSlots slots,
    ImageField field,
    String path,
  ) {
    return ImageField.values.any(
      (other) => other != field && slots.forField(other)?.path == path,
    );
  }

  /// Removes any cached [FileImage] for [path] so an overwritten managed file
  /// is not displayed with stale pixels.
  void _evictCachedImage(String path) {
    PaintingBinding.instance.imageCache.evict(FileImage(File(path)));
  }

  /// Builds the managed file name for [field] of [barcode], sanitizing the
  /// barcode so it cannot inject path separators.
  String _fileName(String barcode, ImageField field) {
    final safe = barcode.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
    return '${safe}_${_suffixFor(field)}.jpg';
  }

  /// The local file suffix for [field], matching the product model columns.
  String _suffixFor(ImageField field) {
    switch (field) {
      case ImageField.nutrition:
        return 'nutrition';
      case ImageField.ingredients:
        return 'ingredients';
      case ImageField.product:
        return 'product';
    }
  }
}
