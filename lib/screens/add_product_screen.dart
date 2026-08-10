import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_nutrient.dart';
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
import 'package:pantry_app/utils/nutrient_catalog.dart';
import 'package:pantry_app/utils/nutrient_conversion.dart';
import 'package:pantry_app/utils/off_units.dart';
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

/// State for one nutrition row in the manual entry form.
///
/// Holds the row's own text controller so dynamic rows keep their input and
/// focus across rebuilds, plus the currently selected unit and the canonical
/// unit the value is converted to before storage. Core rows fix the canonical
/// unit (energy in kcal, macros in g) while additional rows use the
/// nutrient's typical unit.
class _NutrientRowState {
  _NutrientRowState({
    required this.offTag,
    required this.label,
    required this.unitOptions,
    required this.unit,
    required this.canonicalUnit,
  });

  /// Stable identifier used as the widget key and as the stored offTag for
  /// additional rows.
  final String offTag;

  /// The localized row label.
  final String label;

  /// The unit choices offered by the row's dropdown.
  final List<String> unitOptions;

  /// The currently selected unit (editor-only for core rows).
  String unit;

  /// The canonical unit the value is converted to before storage.
  final String canonicalUnit;

  /// Owns the text entered by the user so it survives list rebuilds.
  final TextEditingController controller = TextEditingController();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  String _brand = '';
  String _category = '';
  String _servingSizeAmount = '';
  String _servingSizeUnit = 'g';
  String _ingredients = '';

  /// The six fixed nutrition rows (energy, protein, carbs, fat, fiber, salt).
  ///
  /// Lazily initialized because the labels come from [AppLocalizations],
  /// which is not available during [initState].
  List<_NutrientRowState>? _coreRows;

  /// The dynamically added nutrient rows (beyond the six core ones).
  final List<_NutrientRowState> _additionalRows = [];

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

  /// Lazily builds and caches the six fixed core nutrition rows.
  List<_NutrientRowState> get _coreRowsOrBuild {
    final existing = _coreRows;
    if (existing != null) return existing;
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      _NutrientRowState(
        offTag: 'energy',
        label: l10n.energy,
        unitOptions: OffUnitCatalog.energyUnits,
        unit: 'kcal',
        canonicalUnit: 'kcal',
      ),
      _NutrientRowState(
        offTag: 'protein',
        label: l10n.protein,
        unitOptions: OffUnitCatalog.nutrientWeightUnits,
        unit: 'g',
        canonicalUnit: 'g',
      ),
      _NutrientRowState(
        offTag: 'carbs',
        label: l10n.carbs,
        unitOptions: OffUnitCatalog.nutrientWeightUnits,
        unit: 'g',
        canonicalUnit: 'g',
      ),
      _NutrientRowState(
        offTag: 'fat',
        label: l10n.fat,
        unitOptions: OffUnitCatalog.nutrientWeightUnits,
        unit: 'g',
        canonicalUnit: 'g',
      ),
      _NutrientRowState(
        offTag: 'fiber',
        label: l10n.fiber,
        unitOptions: OffUnitCatalog.nutrientWeightUnits,
        unit: 'g',
        canonicalUnit: 'g',
      ),
      _NutrientRowState(
        offTag: 'salt',
        label: l10n.salt,
        unitOptions: OffUnitCatalog.nutrientWeightUnits,
        unit: 'g',
        canonicalUnit: 'g',
      ),
    ];
    _coreRows = rows;
    return rows;
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

    final additionalNutrients = <ProductNutrient>[
      for (final row in _additionalRows)
        if (double.tryParse(row.controller.text.trim())
            case final double parsed)
          ProductNutrient(
            offTag: row.offTag,
            value: NutrientConverter.convert(
              parsed,
              row.unit,
              row.canonicalUnit,
            ),
            unit: row.canonicalUnit,
          ),
    ];

    final product = Product(
      barcode: widget.barcode,
      name: _name,
      brand: _brand.isNotEmpty ? _brand : null,
      category: _category.isNotEmpty ? _category : null,
      ingredients: _ingredients.isNotEmpty ? _ingredients : null,
      servingSize: _servingSizeAmount.trim().isNotEmpty
          ? _formattedServingSize
          : null,
      energyKcal: _coreValue(_coreRowsOrBuild[0]),
      proteinG: _coreValue(_coreRowsOrBuild[1]),
      carbsG: _coreValue(_coreRowsOrBuild[2]),
      fatG: _coreValue(_coreRowsOrBuild[3]),
      fiberG: _coreValue(_coreRowsOrBuild[4]),
      saltG: _coreValue(_coreRowsOrBuild[5]),
      additionalNutrients: additionalNutrients,
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

  /// Builds the "N unit" serving-size string stored on the product.
  ///
  /// Whole amounts are rendered without a trailing decimal (100 to "100 g",
  /// 1.5 to "1.5 g") so the value round-trips cleanly through the quantity
  /// parser and stays tidy for Open Food Facts.
  String get _formattedServingSize {
    final amount = double.tryParse(_servingSizeAmount.trim());
    if (amount == null) return '';
    final text = amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toString();
    return '$text $_servingSizeUnit';
  }

  /// Returns the canonical-unit value of a core nutrition row, or null when
  /// the row is empty.
  ///
  /// The user may enter the value in any unit offered by the row dropdown
  /// (e.g. protein in mg); the value is converted to the row's canonical
  /// unit (grams for macros, kcal for energy) before it is stored on the
  /// product.
  double? _coreValue(_NutrientRowState row) {
    final text = row.controller.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return null;
    return NutrientConverter.convert(parsed, row.unit, row.canonicalUnit);
  }

  /// Validates the optional serving-size amount.
  ///
  /// An empty amount is valid (the product is saved without a serving size).
  /// Otherwise the amount must parse as a positive number.
  String? _validateServingSize(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return AppLocalizations.of(context)!.enterPositiveNumber;
    }
    return null;
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
    if (_coreRows case final rows?) {
      for (final row in rows) {
        row.controller.dispose();
      }
    }
    for (final row in _additionalRows) {
      row.controller.dispose();
    }
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.servingSize,
                        hintText: l10n.servingSizeHint,
                      ),
                      validator: _validateServingSize,
                      onSaved: (v) => _servingSizeAmount = v ?? '',
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      key: const ValueKey('serving-size-unit'),
                      initialValue: _servingSizeUnit,
                      items: [
                        for (final unit in OffUnitCatalog.sdkQuantityUnits)
                          DropdownMenuItem(
                            value: unit,
                            child: Text(l10n.localizeUnit(unit)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _servingSizeUnit = v!),
                      decoration: InputDecoration(labelText: l10n.unitLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.nutritionInfo,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final row in _coreRowsOrBuild) _nutritionField(row),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addNutrient,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addNutrient),
                ),
              ),
              for (final row in _additionalRows)
                _nutritionField(row, onRemove: () => _removeNutrient(row)),
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

  /// Builds one nutrition editor row for [row].
  ///
  /// The row carries a value text field, a unit dropdown bound to the row's
  /// selected unit, and an optional remove action for additional rows. The
  /// row widget is keyed by its offTag so dynamic rows keep focus and input
  /// across rebuilds.
  Widget _nutritionField(
    _NutrientRowState row, {
    VoidCallback? onRemove,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        key: ValueKey(row.offTag),
        children: [
          SizedBox(
            width: 100,
            child: Text(row.label),
          ),
          Expanded(
            child: TextFormField(
              controller: row.controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0.0',
                isDense: true,
              ),
              validator: _validateNutrient,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: DropdownButtonFormField<String>(
              initialValue: row.unit,
              items: [
                for (final unit in row.unitOptions)
                  DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  ),
              ],
              onChanged: (v) => setState(() => row.unit = v ?? row.unit),
              decoration: const InputDecoration(isDense: true),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.removeNutrient,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }

  /// Validates an optional nutrition value.
  ///
  /// An empty value is valid (the nutrient is omitted). Otherwise the value
  /// must parse as a non-negative finite number; negative values are
  /// rejected so nutrition data never goes out as nonsensical.
  String? _validateNutrient(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed.isNaN || !parsed.isFinite || parsed < 0) {
      return AppLocalizations.of(context)!.enterValidNumber;
    }
    return null;
  }

  /// Opens the nutrient picker and adds the chosen nutrient as a new row.
  ///
  /// The picker lists the curated nutrients that are not already present as
  /// an additional row (the six core rows are never offered again). Each new
  /// row defaults to the nutrient's canonical unit.
  Future<void> _addNutrient() async {
    final l10n = AppLocalizations.of(context)!;
    final addedTags = {
      for (final row in _coreRowsOrBuild) row.offTag,
      for (final row in _additionalRows) row.offTag,
    };
    final available = [
      for (final nutrient in NutrientCatalog.nutrients)
        if (!addedTags.contains(nutrient.offTag)) nutrient,
    ];
    final selected = await showModalBottomSheet<off.Nutrient>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.chooseNutrient,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final nutrient in available)
              ListTile(
                title: Text(l10n.localizeNutrient(nutrient)),
                onTap: () => Navigator.of(context).pop(nutrient),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _additionalRows.add(
        _NutrientRowState(
          offTag: selected.offTag,
          label: l10n.localizeNutrient(selected),
          unitOptions: NutrientCatalog.allowedUnits(selected),
          unit: NutrientCatalog.canonicalUnitFor(selected),
          canonicalUnit: NutrientCatalog.canonicalUnitFor(selected),
        ),
      );
    });
  }

  /// Removes an additional nutrient row from the editor.
  void _removeNutrient(_NutrientRowState row) {
    setState(() => _additionalRows.remove(row));
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
