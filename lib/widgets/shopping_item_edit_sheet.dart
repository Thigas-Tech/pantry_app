import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';

/// Holds the edited values returned by [ShoppingItemEditSheet].
class ShoppingItemEditResult {
  /// Creates a [ShoppingItemEditResult].
  const ShoppingItemEditResult({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  /// The edited item name.
  final String name;

  /// The edited quantity to purchase.
  final double quantity;

  /// The edited unit for [quantity].
  final String unit;
}

/// A bottom sheet that edits an existing shopping list item.
///
/// Lets the user rename the item and change its quantity and unit. Opens
/// via [showModalBottomSheet]. Returns a [ShoppingItemEditResult] or null
/// if cancelled.
class ShoppingItemEditSheet extends ConsumerStatefulWidget {
  const ShoppingItemEditSheet._({required this.item});

  /// The item being edited.
  final ShoppingItem item;

  /// Shows the edit sheet and returns the result, or null if cancelled.
  static Future<ShoppingItemEditResult?> show(
    BuildContext context, {
    required ShoppingItem item,
  }) {
    return BottomSheetHelper.show<ShoppingItemEditResult>(
      context: context,
      builder: (_) => ShoppingItemEditSheet._(item: item),
    );
  }

  @override
  ConsumerState<ShoppingItemEditSheet> createState() =>
      _ShoppingItemEditSheetState();
}

class _ShoppingItemEditSheetState extends ConsumerState<ShoppingItemEditSheet> {
  static const _unitChoices = ['pieces', 'g', 'kg', 'ml', 'L'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item.name);
    _qtyCtrl = TextEditingController(
      text: item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString()
          : item.quantity.toString(),
    );
    _unit = _unitChoices.contains(item.unit) ? item.unit : 'pieces';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1;
    Navigator.of(context).pop(
      ShoppingItemEditResult(
        name: _nameCtrl.text.trim(),
        quantity: qty,
        unit: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = BottomSheetHelper.bottomInset(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.editItem,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.itemName,
                  hintText: l10n.quickAddHint,
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: InputDecoration(labelText: l10n.quantity),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final qty = double.tryParse(v ?? '');
                        if (qty == null || qty < 1) return l10n.requiredField;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: InputDecoration(labelText: l10n.unit),
                      items: _unitChoices
                          .map(
                            (u) => DropdownMenuItem<String>(
                              value: u,
                              child: Text(l10n.localizeUnit(u)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _unit = v);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
