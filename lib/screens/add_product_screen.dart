import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/utils/camera_permission_dialog.dart';
import 'package:pantry_app/utils/gallery_permission_dialog.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/utils/submission_error_label.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';

/// A form screen for manually entering product details.
///
/// Used when a barcode is not found in Open Food Facts, allowing the user
/// to enter name, brand, category, nutrition, ingredients, and capture
/// photos of the nutrition table, ingredients list, and product packaging.
class AddProductScreen extends ConsumerStatefulWidget {
  /// Creates an [AddProductScreen] for the given [barcode].
  ///
  /// Set [submitToOff] to true to give the "Submit to Open Food Facts"
  /// action visual prominence; both actions are always available.
  const AddProductScreen({
    required this.barcode,
    this.submitToOff = false,
    super.key,
  });

  /// The barcode that was scanned/entered.
  final String barcode;

  /// Whether the submit-to-Open-Food-Facts action is the primary button.
  final bool submitToOff;

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

  /// The product cached by the last save; used to re-submit on retry.
  Product? _submittedProduct;

  @override
  void initState() {
    super.initState();
    _imageService = ref.read(productImageServiceProvider);
    // Clear any progress left by a previous submission. Deferred until after
    // the first frame because providers cannot be modified during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(productSubmissionProvider.notifier).clear();
      }
    });
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

  /// Validates the form, saves photos, builds the product, and caches it
  /// locally.
  ///
  /// Returns null when validation fails. The built product is cached via
  /// [ProductRepository.cacheProduct] so both save and submit actions keep
  /// the entry in the local inventory.
  Future<Product?> _buildProduct() async {
    if (!_formKey.currentState!.validate()) {
      logInfo('Add-product form validation failed');
      return null;
    }
    _formKey.currentState!.save();
    final languageCode = Localizations.localeOf(context).languageCode;

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
      languageCode: languageCode,
      nutritionImagePath: saved.nutrition,
      ingredientsImagePath: saved.ingredients,
      productImagePath: saved.product,
    );
    logInfo('Manual product entry saved: ${product.name}');

    await _cacheLocally(product);
    return product;
  }

  /// Saves the product to the local inventory only.
  Future<void> _saveLocally() async {
    final product = await _buildProduct();
    if (product == null || !mounted) return;
    Navigator.of(context).pop(product);
  }

  /// Caches the product locally and submits it to Open Food Facts.
  Future<void> _submitToOff() async {
    final notifier = ref.read(productSubmissionProvider.notifier);
    if (notifier.isSubmitting) {
      logInfo('Add-product submit ignored while a submission is running');
      return;
    }

    final product = await _buildProduct();
    if (product == null || !mounted) return;
    _submittedProduct = product;

    // The screen stays open while the submission runs so progress is
    // visible. On success it pops; on failure the panel offers a retry.
    await notifier.submit(product);

    if (!mounted) return;
    if (ref.read(productSubmissionProvider)?.step == SubmissionStep.completed) {
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showInfo(context, l10n.submissionSuccess);
      Navigator.of(context).pop(product);
    }
  }

  Future<void> _cacheLocally(Product product) async {
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.cacheProduct(product);
    } on Object catch (e) {
      logError('Failed to cache product locally: $e');
    }
  }

  Future<void> _retrySubmission() async {
    final product = _submittedProduct;
    if (product == null) return;
    final notifier = ref.read(productSubmissionProvider.notifier);
    await notifier.submit(product);
    if (!mounted) return;
    if (ref.read(productSubmissionProvider)?.step == SubmissionStep.completed) {
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showInfo(context, l10n.submissionSuccess);
      Navigator.of(context).pop(product);
    }
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
    final progress = ref.watch(productSubmissionProvider);
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
              _actionButtons(l10n),
              if (progress != null) ...[
                const SizedBox(height: 16),
                _submissionPanel(progress),
              ],
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

  /// Builds the save and submit action buttons.
  ///
  /// Both actions are always available so the local save remains a fallback
  /// when Open Food Facts rejects a submission (e.g. a duplicate). The
  /// [AddProductScreen.submitToOff] flag decides which one is rendered as the
  /// primary filled button.
  Widget _actionButtons(AppLocalizations l10n) {
    final submitPrimary = widget.submitToOff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (submitPrimary)
          OutlinedButton.icon(
            onPressed: _saveLocally,
            icon: const Icon(Icons.save),
            label: Text(l10n.saveToInventory),
          )
        else
          ElevatedButton.icon(
            onPressed: _saveLocally,
            icon: const Icon(Icons.save),
            label: Text(l10n.saveToInventory),
          ),
        const SizedBox(height: 8),
        if (submitPrimary)
          ElevatedButton.icon(
            onPressed: _submitToOff,
            icon: const Icon(Icons.cloud_upload),
            label: Text(l10n.submitProductToOff),
          )
        else
          OutlinedButton.icon(
            onPressed: _submitToOff,
            icon: const Icon(Icons.cloud_upload),
            label: Text(l10n.submitProductToOff),
          ),
      ],
    );
  }

  /// Builds the inline submission status shown under the save button.
  ///
  /// Shows an indeterminate or determinate [LinearProgressIndicator] while
  /// the submission runs and a localized message with a retry button once
  /// it reaches a terminal state that can be retried.
  Widget _submissionPanel(SubmissionProgress progress) {
    final l10n = AppLocalizations.of(context)!;
    final (text, value) = switch (progress.step) {
      SubmissionStep.checking => (l10n.preparingSubmission, null),
      SubmissionStep.submittingMetadata => (l10n.submittingMetadata, null),
      SubmissionStep.uploadingFront ||
      SubmissionStep.uploadingIngredients ||
      SubmissionStep.uploadingNutrition => (
        l10n.uploadingPhotos(
          progress.completedImageCount + 1,
          progress.totalImageCount,
        ),
        progress.totalImageCount > 0
            ? (progress.completedImageCount + 1) / progress.totalImageCount
            : null,
      ),
      SubmissionStep.completed => (l10n.submissionSuccess, 1.0),
      SubmissionStep.partiallyCompleted => (
        l10n.submissionPartiallyCompleted,
        null,
      ),
      SubmissionStep.failed => (
        submissionErrorLabel(l10n, progress.errorCategory),
        null,
      ),
    };
    final showBar =
        progress.isActive || progress.step == SubmissionStep.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(text)),
                if (progress.retryAvailable)
                  TextButton(
                    onPressed: _retrySubmission,
                    child: Text(l10n.retryNow),
                  ),
              ],
            ),
            if (showBar) ...[
              const SizedBox(height: 8),
              ProgressIndicatorHelper.build(
                type: ProgressIndicatorType.linear,
                value: value,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
