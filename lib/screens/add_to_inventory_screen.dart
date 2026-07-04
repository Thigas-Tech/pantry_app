import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/utils/logger.dart';

/// A form screen for creating or editing an inventory item.
///
/// Supports custom units and locations via a dialog prompt.
class AddToInventoryScreen extends StatefulWidget {
  /// Creates an [AddToInventoryScreen].
  const AddToInventoryScreen({
    required this.barcode,
    required this.inventoryId,
    super.key,
    this.existingItem,
    this.suggestedExpiry,
  });

  /// The product barcode this inventory item belongs to.
  final String barcode;

  /// The ID of the inventory to add the item to (create mode).
  final int inventoryId;

  /// If provided, the form is in edit mode and pre-filled with this item.
  final InventoryItem? existingItem;

  /// A suggested expiry date in ISO 8601 format (`YYYY-MM-DD`).
  final String? suggestedExpiry;

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

  static const _presetUnits = ['pieces', 'g', 'kg', 'ml', 'L'];
  static const _presetLocations = ['pantry', 'fridge', 'freezer'];

  List<String> _units = List.of(_presetUnits);
  List<String> _locations = List.of(_presetLocations);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    _quantity = existing?.quantity ?? 1;
    _unit = existing?.unit ?? 'pieces';
    _location = existing?.location ?? 'pantry';
    _expiryDate = existing?.expiryDate != null
        ? DateTime.tryParse(existing!.expiryDate!)
        : (widget.suggestedExpiry != null
              ? DateTime.tryParse(widget.suggestedExpiry!)
              : null);
    _notes = existing?.notes ?? '';
    _syncCustomOptions();
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

  Future<void> _pickCustomUnit() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enterCustomUnit),
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
        _unit = value;
        _syncCustomOptions();
      });
    }
  }

  Future<void> _pickCustomLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enterCustomLocation),
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
        _location = value;
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
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final item = InventoryItem(
      id: widget.existingItem?.id,
      barcode: widget.barcode,
      quantity: _quantity,
      unit: _unit,
      location: _location,
      expiryDate: _expiryDate?.toIso8601String().substring(0, 10),
      notes: _notes.isNotEmpty ? _notes : null,
      dateAdded:
          widget.existingItem?.dateAdded ??
          DateTime.now().millisecondsSinceEpoch,
      inventoryId: widget.existingItem?.inventoryId ?? widget.inventoryId,
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
        DropdownMenuItem(value: u, child: Text(u)),
      const DropdownMenuItem(value: '__custom__', child: Text('...')),
    ];
    final locationItems = <DropdownMenuItem<String>>[
      for (final l in _locations.where((l) => _presetLocations.contains(l)))
        DropdownMenuItem(value: l, child: Text(l)),
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
              DropdownButtonFormField<String>(
                initialValue:
                    _presetUnits.contains(_unit) ? _unit : '__custom__',
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
                initialValue: _presetLocations
                        .contains(_location)
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
