import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/unit_conversion.dart';
import 'package:pantry_app/utils/unit_resolver.dart';
import 'package:pantry_app/screens/product_picker_screen.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/quantity_parser.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// Tracks mutable state for a single ingredient row in the form.
class _IngredientEntry {
  _IngredientEntry({required this.nameController, this.barcode})
    : quantityController = TextEditingController(text: '1.0'),
      unit = 'pieces';

  _IngredientEntry.fromIngredient(RecipeIngredient ingredient)
    : nameController = TextEditingController(text: ingredient.name),
      barcode = ingredient.barcode,
      quantityController = TextEditingController(
        text: ingredient.quantity.toString(),
      ),
      unit = ingredient.unit;

  final TextEditingController nameController;
  final TextEditingController quantityController;
  String? barcode;
  String unit;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}

/// A form screen for creating or editing a recipe.
///
/// When [existingRecipeId] is null the screen is in create mode; otherwise
/// it loads the existing recipe data for editing.
class RecipeFormScreen extends ConsumerStatefulWidget {
  /// Creates a [RecipeFormScreen].
  ///
  /// Pass [existingRecipeId] to edit an existing recipe, or omit for create.
  const RecipeFormScreen({super.key, this.existingRecipeId});

  /// The ID of an existing recipe to edit, or null for a new recipe.
  final int? existingRecipeId;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _servingsController = TextEditingController();
  final List<_IngredientEntry> _ingredients = [];
  final _imagePicker = ImagePicker();
  String _imagePath = '';
  bool _isSaving = false;
  bool _isLoading = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecipeId != null) {
      _isLoading = true;
      unawaited(_loadRecipe());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    for (final entry in _ingredients) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    final db = ref.read(databaseProvider);
    final recipe = await db.getRecipe(widget.existingRecipeId!);
    final ingredients = await db.getRecipeIngredients(
      widget.existingRecipeId!,
    );

    if (!mounted) return;

    setState(() {
      if (recipe != null) {
        _nameController.text = recipe.name;
        _instructionsController.text = recipe.instructions;
        if (recipe.servings > 0) {
          _servingsController.text = recipe.servings.toString();
        }
        _imagePath = recipe.imagePath;
      }
      for (final ing in ingredients) {
        _ingredients.add(_IngredientEntry.fromIngredient(ing));
      }
      _isLoading = false;
    });
  }

  ({double quantity, String unit}) _prefillFromProduct(
    Product product, {
    required Settings settings,
  }) {
    double metricQty;
    String metricUnit;

    if (product.productType == ProductType.produce) {
      final parsed = QuantityParser.parseUsda(
        usdaServingAmount: product.usdaServingAmount,
        usdaServingUnit: product.usdaServingUnit,
        usdaGramWeight: product.usdaGramWeight,
      );
      if (parsed != null) {
        metricQty = parsed.amount;
        metricUnit = parsed.unit;
      } else {
        return (quantity: 1.0, unit: 'pieces');
      }
    } else {
      final parsed = QuantityParser.parseServing(
        servingQuantity: product.servingQuantity,
        servingSize: product.servingSize,
      );
      if (parsed != null) {
        metricQty = parsed.amount;
        metricUnit = parsed.unit;
      } else {
        return (quantity: 1.0, unit: 'pieces');
      }
    }

    final system = UnitResolver.systemFor(
      settings: settings,
      context: UnitContext.recipeIngredients,
    );

    if (system == UnitSystem.imperial) {
      final converted = UnitConverter.displayUnit(
        metricQty,
        metricUnit,
        UnitSystem.imperial,
        weightPref: settings.preferredWeightUnit,
        volumePref: settings.preferredVolumeUnit,
      );
      return (quantity: converted.quantity, unit: converted.unit);
    }

    return (quantity: metricQty, unit: metricUnit);
  }

  void _addIngredient({
    String? name,
    String? barcode,
    Product? product,
    double? quantity,
    String? unit,
    Settings? settings,
  }) {
    setState(() {
      if (barcode != null && barcode.isNotEmpty) {
        final existingIndex = _ingredients.indexWhere(
          (e) => e.barcode == barcode,
        );
        if (existingIndex >= 0) {
          final currentQty =
              double.tryParse(
                _ingredients[existingIndex].quantityController.text,
              ) ??
              0.0;
          final addQty =
              quantity ??
              (product != null
                  ? _prefillFromProduct(
                      product,
                      settings: settings ?? const Settings(),
                    ).quantity
                  : 1.0);
          _ingredients[existingIndex].quantityController.text =
              (currentQty + addQty).toStringAsFixed(1);
          return;
        }
      }
      final prefill = product != null
          ? _prefillFromProduct(
              product,
              settings: settings ?? const Settings(),
            )
          : (quantity: quantity ?? 1.0, unit: unit ?? 'pieces');
      final qty = prefill.quantity;
      final unt = prefill.unit;
      _ingredients.add(
        _IngredientEntry(
          nameController: TextEditingController(text: name ?? ''),
          barcode: barcode,
        ),
      );
      _ingredients.last.quantityController.text = qty.toString();
      _ingredients.last.unit = unt;
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
    });
  }

  Future<void> _showPantryPicker() async {
    final db = ref.read(databaseProvider);
    final inventoryId = ref.read(activeInventoryProvider);
    final items = await db.getDistinctProductsFromInventory(
      inventoryId: inventoryId,
    );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final selected = <bool>[];
    for (var i = 0; i < items.length; i++) {
      selected.add(false);
    }

    await BottomSheetHelper.show<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: BottomSheetHelper.bottomInset(ctx),
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectFromPantry,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final name =
                        item['name'] as String? ?? item['barcode'] as String;
                    return CheckboxListTile(
                      title: Text(name),
                      subtitle: item['barcode'] != null
                          ? Text(item['barcode'] as String)
                          : null,
                      value: selected[i],
                      onChanged: (v) {
                        setSheetState(() {
                          selected[i] = v ?? false;
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                  child: Text(l10n.addSelected),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    final repo = ref.read(productRepositoryProvider);
    for (var i = 0; i < items.length; i++) {
      if (selected[i]) {
        final item = items[i];
        final barcode = item['barcode'] as String?;
        Product? product;
        if (barcode != null && barcode.isNotEmpty) {
          product = await repo.getProductFromCache(barcode);
        }
        final settings = ref.read(settingsProvider);
        _addIngredient(
          name: item['name'] as String? ?? item['barcode'] as String,
          barcode: item['barcode'] as String?,
          product: product,
          settings: settings,
        );
      }
    }
  }

  Future<void> _showProductSearch() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const ProductPickerScreen()),
    );
    if (product != null && mounted) {
      final repo = ref.read(productRepositoryProvider);
      final cached = await repo.getProductFromCache(product.barcode);
      final settings = ref.read(settingsProvider);
      _addIngredient(
        name: product.name,
        barcode: product.barcode,
        product: cached ?? product,
        settings: settings,
      );
    }
  }

  Future<void> _pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file != null && mounted) {
      setState(() {
        _imagePath = file.path;
        _isDirty = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final settings = ref.read(settingsProvider);
      final recipeSystem = UnitResolver.systemFor(
        settings: settings,
        context: UnitContext.recipeIngredients,
      );
      final ingredients = _ingredients.map(
        (e) {
          var qty = double.tryParse(e.quantityController.text) ?? 1.0;
          var unit = e.unit;
          // Convert back to metric before saving if system is imperial
          if (recipeSystem == UnitSystem.imperial &&
              !UnitResolver.isMetricUnit(unit)) {
            final converted = UnitConverter.displayUnit(
              qty,
              unit,
              UnitSystem.metric,
            );
            qty = converted.quantity;
            unit = converted.unit;
          }
          return RecipeIngredient(
            recipeId: widget.existingRecipeId ?? 0,
            barcode: e.barcode,
            name: e.nameController.text.trim(),
            quantity: qty,
            unit: unit,
          );
        },
      ).toList();

      await saveRecipe(
        ref,
        existingRecipeId: widget.existingRecipeId,
        name: _nameController.text.trim(),
        instructions: _instructionsController.text.trim(),
        servings: int.tryParse(_servingsController.text) ?? 0,
        imagePath: _imagePath,
        ingredients: ingredients,
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showInfo(context, l10n.recipeSaved);
      Navigator.pop(context, true);
    } on Exception {
      // Validation errors are shown inline via FormState.
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onBackPressed() {
    if (_isDirty) {
      final l10n = AppLocalizations.of(context)!;
      unawaited(
        showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.confirmDiscard),
            content: Text(l10n.confirmDiscardContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.no),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.yes),
              ),
            ],
          ),
        ).then((discard) {
          if (discard == true && mounted) {
            Navigator.pop(context);
          }
        }),
      );
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final recipeSystem = UnitResolver.systemFor(
      settings: settings,
      context: UnitContext.recipeIngredients,
    );
    final dropdownUnits = UnitResolver.unitsForSystem(recipeSystem);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingRecipeId != null
                ? l10n.editRecipe
                : l10n.registerRecipe,
          ),
        ),
        body: _isLoading
            ? Center(child: ProgressIndicatorHelper.build())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.recipeName,
                        hintText: l10n.recipeNameHint,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.recipeNameRequired;
                        }
                        return null;
                      },
                      onChanged: (_) => _isDirty = true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        labelText: l10n.recipeInstructions,
                        hintText: l10n.recipeInstructionsHint,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      onChanged: (_) => _isDirty = true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _servingsController,
                      decoration: InputDecoration(
                        labelText: l10n.servings,
                        hintText: l10n.servingsHint,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _isDirty = true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_imagePath.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePath),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (_imagePath.isNotEmpty) const SizedBox(width: 12),
                        TextButton.icon(
                          icon: Icon(
                            _imagePath.isEmpty
                                ? Icons.add_photo_alternate
                                : Icons.swap_horiz,
                          ),
                          label: Text(
                            _imagePath.isEmpty
                                ? l10n.addPhoto
                                : l10n.changePhoto,
                          ),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          l10n.recipeIngredients,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addIngredient),
                          onPressed: _addIngredient,
                        ),
                      ],
                    ),
                    if (_ingredients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          l10n.addIngredient,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ..._ingredients.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ing = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: ing.nameController,
                                decoration: InputDecoration(
                                  labelText: l10n.ingredientName,
                                  isDense: true,
                                ),
                                onChanged: (_) => _isDirty = true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: ing.quantityController,
                                decoration: InputDecoration(
                                  labelText: l10n.ingredientQuantity,
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _isDirty = true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: ing.unit,
                                decoration: InputDecoration(
                                  labelText: l10n.ingredientUnit,
                                  isDense: true,
                                ),
                                items: [
                                  // Always include the current unit for
                                  // backward compatibility with existing data.
                                  if (!dropdownUnits.contains(ing.unit))
                                    DropdownMenuItem(
                                      value: ing.unit,
                                      child: Text(ing.unit),
                                    ),
                                  ...dropdownUnits.map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null && v != ing.unit) {
                                    final oldQty =
                                        double.tryParse(
                                          ing.quantityController.text,
                                        ) ??
                                        0.0;
                                    final converted = UnitConverter.convert(
                                      oldQty,
                                      ing.unit,
                                      v,
                                    );
                                    ing.quantityController.text = converted
                                        .toStringAsFixed(1);
                                    setState(() {
                                      ing.unit = v;
                                    });
                                    _isDirty = true;
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeIngredient(i),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.kitchen),
                      label: Text(l10n.fromYourPantry),
                      onPressed: _showPantryPicker,
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(l10n.searchProduct),
                      onPressed: _showProductSearch,
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? ProgressIndicatorHelper.build(size: 18, strokeWidth: 2)
              : const Icon(Icons.save),
          label: Text(_isSaving ? l10n.save : l10n.saveRecipe),
        ),
      ),
    );
  }
}
