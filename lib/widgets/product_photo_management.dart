import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/utils/camera_permission_dialog.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';

/// Edits the local photos of a manual product on the detail screen.
///
/// Composes [ProductPhotoTile] tiles for the nutrition, ingredients, and
/// product slots, reusing the picker, camera-permission dialog, preview, and
/// undo flows from the add-product form. Every change is forwarded to
/// [onChanged] so the parent can persist the updated photo paths.
///
/// Physical file deletion is deferred to dispose via
/// [ProductImageService.cleanupUncommitted]: a remove-then-undo inside this
/// widget restores a live file, and files are only reclaimed once the widget
/// (and its undo window) is gone.
class ProductPhotoManagement extends ConsumerStatefulWidget {
  /// Creates a [ProductPhotoManagement] for [barcode] starting from
  /// [initialSlots].
  const ProductPhotoManagement({
    required this.barcode,
    required this.initialSlots,
    required this.onChanged,
    super.key,
  });

  /// The product barcode, used for managed file names.
  final String barcode;

  /// The initial photo slots, typically the persisted product's paths.
  final ProductPhotoSlots initialSlots;

  /// Called whenever the slots change so the parent can persist the product.
  final ValueChanged<ProductPhotoSlots> onChanged;

  @override
  ConsumerState<ProductPhotoManagement> createState() =>
      _ProductPhotoManagementState();
}

class _ProductPhotoManagementState
    extends ConsumerState<ProductPhotoManagement> {
  late ProductPhotoSlots _slots;

  late final ProductImageService _imageService;

  @override
  void initState() {
    super.initState();
    _slots = widget.initialSlots;
    _imageService = ref.read(productImageServiceProvider);
  }

  @override
  void didUpdateWidget(covariant ProductPhotoManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSlots != widget.initialSlots) {
      _slots = widget.initialSlots;
    }
  }

  @override
  void dispose() {
    unawaited(
      _imageService.cleanupUncommitted(
        _slots,
        barcode: widget.barcode,
        committedPaths: _committedPaths,
      ),
    );
    super.dispose();
  }

  /// The paths currently persisted by [ProductPhotoManagement.onChanged];
  /// dispose cleanup must never delete these.
  Set<String> get _committedPaths => {
    if (_slots.nutrition != null) _slots.nutrition!.path,
    if (_slots.ingredients != null) _slots.ingredients!.path,
    if (_slots.product != null) _slots.product!.path,
  };

  File? _imageFor(ImageField field) => _slots.forField(field);

  String _labelFor(ImageField field) {
    final l10n = AppLocalizations.of(context)!;
    switch (field) {
      case ImageField.nutrition:
        return l10n.nutritionTableImage;
      case ImageField.ingredients:
        return l10n.ingredientsImage;
      case ImageField.product:
        return l10n.productImage;
    }
  }

  Future<void> _chooseSource(ImageField field) async {
    final source = await showPhotoSourceChooser(context);
    if (source == null || !mounted) return;
    await _pick(field, source);
  }

  Future<void> _pick(ImageField field, PhotoSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(productPhotoPickerProvider).pick(source);
    if (!mounted) return;
    switch (result) {
      case PhotoPicked(:final file):
        final updated = await _imageService.assign(
          _slots,
          field,
          file,
          barcode: widget.barcode,
        );
        if (!mounted) return;
        setState(() => _slots = updated);
        widget.onChanged(updated);
        if (updated.forField(field) == null) {
          SnackbarHelper.showWarning(context, l10n.couldNotAttachImage);
        }
      case PhotoPermissionDenied():
        await showCameraPermissionDialog(context);
      case PhotoPickCancelled():
        break;
    }
  }

  Future<void> _openPreview(ImageField field) async {
    final image = _imageFor(field);
    if (image == null) return;
    final action = await Navigator.of(context).push<PhotoPreviewAction>(
      MaterialPageRoute<PhotoPreviewAction>(
        builder: (_) => ProductPhotoPreview(
          image: image,
          label: _labelFor(field),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case PhotoPreviewAction.close:
        break;
      case PhotoPreviewAction.retake:
        await _pick(field, PhotoSource.camera);
      case PhotoPreviewAction.replace:
        await _chooseSource(field);
      case PhotoPreviewAction.delete:
        _removeImage(field);
    }
  }

  void _removeImage(ImageField field) {
    final removed = _imageFor(field);
    setState(() => _slots = _imageService.remove(_slots, field));
    widget.onChanged(_slots);
    final l10n = AppLocalizations.of(context)!;
    SnackbarHelper.showUndo(
      context,
      l10n.photoRemoved,
      () {
        // Only restore when the slot is still empty so an older photo is
        // never restored over a newer pick.
        if (mounted && _imageFor(field) == null) {
          setState(() => _slots = _slots.withField(field, removed));
          widget.onChanged(_slots);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.captureImages,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        ProductPhotoTile(
          label: _labelFor(ImageField.nutrition),
          image: _slots.nutrition,
          onAdd: () => _chooseSource(ImageField.nutrition),
          onTap: () => _openPreview(ImageField.nutrition),
          onDelete: () => _removeImage(ImageField.nutrition),
        ),
        ProductPhotoTile(
          label: _labelFor(ImageField.ingredients),
          image: _slots.ingredients,
          onAdd: () => _chooseSource(ImageField.ingredients),
          onTap: () => _openPreview(ImageField.ingredients),
          onDelete: () => _removeImage(ImageField.ingredients),
        ),
        ProductPhotoTile(
          label: _labelFor(ImageField.product),
          image: _slots.product,
          onAdd: () => _chooseSource(ImageField.product),
          onTap: () => _openPreview(ImageField.product),
          onDelete: () => _removeImage(ImageField.product),
        ),
      ],
    );
  }
}
