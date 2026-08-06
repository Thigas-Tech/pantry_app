import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/utils/camera_permission_dialog.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';
import 'package:pantry_app/widgets/submission_progress_sheet.dart';

/// A form screen for manually entering product details.
///
/// Used when a barcode is not found in Open Food Facts, allowing the user
/// to enter name, brand, category, nutrition, ingredients, and capture
/// photos of the nutrition table, ingredients list, and product packaging.
class AddProductScreen extends ConsumerStatefulWidget {
  /// Creates an [AddProductScreen] for the given [barcode].
  const AddProductScreen({required this.barcode, super.key});

  /// The barcode that was scanned/entered.
  final String barcode;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  String _brand = '';
  String _category = '';
  String _servingSize = '';
  String _ingredients = '';

  String _energyKcal = '';
  String _proteinG = '';
  String _carbsG = '';
  String _fatG = '';
  String _fiberG = '';
  String _saltG = '';

  ProductPhotoSlots _slots = const ProductPhotoSlots.empty();

  late final ProductImageService _imageService;

  /// Managed photo paths already committed to a saved [Product]; dispose
  /// cleanup must never delete these.
  final Set<String> _committedPaths = <String>{};

  @override
  void initState() {
    super.initState();
    _imageService = ref.read(productImageServiceProvider);
  }

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
    final l10n = AppLocalizations.of(context)!;
    SnackbarHelper.showUndo(
      context,
      l10n.photoRemoved,
      () {
        // Only restore when the slot is still empty so an older photo is
        // never restored over a newer pick.
        if (mounted && _imageFor(field) == null) {
          setState(() => _slots = _slots.withField(field, removed));
        }
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      logInfo('Add-product form validation failed');
      return;
    }
    _formKey.currentState!.save();

    final saved = await _imageService.save(_slots, barcode: widget.barcode);
    _committedPaths.addAll(
      [
        saved.nutrition,
        saved.ingredients,
        saved.product,
      ].whereType<String>(),
    );

    final product = Product(
      barcode: widget.barcode,
      name: _name,
      brand: _brand.isNotEmpty ? _brand : null,
      category: _category.isNotEmpty ? _category : null,
      ingredients: _ingredients.isNotEmpty ? _ingredients : null,
      servingSize: _servingSize.isNotEmpty ? _servingSize : null,
      energyKcal: double.tryParse(_energyKcal),
      proteinG: double.tryParse(_proteinG),
      carbsG: double.tryParse(_carbsG),
      fatG: double.tryParse(_fatG),
      fiberG: double.tryParse(_fiberG),
      saltG: double.tryParse(_saltG),
      lastSynced: DateTime.now().millisecondsSinceEpoch,
      source: 'manual',
      nutritionImagePath: saved.nutrition,
      ingredientsImagePath: saved.ingredients,
      productImagePath: saved.product,
    );
    logInfo('Manual product entry saved: ${product.name}');

    if (!mounted) return;
    // Pop the screen first so the progress sheet (pushed afterwards on the
    // root navigator) appears above whatever screen the user lands on. The
    // submission runs through the durable notifier and continues even if the
    // user navigates away; the sheet observes the notifier state and shows
    // the terminal result when the run finishes.
    final notifier = ref.read(productSubmissionNotifierProvider.notifier);
    Navigator.of(context).pop(product);
    unawaited(showSubmissionProgressSheet(context, barcode: product.barcode));
    unawaited(_persistAndSubmit(product, notifier));
  }

  /// Persists [product] locally, then submits it to Open Food Facts through
  /// the durable [notifier].
  ///
  /// Runs detached from the save flow so the form can pop immediately; a
  /// failure to cache locally is logged and never blocks the submission.
  Future<void> _persistAndSubmit(
    Product product,
    ProductSubmissionNotifier notifier,
  ) async {
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.cacheProduct(product);
    } on Object catch (e) {
      logError('Failed to cache product locally: $e');
    }
    await notifier.submit(product);
  }

  @override
  void dispose() {
    // Remove photos the form never committed to a saved product. Files already
    // committed on save are listed in [_committedPaths] and preserved.
    unawaited(
      _imageService.cleanupUncommitted(
        _slots,
        barcode: widget.barcode,
        committedPaths: _committedPaths,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.enterProductDetails)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.productNameLabel,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: l10n.brandLabel),
                onSaved: (v) => _brand = v ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.categoryLabel,
                ),
                onSaved: (v) => _category = v ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.servingSize,
                  hintText: l10n.servingSizeHint,
                ),
                onSaved: (v) => _servingSize = v ?? '',
              ),
              const SizedBox(height: 16),
              Text(
                l10n.nutritionInfo,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _nutritionField(
                l10n.energy,
                (v) => _energyKcal = v,
                'kcal',
              ),
              _nutritionField(l10n.protein, (v) => _proteinG = v, 'g'),
              _nutritionField(l10n.carbs, (v) => _carbsG = v, 'g'),
              _nutritionField(l10n.fat, (v) => _fatG = v, 'g'),
              _nutritionField(l10n.fiber, (v) => _fiberG = v, 'g'),
              _nutritionField(l10n.salt, (v) => _saltG = v, 'g'),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: l10n.ingredients),
                maxLines: 3,
                onSaved: (v) => _ingredients = v ?? '',
              ),
              const SizedBox(height: 16),
              Text(
                l10n.captureImages,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _imageTile(
                l10n.nutritionTableImage,
                _slots.nutrition,
                ImageField.nutrition,
              ),
              _imageTile(
                l10n.ingredientsImage,
                _slots.ingredients,
                ImageField.ingredients,
              ),
              _imageTile(
                l10n.productImage,
                _slots.product,
                ImageField.product,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(l10n.saveProduct),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutritionField(
    String label,
    ValueSetter<String> onSaved,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label),
          ),
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: unit,
                isDense: true,
              ),
              onSaved: (v) => onSaved(v ?? ''),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageTile(String label, File? image, ImageField field) {
    return ProductPhotoTile(
      label: label,
      image: image,
      onAdd: () => _chooseSource(field),
      onTap: () => _openPreview(field),
      onDelete: () => _removeImage(field),
    );
  }
}
