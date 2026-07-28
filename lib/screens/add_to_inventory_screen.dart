import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/services/produce_serving_presets.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/quantity_parser.dart';

/// A form screen for creating or editing an inventory item.
///
/// Supports custom units and locations via a dialog prompt. When a [product]
/// is provided and no [existingItem] is set (create mode), the quantity and
/// unit fields are pre-filled from the product's Open Food Facts data.
class AddToInventoryScreen extends StatefulWidget {
  /// Creates an [AddToInventoryScreen].
  const AddToInventoryScreen({
    required this.barcode,
    required this.inventoryId,
    super.key,
    this.existingItem,
    this.suggestedExpiry,
    this.productType,
    this.produceName,
    this.product,
  });

  /// The product barcode this inventory item belongs to.
  final String barcode;

  /// The ID of the inventory to add the item to (create mode).
  final int inventoryId;

  /// If provided, the form is in edit mode and pre-filled with this item.
  final InventoryItem? existingItem;

  /// A suggested expiry date in ISO 8601 format (YYYY-MM-DD).
  final String? suggestedExpiry;

  /// The product type — controls whether the weight/unit toggle is shown.
  final ProductType? productType;

  /// The display name of the product, used for serving weight lookups.
  ///
  /// When null for produce items, the name is extracted from the barcode
  /// by stripping the `produce-` prefix.
  final String? produceName;

  /// The OFF product with quantity data used to pre-fill the amount and
  /// unit fields in create mode (when [existingItem] is null).
  ///
  /// Only used for non-produce items. The values are parsed by
  /// [QuantityParser] and applied as defaults — the user can still
  /// override them.
  final Product? product;

  @override
  State<AddToInventoryScreen> createState() => _AddToInventoryScreenState();
}

class _AddToInventoryScreenState extends State<AddToInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late double _quantity;
  late String _unit;
  late String _location;
  late DateTime? _expiryDate;
  String _notes = '';

  bool _produceIsWeightMode = true;
  String _selectedSize = 'Medium';
  String _produceName = 'Apple';

  bool get _isProduce => widget.productType == ProductType.produce;

  static const _presetUnits = ['pieces', 'g', 'kg', 'ml', 'L'];
  static const _presetLocations = ['pantry', 'fridge', 'freezer'];

  List<String> _units = List.of(_presetUnits);
  List<String> _locations = List.of(_presetLocations);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    _quantity = existing?.quantity ?? _prefillQuantity();
    _unit = existing?.unit ?? _prefillUnit();
    _location = existing?.location ?? 'pantry';
    _expiryDate = existing?.expiryDate != null
        ? DateTime.tryParse(existing!.expiryDate!)
        : (widget.suggestedExpiry != null
              ? DateTime.tryParse(widget.suggestedExpiry!)
              : null);
    _notes = existing?.notes ?? '';
    _produceIsWeightMode = !_isProduce;
    _produceName =
        widget.produceName ??
        (widget.barcode.startsWith('produce-')
            ? widget.barcode.substring(7)
            : 'Apple');
    _syncCustomOptions();
  }

  /// Pre-fills the quantity from the OFF product data.
  ///
  /// Only applies in create mode for non-produce items. Returns 1 (the
  /// default) when no product data is available or the item is produce.
  double _prefillQuantity() {
    if (_isProduce || widget.product == null) return 1;
    final parsed = QuantityParser.parse(
      productQuantity: widget.product!.productQuantity,
      quantity: widget.product!.quantity,
    );
    if (parsed != null && parsed.amount > 0) return parsed.amount;
    return 1;
  }

  /// Pre-fills the unit from the OFF product data.
  ///
  /// Only applies in create mode for non-produce items. Returns 'pieces'
  /// (the default) when no product data is available or the item is
  /// produce.
  String _prefillUnit() {
    if (_isProduce || widget.product == null) return 'pieces';
    final parsed = QuantityParser.parse(
      productQuantity: widget.product!.productQuantity,
      quantity: widget.product!.quantity,
    );
    if (parsed != null && parsed.unit.isNotEmpty) return parsed.unit;
    return 'pieces';
  }

  void _syncCustomOptions() {
    if (!_presetUnits.contains(_unit) && !_units.contains(_unit)) {
      _units = [..._presetUnits, _unit];
    }
    if (!_presetLocations.contains(_location) &&
        !_locations.contains(_location)) {
      _locations = [..._presetLocations, _location];
    }
  }

  Future<void> _pickCustomUnit() => _showCustomInput(
    AppLocalizations.of(context)!.enterCustomUnit,
    (v) => _unit = v,
  );

  Future<void> _pickCustomLocation() => _showCustomInput(
    AppLocalizations.of(context)!.enterCustomLocation,
    (v) => _location = v,
  );

  Future<void> _showCustomInput(
    String title,
    ValueSetter<String> onPicked,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      setState(() {
        onPicked(value);
        _syncCustomOptions();
      });
    }
  }

  String get _expiryDisplayText {
    final l10n = AppLocalizations.of(context)!;
    if (_expiryDate == null) return l10n.expiryDateOptional;
    final dateStr = _expiryDate!.toIso8601String().substring(0, 10);
    return '${l10n.expiryPrefix}: $dateStr';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      logInfo('Add-to-inventory form validation failed');
      return;
    }
    _formKey.currentState!.save();

    String unit;
    double? servingWeightG;

    if (_isProduce && !_produceIsWeightMode) {
      unit = _selectedSize;
      servingWeightG = ProduceServingPresets.forName(
        _produceName,
      )?[_selectedSize];
    } else if (_isProduce) {
      unit = 'g';
      servingWeightG = null;
    } else {
      unit = _unit;
      servingWeightG = null;
    }

    final item = InventoryItem(
      id: widget.existingItem?.id,
      barcode: widget.barcode,
      quantity: _quantity,
      unit: unit,
      location: _location,
      expiryDate: _expiryDate?.toIso8601String().substring(0, 10),
      notes: _notes.isNotEmpty ? _notes : null,
      dateAdded:
          widget.existingItem?.dateAdded ??
          DateTime.now().millisecondsSinceEpoch,
      inventoryId: widget.existingItem?.inventoryId ?? widget.inventoryId,
      servingWeightG: servingWeightG,
    );
    logInfo(
      '''Inventory item ready: barcode=${item.barcode} qty=${item.quantity} ${item.unit} loc=${item.location} expiry=${item.expiryDate} inventory=${item.inventoryId}''',
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existingItem != null;
    final unitItems = <DropdownMenuItem<String>>[
      for (final u in _units.where((u) => _presetUnits.contains(u)))
        DropdownMenuItem(value: u, child: Text(l10n.localizeUnit(u))),
      const DropdownMenuItem(value: '__custom__', child: Text('...')),
    ];
    final locationItems = <DropdownMenuItem<String>>[
      for (final l in _locations.where((l) => _presetLocations.contains(l)))
        DropdownMenuItem(value: l, child: Text(l10n.localizeLocation(l))),
      const DropdownMenuItem(value: '__custom__', child: Text('...')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.updateItem : l10n.addToInventory),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_isProduce)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.weightModeLabel),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.unitModeLabel),
                      ),
                    ],
                    selected: {_produceIsWeightMode},
                    onSelectionChanged: (v) {
                      setState(() => _produceIsWeightMode = v.first);
                    },
                  ),
                ),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: InputDecoration(labelText: l10n.quantityLabel),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) {
                    return l10n.enterPositiveNumber;
                  }
                  return null;
                },
                onSaved: (v) => _quantity = double.parse(v!),
              ),
              if (_isProduce && !_produceIsWeightMode)
                DropdownButtonFormField<String>(
                  initialValue: _selectedSize,
                  items: const [
                    DropdownMenuItem(value: 'Small', child: Text('Small')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'Large', child: Text('Large')),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedSize = v!);
                  },
                  decoration: InputDecoration(labelText: l10n.servingSize),
                ),
              if (!_isProduce)
                DropdownButtonFormField<String>(
                  initialValue: _presetUnits.contains(_unit)
                      ? _unit
                      : '__custom__',
                  items: unitItems,
                  onChanged: (v) {
                    if (v == '__custom__') {
                      unawaited(_pickCustomUnit());
                    } else {
                      setState(() => _unit = v!);
                    }
                  },
                  decoration: InputDecoration(labelText: l10n.unitLabel),
                ),
              DropdownButtonFormField<String>(
                initialValue: _presetLocations.contains(_location)
                    ? _location
                    : '__custom__',
                items: locationItems,
                onChanged: (v) {
                  if (v == '__custom__') {
                    unawaited(_pickCustomLocation());
                  } else {
                    setState(() => _location = v!);
                  }
                },
                decoration: InputDecoration(labelText: l10n.locationLabel),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_expiryDisplayText),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _expiryDate ??
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked != null) setState(() => _expiryDate = picked);
                    },
                    child: Text(l10n.pickDate),
                  ),
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _expiryDate = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _notes,
                decoration: InputDecoration(labelText: l10n.notesLabel),
                onSaved: (v) => _notes = v ?? '',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? l10n.updateItem : l10n.addToPantry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
