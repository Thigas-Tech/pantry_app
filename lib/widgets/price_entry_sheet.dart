import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/formatters/price_calculator_formatter.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// A bottom sheet for entering or editing a price observation.
///
/// Opens via [showModalBottomSheet]. Returns a [Price] object with the
/// entered data, or null if the user cancels.
///
/// The amount field uses a locale-aware decimal separator
/// ([decimalSeparatorFor]).
///
/// Example:
/// ```dart
/// final price = await PriceEntrySheet.show(context, barcode: '123');
/// ```
class PriceEntrySheet extends ConsumerStatefulWidget {
  const PriceEntrySheet._({
    required this.barcode,
    this.existingPrice,
    this.existingAmount,
    this.existingCurrency,
    this.existingStore,
  });

  /// The product barcode this price is for.
  final String barcode;

  /// When set, the sheet is in edit mode for this existing price.
  final Price? existingPrice;

  /// Pre-fills the amount field when not using an existingPrice.
  final double? existingAmount;

  /// Pre-fills the currency when not using an existingPrice.
  final String? existingCurrency;

  /// Pre-fills the store field when not using an existingPrice.
  final String? existingStore;

  /// Shows the price entry bottom sheet and returns the entered [Price],
  /// or null if cancelled.
  static Future<Price?> show(
    BuildContext context, {
    String barcode = '',
    Price? existingPrice,
    double? existingAmount,
    String? existingCurrency,
    String? existingStore,
  }) {
    return BottomSheetHelper.show<Price>(
      context: context,
      builder: (_) => PriceEntrySheet._(
        barcode: barcode,
        existingPrice: existingPrice,
        existingAmount: existingAmount,
        existingCurrency: existingCurrency,
        existingStore: existingStore,
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
  late String _decimalSep;
  TextEditingController? _autocompleteCtrl;
  bool _isAddingStore = false;

  bool get _isEditing => widget.existingPrice != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPrice;
    final base = ref.read(settingsProvider).baseCurrency;
    _currency = existing?.currency ?? widget.existingCurrency ?? base;
    _decimalSep = decimalSeparatorFor(_currency);
    _date = existing?.datePurchased != null
        ? DateTime.fromMillisecondsSinceEpoch(existing!.datePurchased!)
        : DateTime.now();
    _isDiscounted = existing?.isDiscounted ?? false;
    final initialAmount = existing?.price ?? widget.existingAmount;
    final initialText = initialAmount != null
        ? _formatForDisplay(initialAmount)
        : '0$_decimalSep'
              '00';
    _amountCtrl = TextEditingController(text: initialText);
    _storeCtrl = TextEditingController(
      text: existing?.store ?? widget.existingStore ?? '',
    );
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
  }

  /// Formats [value] with exactly 2 decimal places using the locale separator.
  String _formatForDisplay(double value) {
    final fixed = value.toStringAsFixed(2);
    if (_decimalSep == ',') return fixed.replaceAll('.', ',');
    return fixed;
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + BottomSheetHelper.bottomInset(context),
      ),
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
                  prefixText: '${currencySymbolFor(_currency)} ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  PriceCalculatorFormatter(_decimalSep),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(
                    v.trim().replaceAll(',', '.'),
                  );
                  if (parsed == null ||
                      !parsed.isFinite ||
                      parsed <= 0 ||
                      parsed >= 1e9) {
                    return l10n.invalidPriceAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildStoreField(l10n),
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

  Widget _buildStoreField(AppLocalizations l10n) {
    final storesAsync = ref.watch(storesProvider);

    return storesAsync.when(
      data: (stores) {
        return Autocomplete<String>(
          initialValue: TextEditingValue(
            text: _storeCtrl.text,
            selection: TextSelection.collapsed(
              offset: _storeCtrl.text.length,
            ),
          ),
          optionsBuilder: (textEditingValue) {
            final input = textEditingValue.text.toLowerCase();
            if (input.isEmpty) return stores.map((s) => s.name);
            return stores
                .where((s) => s.name.toLowerCase().contains(input))
                .map((s) => s.name);
          },
          onSelected: (value) {
            _storeCtrl.text = value;
          },
          fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
            _autocompleteCtrl = ctrl;
            return TextFormField(
              controller: ctrl,
              focusNode: focusNode,
              decoration: InputDecoration(labelText: l10n.store),
              onChanged: (_) {
                _storeCtrl.text = ctrl.text;
              },
              onFieldSubmitted: (_) => onFieldSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _StoreOptionsView(
              options: options.toList(),
              onSelected: onSelected,
              addNewLabel: l10n.addNewStore,
              onAddNew: () => _handleAddNewStore(l10n),
            );
          },
        );
      },
      loading: () {
        return TextFormField(
          controller: _storeCtrl,
          decoration: InputDecoration(labelText: l10n.store),
        );
      },
      error: (_, stackTrace) {
        return TextFormField(
          controller: _storeCtrl,
          decoration: InputDecoration(labelText: l10n.store),
        );
      },
    );
  }

  Future<void> _handleAddNewStore(AppLocalizations l10n) async {
    if (_isAddingStore) return;
    _isAddingStore = true;

    final nameCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.addNewStore),
          content: TextField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: l10n.storeName),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
    _isAddingStore = false;

    if (result == null || result.isEmpty) return;

    final db = ref.read(databaseProvider);
    final storeId = await db.storeDao.insert(await db.database, result);

    if (storeId >= 0) {
      if (!mounted) return;
      ref.invalidate(storesProvider);
      _storeCtrl.text = result;
      _autocompleteCtrl?.text = result;
      if (mounted) {
        SnackbarHelper.showInfo(context, l10n.storeAdded);
      }
    }
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

    final l10n = AppLocalizations.of(context)!;
    final amountStr = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || !amount.isFinite || amount <= 0 || amount >= 1e9) {
      SnackbarHelper.showError(context, l10n.invalidPriceAmount);
      return;
    }

    final storeName = _storeCtrl.text.trim().isEmpty
        ? null
        : _storeCtrl.text.trim();

    if (storeName != null && storeName.isNotEmpty) {
      unawaited(_autoInsertStore(storeName));
    }

    final price = Price(
      barcode: widget.barcode,
      price: amount,
      currency: _currency,
      id: widget.existingPrice?.id,
      store: storeName,
      isDiscounted: _isDiscounted,
      regularPrice: widget.existingPrice?.regularPrice,
      datePurchased: _date.millisecondsSinceEpoch,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      dateAdded:
          widget.existingPrice?.dateAdded ??
          DateTime.now().millisecondsSinceEpoch,
      syncStatus: widget.existingPrice?.syncStatus ?? priceSyncLocalOnly,
      openPricesId: widget.existingPrice?.openPricesId,
      locationOsmId: widget.existingPrice?.locationOsmId,
      locationOsmType: widget.existingPrice?.locationOsmType,
    );

    Navigator.of(context).pop(price);
  }

  Future<void> _autoInsertStore(String name) async {
    try {
      final db = ref.read(databaseProvider);
      await db.storeDao.insert(await db.database, name);
      if (!mounted) return;
      ref.invalidate(storesProvider);
    } on Exception catch (e) {
      logWarning('Failed to auto-insert store "$name": $e');
    }
  }
}

/// Dropdown list of matching stores with a trailing add-new button.
class _StoreOptionsView extends StatelessWidget {
  const _StoreOptionsView({
    required this.options,
    required this.onSelected,
    required this.addNewLabel,
    required this.onAddNew,
  });

  final List<String> options;
  final AutocompleteOnSelected<String> onSelected;
  final String addNewLabel;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length + 1,
            itemBuilder: (context, index) {
              if (index < options.length) {
                return ListTile(
                  title: Text(options[index]),
                  onTap: () => onSelected(options[index]),
                );
              }
              return ListTile(
                leading: const Icon(Icons.add),
                title: Text(addNewLabel),
                onTap: onAddNew,
                iconColor: theme.colorScheme.primary,
                titleTextStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
