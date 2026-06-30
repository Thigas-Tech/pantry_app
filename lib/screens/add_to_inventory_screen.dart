import 'package:flutter/material.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/utils/logger.dart';

/// A form screen for creating or editing an inventory item.
///
/// This screen is pushed from [ProductDetailScreen] after the user taps
/// "Add to Inventory" or the edit button on an existing inventory tile.
///
/// ## Modes
///
/// - **Create mode**: [existingItem] is `null`. A blank form is shown with
///   default values (quantity = 1, unit = 'pcs', location = 'pantry'). An
///   optional [suggestedExpiry] may be pre‑filled based on the product
///   category.
/// - **Edit mode**: [existingItem] is provided. All fields are initialised
///   with the current values, allowing the user to modify them.
///
/// ## Return value
///
/// When the user saves (or updates), the screen pops and returns an
/// [InventoryItem] with the form data. If the user navigates back without
/// saving, `null` is returned.
///
/// ## Validation
///
/// The quantity field must be a positive number. All other fields are
/// optional.
class AddToInventoryScreen extends StatefulWidget {
  const AddToInventoryScreen({
    required this.barcode,
    super.key,
    this.existingItem,
    this.suggestedExpiry,
  });

  /// The product barcode this inventory item belongs to.
  final String barcode;

  /// If provided, the form is in edit mode and pre‑filled with this item.
  final InventoryItem? existingItem;

  /// A suggested expiry date in ISO 8601 format (`YYYY-MM-DD`), used as
  /// the default for the date picker in create mode.
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

  /// Available units for the dropdown.
  final List<String> _units = ['pcs', 'g', 'kg', 'ml', 'L'];

  /// Available storage locations for the dropdown.
  final List<String> _locations = ['pantry', 'fridge', 'freezer'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    _quantity = existing?.quantity ?? 1;
    _unit = existing?.unit ?? 'pcs';
    _location = existing?.location ?? 'pantry';
    _expiryDate = existing?.expiryDate != null
        ? DateTime.tryParse(existing!.expiryDate!)
        : (widget.suggestedExpiry != null
              ? DateTime.tryParse(widget.suggestedExpiry!)
              : null);
    _notes = existing?.notes ?? '';
  }

  /// Validates the form and, if valid, pops the screen with the constructed
  /// [InventoryItem].
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final item = InventoryItem(
      id: widget.existingItem?.id,
      barcode: widget.barcode,
      quantity: _quantity,
      unit: _unit,
      location: _location,
      // Store only the date part (YYYY-MM-DD), discarding time.
      expiryDate: _expiryDate?.toIso8601String().substring(0, 10),
      notes: _notes.isNotEmpty ? _notes : null,
      dateAdded:
          widget.existingItem?.dateAdded ??
          DateTime.now().millisecondsSinceEpoch,
    );
    logInfo(
      // ignore: lines_longer_than_80_chars
      'Inventory item ready: barcode=${item.barcode} qty=${item.quantity} ${item.unit} loc=${item.location} expiry=${item.expiryDate}',
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Update Item' : 'Add to Inventory'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Quantity input
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a positive number';
                  return null;
                },
                onSaved: (v) => _quantity = double.parse(v!),
              ),
              // Unit dropdown
              DropdownButtonFormField<String>(
                initialValue: _unit,
                items: _units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v!),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              // Location dropdown
              DropdownButtonFormField<String>(
                initialValue: _location,
                items: _locations
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _location = v!),
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 16),
              // Expiry date picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiryDate == null
                          ? 'Expiry date (optional)'
                          // ignore: lines_longer_than_80_chars
                          : 'Expiry: ${_expiryDate!.toIso8601String().substring(0, 10)}',
                    ),
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
                    child: const Text('Pick date'),
                  ),
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _expiryDate = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Notes field
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                onSaved: (v) => _notes = v ?? '',
              ),
              const SizedBox(height: 32),
              // Submit button
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Update' : 'Add to Pantry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
