import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/utils/camera_permission_dialog.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';
import 'package:path_provider/path_provider.dart';

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

  File? _nutritionImage;
  File? _ingredientsImage;
  File? _productImage;

  File? _imageFor(ImageField field) {
    switch (field) {
      case ImageField.nutrition:
        return _nutritionImage;
      case ImageField.ingredients:
        return _ingredientsImage;
      case ImageField.product:
        return _productImage;
    }
  }

  void _setImage(ImageField field, File? file) {
    setState(() {
      switch (field) {
        case ImageField.nutrition:
          _nutritionImage = file;
        case ImageField.ingredients:
          _ingredientsImage = file;
        case ImageField.product:
          _productImage = file;
      }
    });
  }

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
    final result = await ref.read(productPhotoPickerProvider).pick(source);
    if (!mounted) return;
    switch (result) {
      case PhotoPicked(:final file):
        _setImage(field, file);
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
    _setImage(field, null);
    final l10n = AppLocalizations.of(context)!;
    SnackbarHelper.showUndo(
      context,
      l10n.photoRemoved,
      () {
        // Only restore when the slot is still empty so an older photo is
        // never restored over a newer pick.
        if (mounted && _imageFor(field) == null) {
          _setImage(field, removed);
        }
      },
    );
  }

  Future<String?> _saveImageToStorage(
    File? image,
    String barcode,
    String suffix,
  ) async {
    if (image == null) return null;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/product_images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final targetPath = '${dir.path}/${barcode}_$suffix.jpg';
    await image.copy(targetPath);
    return targetPath;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      logInfo('Add-product form validation failed');
      return;
    }
    _formKey.currentState!.save();

    final nutritionPath = await _saveImageToStorage(
      _nutritionImage,
      widget.barcode,
      'nutrition',
    );
    final ingredientsPath = await _saveImageToStorage(
      _ingredientsImage,
      widget.barcode,
      'ingredients',
    );
    final productPath = await _saveImageToStorage(
      _productImage,
      widget.barcode,
      'product',
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
      nutritionImagePath: nutritionPath,
      ingredientsImagePath: ingredientsPath,
      productImagePath: productPath,
    );
    logInfo('Manual product entry saved: ${product.name}');

    if (!mounted) return;
    Navigator.of(context).pop(product);

    // Background submit to OFF (fire-and-forget after local save).
    unawaited(_cacheAndSubmit(product));
  }

  Future<void> _cacheAndSubmit(Product product) async {
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.cacheProduct(product);
    } on Object catch (e) {
      logError('Failed to cache product locally: $e');
    }
    try {
      final service = ref.read(productSubmissionServiceProvider);
      await service.submitProduct(product);
    } on Object catch (e) {
      logError('Failed to submit product to OFF: $e');
    }
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
                _nutritionImage,
                ImageField.nutrition,
              ),
              _imageTile(
                l10n.ingredientsImage,
                _ingredientsImage,
                ImageField.ingredients,
              ),
              _imageTile(
                l10n.productImage,
                _productImage,
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
