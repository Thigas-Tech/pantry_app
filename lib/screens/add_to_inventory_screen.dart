import 'package:flutter/material.dart';
import 'package:pantry_app/models/inventory_item.dart';

class AddToInventoryScreen extends StatefulWidget {
  const AddToInventoryScreen({
    required this.barcode,
    super.key,
    this.existingItem,
    this.suggestedExpiry,
  });
  final String barcode;

  /// If provided, we're editing an existing item.
  final InventoryItem? existingItem;
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

  final List<String> _units = ['pcs', 'g', 'kg', 'ml', 'L'];
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
              DropdownButtonFormField<String>(
                initialValue: _unit,
                items: _units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v!),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _location,
                items: _locations
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _location = v!),
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                onSaved: (v) => _notes = v ?? '',
              ),
              const SizedBox(height: 32),
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
