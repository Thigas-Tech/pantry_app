import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// A bottom sheet for entering or editing a price observation.
///
/// Opens via [showModalBottomSheet]. Returns a [Price] object with the
/// entered data, or `null` if the user cancels.
///
/// Example:
/// ```dart
/// final price = await PriceEntrySheet.show(context, barcode: barcode);
/// ```
class PriceEntrySheet extends ConsumerStatefulWidget {
  const PriceEntrySheet._({
    required this.barcode,
    this.existingPrice,
  });

  /// The product barcode this price is for.
  final String barcode;

  /// When set, the sheet is in edit mode for this existing price.
  final Price? existingPrice;

  /// Shows the price entry bottom sheet and returns the entered [Price],
  /// or `null` if cancelled.
  static Future<Price?> show(
    BuildContext context, {
    required String barcode,
    Price? existingPrice,
  }) {
    return showModalBottomSheet<Price>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PriceEntrySheet._(
        barcode: barcode,
        existingPrice: existingPrice,
      ),
    );
  }

  @override
  ConsumerState<PriceEntrySheet> createState() => _PriceEntrySheetState();
}

class _PriceEntrySheetState extends ConsumerState<PriceEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _storeCtrl;
  late final TextEditingController _notesCtrl;
  String _currency = 'USD';
  DateTime _date = DateTime.now();
  bool _isDiscounted = false;

  bool get _isEditing => widget.existingPrice != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPrice;
    final base = ref.read(settingsProvider).baseCurrency;
    _currency = existing?.currency ?? base;
    _date = existing?.datePurchased != null
        ? DateTime.fromMillisecondsSinceEpoch(existing!.datePurchased!)
        : DateTime.now();
    _isDiscounted = existing?.isDiscounted ?? false;
    _amountCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(2) : '',
    );
    _storeCtrl = TextEditingController(text: existing?.store ?? '');
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _storeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? l10n.editPrice : l10n.addPrice,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: l10n.price,
                  prefixText: '$_currency ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _storeCtrl,
                decoration: InputDecoration(labelText: l10n.store),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        '${l10n.datePurchased}: '
                        '${_date.day.toString().padLeft(2, '0')}/'
                        '${_date.month.toString().padLeft(2, '0')}/'
                        '${_date.year}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(l10n.discounted),
                value: _isDiscounted,
                onChanged: (v) => setState(() => _isDiscounted = v),
                contentPadding: EdgeInsets.zero,
              ),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(labelText: l10n.notes),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? l10n.save : l10n.addPrice),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountCtrl.text.trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showError(context, l10n.invalidPriceAmount);
      return;
    }

    final price = Price(
      barcode: widget.barcode,
      price: amount,
      currency: _currency,
      id: widget.existingPrice?.id,
      store: _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
      isDiscounted: _isDiscounted,
      regularPrice: widget.existingPrice?.regularPrice,
      datePurchased: _date.millisecondsSinceEpoch,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      dateAdded:
          widget.existingPrice?.dateAdded ??
          DateTime.now().millisecondsSinceEpoch,
    );

    Navigator.of(context).pop(price);
  }
}
