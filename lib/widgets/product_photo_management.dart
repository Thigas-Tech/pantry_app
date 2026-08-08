import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/services/product_photo_picker.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/utils/camera_permission_dialog.dart';
import 'package:pantry_app/utils/gallery_permission_dialog.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';

/// Manages the three local photos of a manually entered product from the
/// product detail screen.
///
/// Renders the nutrition, ingredients, and product photo slots using the
/// shared [ProductPhotoTile] and [ProductPhotoPreview] components. Tapping a
/// filled slot opens the preview with retake, replace, and delete actions;
/// empty slots offer an add-photo affordance backed by [ProductPhotoPicker]
/// and [ProductImageService].
///
/// Every mutation builds an updated [Product] (with the touched slot path
/// replaced or cleared), persists it through [DatabaseHelper.insertProduct]
/// (a raw upsert so a cleared path really is removed, unlike
/// [ProductRepository.cacheProduct]'s merge), and reports it via [onChanged].
/// Deleting a slot keeps the physical file on disk so the undo action can
/// restore a live photo; the detail screen removes orphaned files on dispose.
class ProductPhotoManagement extends ConsumerWidget {
  /// Creates a [ProductPhotoManagement] for the given [product].
  const ProductPhotoManagement({
    required this.product,
    required this.onChanged,
    super.key,
  });

  /// The manual product whose photos are edited.
  final Product product;

  /// Called with the updated product after every photo mutation.
  final ValueChanged<Product> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.captureImages,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _tile(
          context,
          ref,
          l10n.nutritionTableImage,
          product.nutritionImagePath,
          ImageField.nutrition,
        ),
        _tile(
          context,
          ref,
          l10n.ingredientsImage,
          product.ingredientsImagePath,
          ImageField.ingredients,
        ),
        _tile(
          context,
          ref,
          l10n.productImage,
          product.productImagePath,
          ImageField.product,
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    String label,
    String? path,
    ImageField field,
  ) {
    return ProductPhotoTile(
      label: label,
      image: _fileFor(path),
      onAdd: () => _chooseSource(context, ref, field),
      onTap: () => _openPreview(context, ref, field),
      onDelete: () => _removePhoto(context, ref, field),
    );
  }

  String _labelFor(BuildContext context, ImageField field) {
    final l10n = AppLocalizations.of(context)!;
    return switch (field) {
      ImageField.nutrition => l10n.nutritionTableImage,
      ImageField.ingredients => l10n.ingredientsImage,
      ImageField.product => l10n.productImage,
    };
  }

  /// The current local path for [field], or null when the slot is empty.
  String? _pathFor(ImageField field) {
    return switch (field) {
      ImageField.nutrition => product.nutritionImagePath,
      ImageField.ingredients => product.ingredientsImagePath,
      ImageField.product => product.productImagePath,
    };
  }

  /// Returns [product] with [field] set to [path].
  Product _withPath(ImageField field, String? path) {
    return switch (field) {
      ImageField.nutrition => product.copyWith(nutritionImagePath: path),
      ImageField.ingredients => product.copyWith(ingredientsImagePath: path),
      ImageField.product => product.copyWith(productImagePath: path),
    };
  }

  /// Returns [current] with [field] restored to [path].
  Product _restorePath(Product current, ImageField field, String path) {
    return switch (field) {
      ImageField.nutrition => current.copyWith(nutritionImagePath: path),
      ImageField.ingredients => current.copyWith(ingredientsImagePath: path),
      ImageField.product => current.copyWith(productImagePath: path),
    };
  }

  /// A [File] for [path], or null for an empty slot.
  File? _fileFor(String? path) {
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  /// Builds a [ProductPhotoSlots] snapshot from the current product paths.
  ProductPhotoSlots _slotsFrom() {
    return ProductPhotoSlots(
      nutrition: _fileFor(product.nutritionImagePath),
      ingredients: _fileFor(product.ingredientsImagePath),
      product: _fileFor(product.productImagePath),
    );
  }

  Future<void> _chooseSource(
    BuildContext context,
    WidgetRef ref,
    ImageField field,
  ) async {
    final source = await showPhotoSourceChooser(context);
    if (source == null || !context.mounted) return;
    await _pick(context, ref, field, source);
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    ImageField field,
    PhotoSource source,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(productPhotoPickerProvider).pick(source);
    if (!context.mounted) return;
    switch (result) {
      case PhotoPicked(:final file):
        final slots = _slotsFrom();
        final imageService = ref.read(productImageServiceProvider);
        final updatedSlots = await imageService.assign(
          slots,
          field,
          file,
          barcode: product.barcode,
        );
        final managedPath = updatedSlots.forField(field)?.path;
        if (managedPath == null) {
          if (context.mounted) {
            SnackbarHelper.showWarning(context, l10n.couldNotAttachImage);
          }
          return;
        }
        final updated = _withPath(field, managedPath);
        await _persist(ref, updated);
        onChanged(updated);
      case PhotoPermissionDenied(:final permanentlyDenied):
        if (permanentlyDenied) {
          await showCameraPermissionDialog(context);
        } else {
          SnackbarHelper.showWarning(context, l10n.cameraPermissionDenied);
        }
      case PhotoGalleryPermissionDenied():
        await showGalleryPermissionDialog(context);
      case PhotoPickCancelled():
        break;
    }
  }

  Future<void> _openPreview(
    BuildContext context,
    WidgetRef ref,
    ImageField field,
  ) async {
    final image = _fileFor(_pathFor(field));
    if (image == null) return;
    final action = await Navigator.of(context).push<PhotoPreviewAction>(
      MaterialPageRoute<PhotoPreviewAction>(
        builder: (_) => ProductPhotoPreview(
          image: image,
          label: _labelFor(context, field),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case PhotoPreviewAction.close:
        break;
      case PhotoPreviewAction.retake:
        await _pick(context, ref, field, PhotoSource.camera);
      case PhotoPreviewAction.replace:
        await _chooseSource(context, ref, field);
      case PhotoPreviewAction.delete:
        await _removePhoto(context, ref, field);
    }
  }

  /// Clears [field] from the product, persists the change, and offers undo.
  ///
  /// The physical file is kept on disk so undo restores a live photo; the
  /// detail screen deletes orphaned files when it is disposed.
  Future<void> _removePhoto(
    BuildContext context,
    WidgetRef ref,
    ImageField field,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final removedPath = _pathFor(field);
    if (removedPath == null) return;
    final updated = _withPath(field, null);
    await _persist(ref, updated);
    if (!context.mounted) return;
    onChanged(updated);
    logInfo('Removed ${field.name} photo path for ${product.barcode}');
    SnackbarHelper.showUndo(context, l10n.photoRemoved, () async {
      final restored = _restorePath(product, field, removedPath);
      await _persist(ref, restored);
      onChanged(restored);
    });
  }

  Future<void> _persist(WidgetRef ref, Product updated) async {
    await ref.read(databaseProvider).insertProduct(updated);
  }
}
