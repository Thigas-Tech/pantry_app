import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/providers/inventory_provider.dart';

/// Holds the result of [QuantityAndPantrySheet].
class QuantityAndPantryResult {
  /// Creates a [QuantityAndPantryResult].
  const QuantityAndPantryResult({
    required this.quantity,
    required this.inventoryId,
  });

  /// The number of units the user bought.
  final double quantity;

  /// The target inventory (pantry) ID.
  final int inventoryId;
}

/// A bottom sheet that prompts the user to record the quantity bought and,
/// when multiple pantries exist, choose which one to store the item in.
///
/// Opens via [showModalBottomSheet]. Returns a [QuantityAndPantryResult] or
/// `null` if the user cancels.
class QuantityAndPantrySheet extends ConsumerStatefulWidget {
  const QuantityAndPantrySheet._();

  /// Shows the sheet and returns the result, or `null` if cancelled.
  static Future<QuantityAndPantryResult?> show(BuildContext context) {
    return showModalBottomSheet<QuantityAndPantryResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const QuantityAndPantrySheet._(),
    );
  }

  @override
  ConsumerState<QuantityAndPantrySheet> createState() =>
      _QuantityAndPantrySheetState();
}

class _QuantityAndPantrySheetState
    extends ConsumerState<QuantityAndPantrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyCtrl;
  int _selectedInventoryId = 1;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inventoriesAsync = ref.watch(inventoryListProvider);
    final inventories =
        inventoriesAsync.asData?.value ?? <Map<String, dynamic>>[];

    if (_selectedInventoryId == 1 && inventories.isNotEmpty) {
      _selectedInventoryId = inventories.first['id'] as int;
    }

    final bottomPad = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad + keyboardHeight),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addToPantryAfterPrice,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.addToPantryAfterPriceDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyCtrl,
                decoration: InputDecoration(
                  labelText: l10n.howManyBought,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final qty = double.tryParse(v.trim());
                  if (qty == null || !qty.isFinite || qty <= 0) {
                    return l10n.invalidPriceAmount;
                  }
                  return null;
                },
              ),
              if (inventories.length > 1) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _selectedInventoryId,
                  decoration: InputDecoration(
                    labelText: l10n.choosePantry,
                  ),
                  items: inventories
                      .map(
                        (inv) => DropdownMenuItem<int>(
                          value: inv['id'] as int,
                          child: Text(
                            l10n.displayInventoryName(
                              inv['name'] as String? ?? '',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedInventoryId = v);
                    }
                  },
                ),
              ],
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
                      child: Text(l10n.addToInventory),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1;

    Navigator.of(context).pop(
      QuantityAndPantryResult(
        quantity: qty,
        inventoryId: _selectedInventoryId,
      ),
    );
  }
}
